package advisories

import (
	"encoding/json"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"ado-reviewer/.github/tools/skills-go/internal/files"
	"ado-reviewer/.github/tools/skills-go/internal/iterations"
	"ado-reviewer/.github/tools/skills-go/internal/pullrequests"
	"ado-reviewer/.github/tools/skills-go/internal/shared"
)

type dependency struct {
	Ecosystem string `json:"ecosystem"`
	Package   string `json:"package"`
	Version   string `json:"version"`
	FilePath  string `json:"filePath"`
}

func GetPRDependencyAdvisories(organization, project, repositoryID, pullRequestID, iterationID string, perPage int) (map[string]any, error) {
	if perPage <= 0 {
		perPage = 20
	}
	if perPage > 100 {
		return nil, fmt.Errorf("per_page must be an integer between 1 and 100")
	}

	prDetails, err := pullrequests.GetDetails(organization, project, repositoryID, pullRequestID)
	if err != nil {
		return nil, err
	}
	sourceBranch := strings.TrimPrefix(shared.TrimmedString(prDetails["sourceRefName"]), "refs/heads/")

	iter := strings.TrimSpace(iterationID)
	if iter == "" {
		iterPayload, err := iterations.List(organization, project, repositoryID, pullRequestID)
		if err != nil {
			return nil, err
		}
		iter = strconv.Itoa(maxIterationID(iterPayload))
	}
	if iter == "0" || iter == "" {
		return map[string]any{"manifestFiles": []string{}, "dependencies": []any{}, "advisories": []any{}, "dependenciesChecked": 0, "advisoriesFound": 0, "highOrCritical": 0}, nil
	}

	changes, err := pullrequests.GetChanges(organization, project, repositoryID, pullRequestID, iter)
	if err != nil {
		return nil, err
	}
	projected := pullrequests.ProjectChangedFiles(changes, pullRequestID, iter)
	manifestPaths := findManifestPaths(projected)
	if len(manifestPaths) == 0 {
		return map[string]any{"manifestFiles": []string{}, "dependencies": []any{}, "advisories": []any{}, "dependenciesChecked": 0, "advisoriesFound": 0, "highOrCritical": 0}, nil
	}

	deps := make([]dependency, 0)
	seen := map[string]bool{}
	for _, path := range manifestPaths {
		filePayload, err := files.GetContent(organization, project, repositoryID, path, sourceBranch, "branch")
		if err != nil {
			continue
		}
		content := shared.TrimmedString(filePayload["content"])
		for _, dep := range parseDependencies(path, content) {
			key := dep.Ecosystem + "|" + dep.Package + "|" + dep.Version
			if seen[key] {
				continue
			}
			seen[key] = true
			deps = append(deps, dep)
		}
	}

	advList := make([]map[string]any, 0)
	highOrCritical := 0
	for _, dep := range deps {
		advs, err := GetGitHubAdvisories(dep.Ecosystem, dep.Package, dep.Version, "", perPage)
		if err != nil {
			continue
		}
		for _, raw := range advs {
			adv, ok := raw.(map[string]any)
			if !ok {
				continue
			}
			entry := map[string]any{
				"filePath":  dep.FilePath,
				"ecosystem": dep.Ecosystem,
				"package":   dep.Package,
				"version":   dep.Version,
				"ghsa_id":   adv["ghsa_id"],
				"cve_id":    adv["cve_id"],
				"severity":  adv["severity"],
				"summary":   adv["summary"],
				"html_url":  adv["html_url"],
			}
			if strings.EqualFold(shared.TrimmedString(adv["severity"]), "high") || strings.EqualFold(shared.TrimmedString(adv["severity"]), "critical") {
				highOrCritical++
			}
			if vulns, ok := adv["vulnerabilities"].([]any); ok {
				for _, vraw := range vulns {
					v, ok := vraw.(map[string]any)
					if !ok {
						continue
					}
					pkgData, _ := v["package"].(map[string]any)
					if strings.EqualFold(shared.TrimmedString(pkgData["name"]), dep.Package) && strings.EqualFold(shared.TrimmedString(pkgData["ecosystem"]), dep.Ecosystem) {
						entry["vulnerable_version_range"] = v["vulnerable_version_range"]
						entry["first_patched_version"] = v["first_patched_version"]
						break
					}
				}
			}
			advList = append(advList, entry)
		}
	}

	depAny := make([]any, 0, len(deps))
	for _, d := range deps {
		depAny = append(depAny, d)
	}
	advAny := make([]any, 0, len(advList))
	for _, a := range advList {
		advAny = append(advAny, a)
	}

	return map[string]any{
		"manifestFiles":       manifestPaths,
		"dependencies":        depAny,
		"advisories":          advAny,
		"dependenciesChecked": len(deps),
		"advisoriesFound":     len(advList),
		"highOrCritical":      highOrCritical,
	}, nil
}

