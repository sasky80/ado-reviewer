package projects

import (
	"fmt"

	"ado-reviewer/.github/tools/skills-go/internal/ado"
)

func List(organization string) (map[string]any, error) {
	client, err := ado.NewClient(organization)
	if err != nil {
		return nil, err
	}

	apiURL := fmt.Sprintf("https://dev.azure.com/%s/_apis/projects?api-version=7.2-preview", client.EncodedOrg)
	response := map[string]any{}
	if err := client.GetJSON(apiURL, &response); err != nil {
		return nil, err
	}

	return response, nil
}
