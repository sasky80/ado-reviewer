package pullrequests

import (
	"fmt"
	"sort"
	"strconv"
	"strings"

	"ado-reviewer/tools/skills-go/internal/files"
	"ado-reviewer/tools/skills-go/internal/iterations"
)

const (
	defaultBundleFileLimit   = 100
	defaultBundleThreadLimit = 100
	maxBundleFileLimit       = 500
	maxBundleThreadLimit     = 500
)

type ReviewBundleOptions struct {
	Organization         string
	Project              string
	RepositoryID         string
	PullRequestID        string
	IterationID          string
	FileOffset           int
	FileLimit            int
	ThreadOffset         int
	ThreadLimit          int
	ThreadStatusFilter   string
	ExcludeSystemThreads bool
	IncludeLineMap       bool
}

func GetReviewBundle(options ReviewBundleOptions) (map[string]any, error) {
	org := strings.TrimSpace(options.Organization)
	project := strings.TrimSpace(options.Project)
	repo := strings.TrimSpace(options.RepositoryID)
	prID := strings.TrimSpace(options.PullRequestID)
	if org == "" || project == "" || repo == "" || prID == "" {
		return nil, fmt.Errorf("organization, project, repositoryId and pullRequestId are required")
	}

	fileOffset := options.FileOffset
	if fileOffset < 0 {
		return nil, fmt.Errorf("fileOffset must be >= 0")
	}
	threadOffset := options.ThreadOffset
	if threadOffset < 0 {
		return nil, fmt.Errorf("threadOffset must be >= 0")
	}

	fileLimit := normalizeBundleLimit(options.FileLimit, defaultBundleFileLimit, maxBundleFileLimit)
	threadLimit := normalizeBundleLimit(options.ThreadLimit, defaultBundleThreadLimit, maxBundleThreadLimit)

	prDetails, err := GetDetails(org, project, repo, prID)
	if err != nil {
		return nil, err
	}

	sourceBranch := strings.TrimPrefix(toBundleString(prDetails["sourceRefName"]), "refs/heads/")
	targetBranch := strings.TrimPrefix(toBundleString(prDetails["targetRefName"]), "refs/heads/")

	iterationID := strings.TrimSpace(options.IterationID)
	if iterationID == "" {
		latestIteration, err := resolveLatestIterationID(org, project, repo, prID)
		if err != nil {
			return nil, err
		}
		iterationID = latestIteration
	}

	changes, err := GetChanges(org, project, repo, prID, iterationID)
	if err != nil {
		return nil, err
	}
	projected := ProjectChangedFiles(changes, prID, iterationID)
	allFiles := asMapSlice(projected["files"])

	filesSlice, filesHasMore := paginateMaps(allFiles, fileOffset, fileLimit)
	if options.IncludeLineMap {
		for _, fileEntry := range filesSlice {
			path := toBundleString(fileEntry["path"])
			if path == "" {
				continue
			}
			isFolder, _ := fileEntry["isFolder"].(bool)
			if isFolder {
				fileEntry["lineMap"] = emptyBundleLineMap()
				fileEntry["baseExists"] = false
				fileEntry["prExists"] = false
				continue
			}

			basePayload, baseErr := files.GetContent(org, project, repo, path, targetBranch, "branch")
			prPayload, prErr := files.GetContent(org, project, repo, path, sourceBranch, "branch")

			baseExists := baseErr == nil
			prExists := prErr == nil
			baseContent := ""
			prContent := ""
			if baseExists {
				baseContent = toBundleString(basePayload["content"])
			}
			if prExists {
				prContent = toBundleString(prPayload["content"])
			}

			fileEntry["baseExists"] = baseExists
			fileEntry["prExists"] = prExists
			fileEntry["lineMap"] = buildBundleSimpleLineMap(baseContent, prContent)
		}
	}

	threadsResponse, err := GetThreads(org, project, repo, prID, strings.TrimSpace(options.ThreadStatusFilter), options.ExcludeSystemThreads)
	if err != nil {
		return nil, err
	}
	allThreads := asMapSlice(threadsResponse["value"])
	threadsSlice, threadsHasMore := paginateMaps(allThreads, threadOffset, threadLimit)

	warnings := make([]string, 0)
	if options.FileLimit > maxBundleFileLimit {
		warnings = append(warnings, fmt.Sprintf("fileLimit capped to %d", maxBundleFileLimit))
	}
	if options.ThreadLimit > maxBundleThreadLimit {
		warnings = append(warnings, fmt.Sprintf("threadLimit capped to %d", maxBundleThreadLimit))
	}

	bundle := map[string]any{
		"organization":  org,
		"project":       project,
		"repositoryId":  repo,
		"pullRequestId": prID,
		"iterationId":   iterationID,
		"sourceBranch":  sourceBranch,
		"targetBranch":  targetBranch,
		"summary": map[string]any{
			"totalChangedFiles":  len(allFiles),
			"totalThreads":       len(allThreads),
			"filePageReturned":   len(filesSlice),
			"threadPageReturned": len(threadsSlice),
			"filesHasMore":       filesHasMore,
			"threadsHasMore":     threadsHasMore,
		},
		"files": map[string]any{
			"offset":  fileOffset,
			"limit":   fileLimit,
			"total":   len(allFiles),
			"hasMore": filesHasMore,
			"items":   filesSlice,
		},
		"threads": map[string]any{
			"offset":  threadOffset,
			"limit":   threadLimit,
			"total":   len(allThreads),
			"hasMore": threadsHasMore,
			"items":   threadsSlice,
		},
		"pullRequest": prDetails,
		"warnings":    warnings,
	}

	if filesHasMore {
		bundle["nextFileOffset"] = fileOffset + len(filesSlice)
	}
	if threadsHasMore {
		bundle["nextThreadOffset"] = threadOffset + len(threadsSlice)
	}

	return bundle, nil
}

