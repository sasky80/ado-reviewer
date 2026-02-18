package files

import (
	"fmt"
	"net/url"
	"strings"

	"ado-reviewer/.github/tools/skills-go/internal/ado"
)

func GetContent(organization, project, repositoryID, path, version, versionType string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	projectName := strings.TrimSpace(project)
	repo := strings.TrimSpace(repositoryID)
	if projectName == "" {
		return nil, fmt.Errorf("project is required")
	}
	if repo == "" {
		return nil, fmt.Errorf("repositoryId is required")
	}

	normalizedPath, err := ado.NormalizeADOFilePath(path)
	if err != nil {
		return nil, err
	}
	if normalizedPath == "" {
		return nil, fmt.Errorf("path is required")
	}

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/%s/_apis/git/repositories/%s/items?path=%s&includeContent=true&api-version=7.2-preview", client.EncodedOrg, url.PathEscape(projectName), url.PathEscape(repo), url.QueryEscape(normalizedPath))
	if strings.TrimSpace(version) != "" {
		if strings.TrimSpace(versionType) == "" {
			versionType = "branch"
		}
		apiURL += fmt.Sprintf("&versionDescriptor.version=%s&versionDescriptor.versionType=%s", url.QueryEscape(strings.TrimSpace(version)), url.QueryEscape(strings.TrimSpace(versionType)))
	}

	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}
	return response, nil
}