func maxIterationID(payload map[string]any) int {
	maxValue := 0
	values, _ := payload["value"].([]any)
	for _, raw := range values {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if id, ok := item["id"].(float64); ok && int(id) > maxValue {
			maxValue = int(id)
		}
	}
	return maxValue
}

func findManifestPaths(projected map[string]any) []string {
	paths := make([]string, 0)
	filesRaw, _ := projected["files"].([]map[string]any)
	if len(filesRaw) == 0 {
		if generic, ok := projected["files"].([]any); ok {
			for _, raw := range generic {
				if file, ok := raw.(map[string]any); ok {
					paths = appendManifestPath(paths, shared.TrimmedString(file["path"]))
				}
			}
		}
	} else {
		for _, file := range filesRaw {
			paths = appendManifestPath(paths, shared.TrimmedString(file["path"]))
		}
	}
	sort.Strings(paths)
	seen := map[string]bool{}
	unique := make([]string, 0, len(paths))
	for _, p := range paths {
		if !seen[p] {
			seen[p] = true
			unique = append(unique, p)
		}
	}
	return unique
}

func appendManifestPath(paths []string, p string) []string {
	lower := strings.ToLower(strings.TrimSpace(p))
	if lower == "" {
		return paths
	}
	if strings.HasSuffix(lower, "/package.json") || strings.HasSuffix(lower, "/package-lock.json") || strings.HasSuffix(lower, "requirements.txt") || strings.HasSuffix(lower, "requirements-dev.txt") || strings.HasSuffix(lower, "poetry.lock") || strings.HasSuffix(lower, "go.mod") || strings.HasSuffix(lower, "cargo.lock") {
		return append(paths, p)
	}
	return paths
}

func parseDependencies(path, content string) []dependency {
	lower := strings.ToLower(path)
	switch {
	case strings.HasSuffix(lower, "/package.json"):
		return parsePackageJSON(path, content)
	case strings.HasSuffix(lower, "/package-lock.json"):
		return parsePackageLock(path, content)
	case strings.HasSuffix(lower, "requirements.txt") || strings.HasSuffix(lower, "requirements-dev.txt"):
		return parseRequirements(path, content)
	case strings.HasSuffix(lower, "poetry.lock"):
		return parsePoetry(path, content)
	case strings.HasSuffix(lower, "go.mod"):
		return parseGoMod(path, content)
	case strings.HasSuffix(lower, "cargo.lock"):
		return parseCargoLock(path, content)
	default:
		return []dependency{}
	}
}

func parsePackageJSON(path, content string) []dependency {
	result := make([]dependency, 0)
	payload := map[string]any{}
	if err := json.Unmarshal([]byte(content), &payload); err != nil {
		return result
	}
	for _, section := range []string{"dependencies", "devDependencies", "optionalDependencies", "peerDependencies"} {
		deps, ok := payload[section].(map[string]any)
		if !ok {
			continue
		}
		for name, v := range deps {
			result = append(result, dependency{Ecosystem: "npm", Package: name, Version: shared.TrimmedString(v), FilePath: path})
		}
	}
	return result
}

