package diffmapper

import (
	"fmt"
	"strings"

	"ado-reviewer/tools/skills-go/internal/files"
	"ado-reviewer/tools/skills-go/internal/pullrequests"
)

func MapPRDiffLines(organization, project, repositoryID, pullRequestID, iterationID string) (map[string]any, error) {
	prDetails, err := pullrequests.GetDetails(organization, project, repositoryID, pullRequestID)
	if err != nil {
		return nil, err
	}
	sourceBranch := strings.TrimPrefix(toString(prDetails["sourceRefName"]), "refs/heads/")
	targetBranch := strings.TrimPrefix(toString(prDetails["targetRefName"]), "refs/heads/")

	changes, err := pullrequests.GetChanges(organization, project, repositoryID, pullRequestID, iterationID)
	if err != nil {
		return nil, err
	}
	projected := pullrequests.ProjectChangedFiles(changes, pullRequestID, iterationID)
	filesRaw, _ := projected["files"].([]any)
	if len(filesRaw) == 0 {
		if converted, ok := projected["files"].([]map[string]any); ok {
			filesRaw = make([]any, 0, len(converted))
			for _, item := range converted {
				filesRaw = append(filesRaw, item)
			}
		}
	}

	mapped := make([]map[string]any, 0)
	for _, raw := range filesRaw {
		fileEntry, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		path := toString(fileEntry["path"])
		if path == "" {
			continue
		}
		isFolder, _ := fileEntry["isFolder"].(bool)

		entry := map[string]any{
			"path":             path,
			"changeType":       fileEntry["changeType"],
			"changeTrackingId": fileEntry["changeTrackingId"],
			"isFolder":         isFolder,
		}

		if isFolder {
			entry["baseExists"] = false
			entry["prExists"] = false
			entry["lineMap"] = emptyLineMap()
			mapped = append(mapped, entry)
			continue
		}

		basePayload, baseErr := files.GetContent(organization, project, repositoryID, path, targetBranch, "branch")
		prPayload, prErr := files.GetContent(organization, project, repositoryID, path, sourceBranch, "branch")

		baseExists := baseErr == nil
		prExists := prErr == nil
		baseContent := ""
		prContent := ""
		if baseExists {
			baseContent = toString(basePayload["content"])
		}
		if prExists {
			prContent = toString(prPayload["content"])
		}

		entry["baseExists"] = baseExists
		entry["prExists"] = prExists
		entry["lineMap"] = buildSimpleLineMap(baseContent, prContent)
		mapped = append(mapped, entry)
	}

	return map[string]any{
		"pullRequestId": pullRequestID,
		"iterationId":   iterationID,
		"sourceBranch":  sourceBranch,
		"targetBranch":  targetBranch,
		"count":         len(mapped),
		"files":         mapped,
	}, nil
}

func buildSimpleLineMap(oldContent, newContent string) map[string]any {
	if oldContent == newContent {
		return emptyLineMap()
	}
	oldLines := splitLines(oldContent)
	newLines := splitLines(newContent)
	added := maxInt(0, len(newLines)-len(oldLines))
	deleted := maxInt(0, len(oldLines)-len(newLines))
	if oldContent != "" && newContent != "" {
		if added == 0 && deleted == 0 {
			added = len(newLines)
			deleted = len(oldLines)
		}
	}

	hunk := map[string]any{
		"index":       1,
		"oldStart":    1,
		"oldLines":    len(oldLines),
		"newStart":    1,
		"newLines":    len(newLines),
		"addedLines":  added,
		"deletedLines": deleted,
		"contextLines": 0,
	}
	return map[string]any{
		"hunkCount":   1,
		"totalAdded":  added,
		"totalDeleted": deleted,
		"totalContext": 0,
		"hunks":       []map[string]any{hunk},
	}
}

func emptyLineMap() map[string]any {
	return map[string]any{"hunkCount": 0, "totalAdded": 0, "totalDeleted": 0, "totalContext": 0, "hunks": []any{}}
}

func splitLines(s string) []string {
	if s == "" {
		return []string{}
	}
	return strings.Split(strings.ReplaceAll(s, "\r\n", "\n"), "\n")
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func toString(value any) string {
	str, _ := value.(string)
	return strings.TrimSpace(str)
}

func ValidateInputs(organization, project, repositoryID, pullRequestID, iterationID string) error {
	if strings.TrimSpace(organization) == "" || strings.TrimSpace(project) == "" || strings.TrimSpace(repositoryID) == "" || strings.TrimSpace(pullRequestID) == "" || strings.TrimSpace(iterationID) == "" {
		return fmt.Errorf("organization, project, repositoryId, pullRequestId and iterationId are required")
	}
	return nil
}
