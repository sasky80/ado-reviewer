package pullrequests

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/tools/skills-go/internal/ado"
)

func GetChanges(organization, project, repositoryID, pullRequestID, iterationID string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	projectName := strings.TrimSpace(project)
	repo := strings.TrimSpace(repositoryID)
	prID := strings.TrimSpace(pullRequestID)
	iter := strings.TrimSpace(iterationID)
	if projectName == "" {
		return nil, fmt.Errorf("project is required")
	}
	if repo == "" {
		return nil, fmt.Errorf("repositoryId is required")
	}
	if prID == "" {
		return nil, fmt.Errorf("pullRequestId is required")
	}
	if iter == "" {
		return nil, fmt.Errorf("iterationId is required")
	}

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/pullRequests/%s/iterations/%s/changes?api-version=7.2-preview", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), prID, iter)

	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}
	return response, nil
}
