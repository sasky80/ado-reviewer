package files

import (
	"strings"
)

func GetMultiple(organization, project, repositoryID, version, versionType string, paths []string) (map[string]any, error) {
	results := make([]map[string]any, 0, len(paths))
	succeeded := 0
	failed := 0
	for _, path := range paths {
		content, err := GetContent(organization, project, repositoryID, path, version, versionType)
		entry := map[string]any{"path": path}
		if err != nil {
			entry["status"] = "error"
			entry["error"] = err.Error()
			failed++
		} else {
			entry["status"] = "ok"
			entry["content"] = toString(content["content"])
			entry["commitId"] = toString(content["commitId"])
			entry["objectId"] = toString(content["objectId"])
			succeeded++
		}
		results = append(results, entry)
	}

	return map[string]any{
		"results":   results,
		"succeeded": succeeded,
		"failed":    failed,
		"total":     len(results),
	}, nil
}

func toString(value any) string {
	s, _ := value.(string)
	return strings.TrimSpace(s)
}
