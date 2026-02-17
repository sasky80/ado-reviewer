package ado

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strings"
	"time"
)

type Client struct {
	Organization string
	EncodedOrg   string
	headers      http.Header
	httpClient   *http.Client
}

var invalidPATChars = regexp.MustCompile(`[^A-Za-z0-9_]`)

func NewClient(organization string) (*Client, error) {
	org := strings.TrimSpace(organization)
	if org == "" {
		return nil, fmt.Errorf("organization is required")
	}

	suffix := invalidPATChars.ReplaceAllString(org, "_")
	if suffix != "" && suffix[0] >= '0' && suffix[0] <= '9' {
		suffix = "_" + suffix
	}

	patVar := "ADO_PAT_" + suffix
	pat, ok := os.LookupEnv(patVar)
	if !ok || strings.TrimSpace(pat) == "" {
		return nil, fmt.Errorf("environment variable %s is not set", patVar)
	}

	token := base64.StdEncoding.EncodeToString([]byte(":" + pat))
	headers := make(http.Header)
	headers.Set("Authorization", "Basic "+token)
	headers.Set("Accept", "application/json")

	return &Client{
		Organization: org,
		EncodedOrg:   url.PathEscape(org),
		headers:      headers,
		httpClient:   &http.Client{Timeout: 30 * time.Second},
	}, nil
}

func (c *Client) GetJSON(rawURL string, target any) error {
	return c.doJSON(http.MethodGet, rawURL, nil, target)
}

func (c *Client) PostJSON(rawURL string, body any, target any) error {
	return c.doJSON(http.MethodPost, rawURL, body, target)
}

func (c *Client) PutJSON(rawURL string, body any, target any) error {
	return c.doJSON(http.MethodPut, rawURL, body, target)
}

func (c *Client) PatchJSON(rawURL string, body any, target any) error {
	return c.doJSON(http.MethodPatch, rawURL, body, target)
}

func (c *Client) GetAuthenticatedUserID() (string, error) {
	var payload struct {
		AuthenticatedUser struct {
			ID string `json:"id"`
		} `json:"authenticatedUser"`
	}

	connURL := fmt.Sprintf("https://dev.azure.com/%s/_apis/connectionData", c.EncodedOrg)
	if err := c.GetJSON(connURL, &payload); err != nil {
		return "", err
	}

	id := strings.TrimSpace(payload.AuthenticatedUser.ID)
	if id == "" {
		return "", fmt.Errorf("authenticated user id not found")
	}

	return id, nil
}

func NormalizeADOFilePath(path string) (string, error) {
	trimmed := strings.TrimSpace(path)
	if trimmed == "" || trimmed == "-" {
		return trimmed, nil
	}

	normalized := strings.ReplaceAll(trimmed, "\\", "/")
	if regexp.MustCompile(`^[A-Za-z]:/`).MatchString(normalized) || strings.HasPrefix(normalized, "//") {
		return "", fmt.Errorf("FilePath must be repository-relative (for example: /src/app.js). Received: '%s'", path)
	}

	for strings.HasPrefix(normalized, "./") {
		normalized = strings.TrimPrefix(normalized, "./")
	}
	for strings.Contains(normalized, "//") {
		normalized = strings.ReplaceAll(normalized, "//", "/")
	}
	if !strings.HasPrefix(normalized, "/") {
		normalized = "/" + normalized
	}

	return normalized, nil
}

func (c *Client) doJSON(method, rawURL string, body any, target any) error {
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(encoded)
	}

	req, err := http.NewRequest(method, rawURL, reader)
	if err != nil {
		return err
	}

	req.Header = c.headers.Clone()
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	payload, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		message := strings.TrimSpace(string(payload))
		if message == "" {
			message = resp.Status
		}
		return fmt.Errorf("request failed: %s", message)
	}

	if target == nil || len(payload) == 0 {
		return nil
	}

	if err := json.Unmarshal(payload, target); err != nil {
		return err
	}

	return nil
}
