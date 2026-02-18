package files

import (
	"sync"

	"ado-reviewer/.github/tools/skills-go/internal/shared"
)

const maxParallelContentRequests = 6

func GetMultiple(organization, project, repositoryID, version, versionType string, paths []string) (map[string]any, error) {
	results := make([]map[string]any, len(paths))
	semaphore := make(chan struct{}, maxParallelContentRequests)
	var wg sync.WaitGroup

	for index, path := range paths {
		index := index
		path := path
		wg.Add(1)
		go func() {
			defer wg.Done()
			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			content, err := GetContent(organization, project, repositoryID, path, version, versionType)
			entry := map[string]any{"path": path}
			if err != nil {
				entry["status"] = "error"
				entry["error"] = err.Error()
			} else {
				entry["status"] = "ok"
				entry["content"] = shared.TrimmedString(content["content"])
				entry["commitId"] = shared.TrimmedString(content["commitId"])
				entry["objectId"] = shared.TrimmedString(content["objectId"])
			}
			results[index] = entry
		}()
	}

	wg.Wait()

	succeeded := 0
	failed := 0
	for _, entry := range results {
		if shared.TrimmedString(entry["status"]) == "ok" {
			succeeded++
		} else {
			failed++
		}
	}

	return map[string]any{
		"results":   results,
		"succeeded": succeeded,
		"failed":    failed,
		"total":     len(results),
	}, nil
}

func ContentByPath(payload map[string]any) map[string]string {
	result := make(map[string]string)

	rawResults, _ := payload["results"].([]map[string]any)
	if len(rawResults) == 0 {
		if generic, ok := payload["results"].([]any); ok {
			for _, raw := range generic {
				entry, ok := raw.(map[string]any)
				if !ok {
					continue
				}
				if shared.TrimmedString(entry["status"]) != "ok" {
					continue
				}
				path := shared.TrimmedString(entry["path"])
				if path == "" {
					continue
				}
				result[path] = shared.TrimmedString(entry["content"])
			}
		}
		return result
	}

	for _, entry := range rawResults {
		if shared.TrimmedString(entry["status"]) != "ok" {
			continue
		}
		path := shared.TrimmedString(entry["path"])
		if path == "" {
			continue
		}
		result[path] = shared.TrimmedString(entry["content"])
	}

	return result
}
