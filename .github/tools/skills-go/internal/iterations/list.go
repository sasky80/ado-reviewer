package iterations

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/.github/tools/skills-go/internal/ado"
)

func List(organization, project, repositoryID, pullRequestID string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	projectName := strings.TrimSpace(project)
	if projectName == "" {
		return nil, fmt.Errorf("project is required")
	}

	repo := strings.TrimSpace(repositoryID)
	if repo == "" {
		return nil, fmt.Errorf("repositoryId is required")
	}

	prID := strings.TrimSpace(pullRequestID)
	if prID == "" {
		return nil, fmt.Errorf("pullRequestId is required")
	}

	projectEncoded := url.PathEscape(projectName)
	repoEncoded := url.PathEscape(repo)
	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/pullRequests/%s/iterations?api-version=7.2-preview", client.EncodedOrg, projectEncoded, repoEncoded, prID)

	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}

	return response, nil
}
