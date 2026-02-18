package deprecated

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"sort"
	"strings"
	"time"
)

type Result struct {
	Ecosystem   string `json:"ecosystem"`
	Package     string `json:"package"`
	Version     string `json:"version"`
	Deprecated  bool   `json:"deprecated"`
	Message     string `json:"message"`
	Replacement string `json:"replacement"`
}

type UsageError struct {
	Message string
}

type npmVersionMeta struct {
	Deprecated string `json:"deprecated"`
}

type npmPackageMeta struct {
	Versions map[string]npmVersionMeta `json:"versions"`
}

func (e *UsageError) Error() string {
	return e.Message
}

func Check(ecosystem, pkg, version string) (Result, error) {
	switch ecosystem {
	case "npm":
		return checkNPM(pkg, version)
	case "pip":
		return checkPip(pkg, version)
	case "nuget":
		return checkNuGet(pkg, version)
	default:
		return Result{}, &UsageError{Message: fmt.Sprintf("unsupported ecosystem: %s (supported: npm, pip|pypi, nuget)", ecosystem)}
	}
}

var replacementPattern = regexp.MustCompile(`(?i)(?:use|switch to|migrate to)\s+([@A-Za-z0-9_./-]+)`)

func findReplacement(message string) string {
	if message == "" {
		return ""
	}
	matches := replacementPattern.FindStringSubmatch(message)
	if len(matches) < 2 {
		return ""
	}
	return strings.TrimSpace(matches[1])
}

func httpClient() *http.Client {
	return &http.Client{Timeout: 25 * time.Second}
}

func getJSON(url string, target any) error {
	resp, err := httpClient().Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("request failed: %s", resp.Status)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if err := json.Unmarshal(body, target); err != nil {
		return err
	}

	return nil
}

func checkNPM(pkg, version string) (Result, error) {
	metaURL := fmt.Sprintf("https://registry.npmjs.org/%s", url.PathEscape(pkg))
	var meta npmPackageMeta
	if err := getJSON(metaURL, &meta); err != nil {
		return Result{}, fmt.Errorf("failed to query npm metadata for %s: %w", pkg, err)
	}

	targetVersion := strings.TrimSpace(version)
	if targetVersion == "" {
		targetVersion = latestVersion(meta.Versions)
		if targetVersion == "" {
			return Result{}, fmt.Errorf("no npm versions found for %s", pkg)
		}
	}

	entry, ok := meta.Versions[targetVersion]
	if !ok {
		return Result{}, fmt.Errorf("version %s not found for npm package %s", targetVersion, pkg)
	}

	message := strings.TrimSpace(entry.Deprecated)
	return Result{
		Ecosystem:   "npm",
		Package:     pkg,
		Version:     targetVersion,
		Deprecated:  message != "",
		Message:     message,
		Replacement: findReplacement(message),
	}, nil
}

func latestVersion(versions map[string]npmVersionMeta) string {
	keys := make([]string, 0, len(versions))
	for version := range versions {
		keys = append(keys, version)
	}
	sort.Strings(keys)
	if len(keys) == 0 {
		return ""
	}
	return keys[len(keys)-1]
}

type pipResponse struct {
	Info struct {
		Summary     string   `json:"summary"`
		Description string   `json:"description"`
		Classifiers []string `json:"classifiers"`
	} `json:"info"`
	URLs []struct {
		Yanked       bool   `json:"yanked"`
		YankedReason string `json:"yanked_reason"`
	} `json:"urls"`
}

func checkPip(pkg, version string) (Result, error) {
	base := "https://pypi.org/pypi/"
	target := strings.TrimSpace(version)
	encodedPackage := url.PathEscape(pkg)

	apiURL := ""
	if target == "" {
		apiURL = base + encodedPackage + "/json"
	} else {
		apiURL = base + encodedPackage + "/" + url.PathEscape(target) + "/json"
	}

	var payload pipResponse
	if err := getJSON(apiURL, &payload); err != nil {
		return Result{}, fmt.Errorf("failed to query PyPI metadata for %s%s: %w", pkg, suffixVersion(target), err)
	}

	deprecated := false
	message := ""
	for _, item := range payload.URLs {
		if item.Yanked {
			deprecated = true
			message = strings.TrimSpace(item.YankedReason)
			if message == "" {
				message = "Package release is yanked"
			}
			break
		}
	}

	if !deprecated {
		for _, classifier := range payload.Info.Classifiers {
			if strings.Contains(classifier, "Development Status :: 7 - Inactive") {
				deprecated = true
				message = "Package is marked as inactive by classifier"
				break
			}
		}
	}

	if !deprecated {
		haystack := strings.ToLower(payload.Info.Summary + "\n" + truncate(payload.Info.Description, 8000))
		if strings.Contains(haystack, "deprecated") || strings.Contains(haystack, "unmaintained") || strings.Contains(haystack, "obsolete") || strings.Contains(haystack, "no longer maintained") {
			deprecated = true
			message = "Package metadata indicates deprecation or maintenance end"
		}
	}

	return Result{
		Ecosystem:   "pip",
		Package:     pkg,
		Version:     target,
		Deprecated:  deprecated,
		Message:     message,
		Replacement: findReplacement(message),
	}, nil
}

