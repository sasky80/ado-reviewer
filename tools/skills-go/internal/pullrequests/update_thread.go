package pullrequests

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/tools/skills-go/internal/ado"
)

func UpdateThread(organization, project, repositoryID, pullRequestID, threadID, reply, status string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}
	projectName := strings.TrimSpace(project)
	repo := strings.TrimSpace(repositoryID)
	prID := strings.TrimSpace(pullRequestID)
	tID := strings.TrimSpace(threadID)
	rep := strings.TrimSpace(reply)
	st := strings.TrimSpace(status)
	if projectName == "" || repo == "" || prID == "" || tID == "" {
		return nil, fmt.Errorf("organization, project, repositoryId, pullRequestId and threadId are required")
	}
	if rep == "-" {
		rep = ""
	}
	if rep == "" && st == "" {
		return nil, fmt.Errorf("at least one of reply or status must be provided")
	}

	baseURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/pullRequests/%s/threads/%s", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), prID, tID)
	result := map[string]any{}
	if rep != "" {
		commentURL := baseURL + "/comments?api-version=7.2-preview"
		replyPayload := map[string]any{"content": rep, "parentCommentId": 1, "commentType": "text"}
		replyResponse := map[string]any{}
		if err := client.PostJSON(commentURL, replyPayload, &replyResponse); err != nil {
			return nil, err
		}
		result["reply"] = replyResponse
	}
	if st != "" {
		threadURL := baseURL + "?api-version=7.2-preview"
		statusResponse := map[string]any{}
		if err := client.PatchJSON(threadURL, map[string]string{"status": st}, &statusResponse); err != nil {
			return nil, err
		}
		result["thread"] = statusResponse
	}
	return result, nil
}
