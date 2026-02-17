package commits

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/tools/skills-go/internal/ado"
)

func GetDiffs(organization, project, repositoryID, baseVersion, targetVersion, baseVersionType, targetVersionType string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	projectName := strings.TrimSpace(project)
	repo := strings.TrimSpace(repositoryID)
	base := strings.TrimSpace(baseVersion)
	target := strings.TrimSpace(targetVersion)
	if projectName == "" {
		return nil, fmt.Errorf("project is required")
	}
	if repo == "" {
		return nil, fmt.Errorf("repositoryId is required")
	}
	if base == "" || target == "" {
		return nil, fmt.Errorf("baseVersion and targetVersion are required")
	}
	if strings.TrimSpace(baseVersionType) == "" {
		baseVersionType = "commit"
	}
	if strings.TrimSpace(targetVersionType) == "" {
		targetVersionType = "commit"
	}

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/diffs/commits?baseVersion=%s&baseVersionType=%s&targetVersion=%s&targetVersionType=%s&api-version=7.2-preview", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), url.QueryEscape(base), url.QueryEscape(baseVersionType), url.QueryEscape(target), url.QueryEscape(targetVersionType))

	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}
	return response, nil
}