type nugetRoot struct {
	Items []nugetPage `json:"items"`
}

type nugetPage struct {
	ID    string      `json:"@id"`
	Items []nugetItem `json:"items"`
}

type nugetItem struct {
	CatalogEntry nugetCatalog `json:"catalogEntry"`
}

type nugetCatalog struct {
	Version     string            `json:"version"`
	Deprecation *nugetDeprecation `json:"deprecation"`
}

type nugetDeprecation struct {
	Reasons          []string             `json:"reasons"`
	AlternatePackage *nugetAlternate      `json:"alternatePackage"`
	LegacyReason     map[string]any       `json:"-"`
}

type nugetAlternate struct {
	ID    string `json:"id"`
	Range string `json:"range"`
}

func checkNuGet(pkg, version string) (Result, error) {
	target := strings.TrimSpace(version)
	lower := strings.ToLower(pkg)
	apiURL := fmt.Sprintf("https://api.nuget.org/v3/registration5-semver1/%s/index.json", url.PathEscape(lower))

	var root nugetRoot
	if err := getJSON(apiURL, &root); err != nil {
		return Result{}, fmt.Errorf("failed to query NuGet metadata for %s%s: %w", pkg, suffixVersion(target), err)
	}

	entries := make([]nugetItem, 0)
	for _, page := range root.Items {
		if len(page.Items) > 0 {
			entries = append(entries, page.Items...)
			continue
		}
		if page.ID == "" {
			continue
		}
		var resolved nugetPage
		if err := getJSON(page.ID, &resolved); err != nil {
			continue
		}
		entries = append(entries, resolved.Items...)
	}

	if len(entries) == 0 {
		return Result{}, fmt.Errorf("no NuGet versions found for %s", pkg)
	}

	selected := nugetItem{}
	if target == "" {
		selected = entries[len(entries)-1]
		target = strings.TrimSpace(selected.CatalogEntry.Version)
	} else {
		found := false
		for _, item := range entries {
			if strings.EqualFold(strings.TrimSpace(item.CatalogEntry.Version), target) {
				selected = item
				found = true
				break
			}
		}
		if !found {
			return Result{}, fmt.Errorf("version %s not found for NuGet package %s", target, pkg)
		}
	}

	deprecated := selected.CatalogEntry.Deprecation != nil
	message := ""
	replacement := ""
	if deprecated {
		if len(selected.CatalogEntry.Deprecation.Reasons) > 0 {
			message = strings.Join(selected.CatalogEntry.Deprecation.Reasons, "; ")
		} else {
			message = "Package version is marked as deprecated in NuGet metadata"
		}
		alt := selected.CatalogEntry.Deprecation.AlternatePackage
		if alt != nil {
			if strings.TrimSpace(alt.ID) != "" && strings.TrimSpace(alt.Range) != "" {
				replacement = strings.TrimSpace(alt.ID) + " " + strings.TrimSpace(alt.Range)
			} else {
				replacement = strings.TrimSpace(alt.ID)
			}
		}
	}

	return Result{
		Ecosystem:   "nuget",
		Package:     pkg,
		Version:     target,
		Deprecated:  deprecated,
		Message:     message,
		Replacement: replacement,
	}, nil
}

func suffixVersion(version string) string {
	if strings.TrimSpace(version) == "" {
		return ""
	}
	return "@" + strings.TrimSpace(version)
}

func truncate(value string, max int) string {
	if max <= 0 || len(value) <= max {
		return value
	}
	return value[:max]
}
