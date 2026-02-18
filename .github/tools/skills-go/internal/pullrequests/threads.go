package pullrequests

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/.github/tools/skills-go/internal/ado"
)

func GetThreads(organization, project, repositoryID, pullRequestID, statusFilter string, excludeSystem bool) (map[string]any, error) {
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

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/pullRequests/%s/threads?api-version=7.2-preview", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), prID)
	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}

	rawThreads, _ := response["value"].([]any)
	filtered := make([]any, 0, len(rawThreads))
	for _, t := range rawThreads {
		thread, ok := t.(map[string]any)
		if !ok {
			continue
		}
		if excludeSystem && isSystemThread(thread) {
			continue
		}
		if strings.TrimSpace(statusFilter) != "" {
			status, _ := thread["status"].(string)
			if status != statusFilter {
				continue
			}
		}
		filtered = append(filtered, thread)
	}
	response["value"] = filtered
	response["count"] = len(filtered)
	return response, nil
}

func isSystemThread(thread map[string]any) bool {
	if props, ok := thread["properties"].(map[string]any); ok {
		for k := range props {
			if strings.HasPrefix(k, "CodeReview") {
				return true
			}
		}
	}

	comments, _ := thread["comments"].([]any)
	if len(comments) == 0 {
		return false
	}
	allSystem := true
	for _, raw := range comments {
		comment, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if commentType, _ := comment["commentType"].(string); commentType == "system" {
			continue
		}
		author, _ := comment["author"].(map[string]any)
		displayName, _ := author["displayName"].(string)
		if strings.HasPrefix(displayName, "Microsoft.") {
			continue
		}
		allSystem = false
		break
	}
	return allSystem
}
