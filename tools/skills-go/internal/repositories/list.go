package repositories

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/tools/skills-go/internal/ado"
)

func List(organization, project string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	projectName := strings.TrimSpace(project)
	if projectName == "" {
		return nil, fmt.Errorf("project is required")
	}

	projectEncoded := url.PathEscape(projectName)
	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories?api-version=7.2-preview", client.EncodedOrg, projectEncoded)
	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}

	return response, nil
}
