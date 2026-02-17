package advisories

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

func GetGitHubAdvisories(ecosystem, pkg, version, severity string, perPage int) ([]any, error) {
	if strings.TrimSpace(ecosystem) == "" || strings.TrimSpace(pkg) == "" {
		return nil, fmt.Errorf("ecosystem and package are required")
	}
	if perPage <= 0 {
		perPage = 30
	}
	if perPage < 1 || perPage > 100 {
		return nil, fmt.Errorf("per_page must be an integer between 1 and 100")
	}

	token := strings.TrimSpace(os.Getenv("GH_SEC_PAT"))
	if token == "" {
		return nil, fmt.Errorf("environment variable GH_SEC_PAT is not set")
	}

	affects := strings.TrimSpace(pkg)
	if strings.TrimSpace(version) != "" {
		affects = affects + "@" + strings.TrimSpace(version)
	}

	query := "ecosystem=" + url.QueryEscape(ecosystem) + "&affects=" + url.QueryEscape(affects) + "&per_page=" + strconv.Itoa(perPage)
	if strings.TrimSpace(severity) != "" {
		query += "&severity=" + url.QueryEscape(strings.TrimSpace(severity))
	}

	requestURL := "https://api.github.com/advisories?" + query
	req, err := http.NewRequest(http.MethodGet, requestURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := (&http.Client{Timeout: 30 * time.Second}).Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		msg := strings.TrimSpace(string(body))
		if msg == "" {
			msg = resp.Status
		}
		return nil, fmt.Errorf(msg)
	}

	advisories := []any{}
	if err := json.Unmarshal(body, &advisories); err != nil {
		return nil, err
	}
	return advisories, nil
}
