package pullrequests

import (
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"ado-reviewer/.github/tools/skills-go/internal/ado"
)

func PostComment(organization, project, repositoryID, pullRequestID, filePath, line, comment string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}
	projectName := strings.TrimSpace(project)
	repo := strings.TrimSpace(repositoryID)
	prID := strings.TrimSpace(pullRequestID)
	if projectName == "" || repo == "" || prID == "" {
		return nil, fmt.Errorf("organization, project, repositoryId and pullRequestId are required")
	}
	if strings.TrimSpace(comment) == "" {
		return nil, fmt.Errorf("comment is required")
	}

	payload := map[string]any{
		"comments": []map[string]any{{
			"parentCommentId": 0,
			"content":         comment,
			"commentType":     "text",
		}},
		"status": "active",
	}

	trimPath := strings.TrimSpace(filePath)
	if trimPath != "" && trimPath != "-" {
		normalized, err := ado.NormalizeADOFilePath(trimPath)
		if err != nil {
			return nil, err
		}
		lineNum, _ := strconv.Atoi(strings.TrimSpace(line))
		if lineNum < 1 {
			lineNum = 1
		}
		payload["threadContext"] = map[string]any{
			"filePath":       normalized,
			"rightFileStart": map[string]int{"line": lineNum, "offset": 1},
			"rightFileEnd":   map[string]int{"line": lineNum, "offset": 1},
		}
	}

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/pullRequests/%s/threads?api-version=7.2-preview", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), prID)
	response := map[string]any{}
	if err := client.PostJSON(apiURL, payload, &response); err != nil {
		return nil, err
	}
	return response, nil
}
