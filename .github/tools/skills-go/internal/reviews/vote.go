package reviews

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/.github/tools/skills-go/internal/ado"
)

func SetVote(organization, project, repositoryID, pullRequestID string, vote int) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	projectName := strings.TrimSpace(project)
	repo := strings.TrimSpace(repositoryID)
	prID := strings.TrimSpace(pullRequestID)
	if projectName == "" {
		return nil, fmt.Errorf("project is required")
	}
	if repo == "" {
		return nil, fmt.Errorf("repositoryId is required")
	}
	if prID == "" {
		return nil, fmt.Errorf("pullRequestId is required")
	}

	reviewerID, err := client.GetAuthenticatedUserID()
	if err != nil {
		return nil, err
	}

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/pullRequests/%s/reviewers/%s?api-version=7.2-preview", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), prID, url.PathEscape(reviewerID))

	response := map[string]any{}
	if err := client.PutJSON(apiURL, map[string]int{"vote": vote}, &response); err != nil {
		return nil, err
	}
	return response, nil
}