func parsePackageLock(path, content string) []dependency {
	result := make([]dependency, 0)
	payload := map[string]any{}
	if err := json.Unmarshal([]byte(content), &payload); err != nil {
		return result
	}
	if packages, ok := payload["packages"].(map[string]any); ok {
		for pkgPath, rawNode := range packages {
			node, ok := rawNode.(map[string]any)
			if !ok {
				continue
			}
			name := shared.TrimmedString(node["name"])
			if name == "" && strings.Contains(pkgPath, "node_modules/") {
				parts := strings.Split(pkgPath, "node_modules/")
				name = parts[len(parts)-1]
			}
			if name == "" {
				continue
			}
			result = append(result, dependency{Ecosystem: "npm", Package: name, Version: shared.TrimmedString(node["version"]), FilePath: path})
		}
	}
	if deps, ok := payload["dependencies"].(map[string]any); ok {
		for name, raw := range deps {
			node, _ := raw.(map[string]any)
			result = append(result, dependency{Ecosystem: "npm", Package: name, Version: shared.TrimmedString(node["version"]), FilePath: path})
		}
	}
	return result
}

func parseRequirements(path, content string) []dependency {
	result := make([]dependency, 0)
	lines := strings.Split(content, "\n")
	re := regexp.MustCompile(`^([A-Za-z0-9_.-]+)\s*(?:(==|~=|>=|<=|!=|>|<)\s*([^;\s]+))?`)
	for _, line := range lines {
		trimmed := strings.TrimSpace(strings.Split(line, "#")[0])
		if trimmed == "" || strings.HasPrefix(trimmed, "-") {
			continue
		}
		m := re.FindStringSubmatch(trimmed)
		if len(m) == 0 {
			continue
		}
		version := ""
		if len(m) >= 4 {
			version = m[3]
		}
		result = append(result, dependency{Ecosystem: "pip", Package: m[1], Version: version, FilePath: path})
	}
	return result
}

func parsePoetry(path, content string) []dependency {
	result := make([]dependency, 0)
	name := ""
	version := ""
	for _, raw := range strings.Split(content, "\n") {
		line := strings.TrimSpace(raw)
		if line == "[[package]]" {
			if name != "" {
				result = append(result, dependency{Ecosystem: "pip", Package: name, Version: version, FilePath: path})
			}
			name, version = "", ""
			continue
		}
		if strings.HasPrefix(line, "name = ") {
			name = strings.Trim(line[len("name = "):], `"`)
		}
		if strings.HasPrefix(line, "version = ") {
			version = strings.Trim(line[len("version = "):], `"`)
		}
	}
	if name != "" {
		result = append(result, dependency{Ecosystem: "pip", Package: name, Version: version, FilePath: path})
	}
	return result
}

func parseGoMod(path, content string) []dependency {
	result := make([]dependency, 0)
	inRequire := false
	for _, raw := range strings.Split(content, "\n") {
		line := strings.TrimSpace(strings.Split(raw, "//")[0])
		if line == "" {
			continue
		}
		if line == "require (" {
			inRequire = true
			continue
		}
		if inRequire && line == ")" {
			inRequire = false
			continue
		}
		if strings.HasPrefix(line, "replace ") || strings.HasPrefix(line, "exclude ") {
			continue
		}
		if strings.HasPrefix(line, "require ") {
			parts := strings.Fields(line)
			if len(parts) >= 3 {
				result = append(result, dependency{Ecosystem: "go", Package: parts[1], Version: parts[2], FilePath: path})
			}
			continue
		}
		if inRequire {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				result = append(result, dependency{Ecosystem: "go", Package: parts[0], Version: parts[1], FilePath: path})
			}
		}
	}
	return result
}

func parseCargoLock(path, content string) []dependency {
	result := make([]dependency, 0)
	name := ""
	version := ""
	for _, raw := range strings.Split(content, "\n") {
		line := strings.TrimSpace(raw)
		if line == "[[package]]" {
			if name != "" {
				result = append(result, dependency{Ecosystem: "rust", Package: name, Version: version, FilePath: path})
			}
			name, version = "", ""
			continue
		}
		if strings.HasPrefix(line, "name = ") {
			name = strings.Trim(line[len("name = "):], `"`)
		}
		if strings.HasPrefix(line, "version = ") {
			version = strings.Trim(line[len("version = "):], `"`)
		}
	}
	if name != "" {
		result = append(result, dependency{Ecosystem: "rust", Package: name, Version: version, FilePath: path})
	}
	return result
}