func resolveLatestIterationID(organization, project, repositoryID, pullRequestID string) (string, error) {
	response, err := iterations.List(organization, project, repositoryID, pullRequestID)
	if err != nil {
		return "", err
	}

	rawIterations, _ := response["value"].([]any)
	if len(rawIterations) == 0 {
		return "", fmt.Errorf("no iterations found for pull request %s", pullRequestID)
	}

	ids := make([]int, 0, len(rawIterations))
	for _, raw := range rawIterations {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		id := toBundleInt(item["id"])
		if id > 0 {
			ids = append(ids, id)
		}
	}
	if len(ids) == 0 {
		return "", fmt.Errorf("could not determine iteration id")
	}
	sort.Ints(ids)
	return strconv.Itoa(ids[len(ids)-1]), nil
}

func paginateMaps(items []map[string]any, offset, limit int) ([]map[string]any, bool) {
	if offset >= len(items) {
		return []map[string]any{}, false
	}
	end := offset + limit
	if end > len(items) {
		end = len(items)
	}
	return items[offset:end], end < len(items)
}

func asMapSlice(value any) []map[string]any {
	out := make([]map[string]any, 0)
	switch typed := value.(type) {
	case []map[string]any:
		return append(out, typed...)
	case []any:
		for _, raw := range typed {
			item, ok := raw.(map[string]any)
			if !ok {
				continue
			}
			out = append(out, item)
		}
	}
	return out
}

func toBundleString(value any) string {
	str, _ := value.(string)
	return strings.TrimSpace(str)
}

func toBundleInt(value any) int {
	switch typed := value.(type) {
	case int:
		return typed
	case int32:
		return int(typed)
	case int64:
		return int(typed)
	case float32:
		return int(typed)
	case float64:
		return int(typed)
	case string:
		parsed, err := strconv.Atoi(strings.TrimSpace(typed))
		if err == nil {
			return parsed
		}
	}
	return 0
}

func buildBundleSimpleLineMap(oldContent, newContent string) map[string]any {
	if oldContent == newContent {
		return emptyBundleLineMap()
	}
	oldLines := splitBundleLines(oldContent)
	newLines := splitBundleLines(newContent)
	added := maxBundleInt(0, len(newLines)-len(oldLines))
	deleted := maxBundleInt(0, len(oldLines)-len(newLines))
	if oldContent != "" && newContent != "" && added == 0 && deleted == 0 {
		added = len(newLines)
		deleted = len(oldLines)
	}

	hunk := map[string]any{
		"index":        1,
		"oldStart":     1,
		"oldLines":     len(oldLines),
		"newStart":     1,
		"newLines":     len(newLines),
		"addedLines":   added,
		"deletedLines": deleted,
		"contextLines": 0,
	}
	return map[string]any{
		"hunkCount":    1,
		"totalAdded":   added,
		"totalDeleted": deleted,
		"totalContext": 0,
		"hunks":        []map[string]any{hunk},
	}
}

func emptyBundleLineMap() map[string]any {
	return map[string]any{"hunkCount": 0, "totalAdded": 0, "totalDeleted": 0, "totalContext": 0, "hunks": []any{}}
}

func splitBundleLines(s string) []string {
	if s == "" {
		return []string{}
	}
	return strings.Split(strings.ReplaceAll(s, "\r\n", "\n"), "\n")
}

func maxBundleInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func normalizeBundleLimit(value, defaultValue, maxValue int) int {
	if value <= 0 {
		return defaultValue
	}
	if value > maxValue {
		return maxValue
	}
	return value
}
