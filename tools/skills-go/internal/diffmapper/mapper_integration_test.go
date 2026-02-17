package diffmapper

import (
	"os"
	"regexp"
	"strconv"
	"testing"

	"ado-reviewer/tools/skills-go/internal/iterations"
)

var invalidPATChars = regexp.MustCompile(`[^A-Za-z0-9_]`)

func TestMapPRDiffLines_Live(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping live integration test in short mode")
	}

	org, project, repositoryID, pullRequestID := requireADOContext(t)
	iterationID := stringsOrDefault(os.Getenv("ADO_IT_ITERATION"), "")
	if iterationID == "" {
		latest, err := latestIterationID(org, project, repositoryID, pullRequestID)
		if err != nil {
			t.Fatalf("failed to resolve latest iteration: %v", err)
		}
		iterationID = latest
	}

	result, err := MapPRDiffLines(org, project, repositoryID, pullRequestID, iterationID)
	if err != nil {
		t.Fatalf("MapPRDiffLines failed: %v", err)
	}

	if result["pullRequestId"] != pullRequestID {
		t.Fatalf("expected pullRequestId %q, got %v", pullRequestID, result["pullRequestId"])
	}
	if result["iterationId"] != iterationID {
		t.Fatalf("expected iterationId %q, got %v", iterationID, result["iterationId"])
	}

	count, ok := result["count"].(int)
	if !ok {
		t.Fatalf("expected int count, got %T", result["count"])
	}
	files, ok := result["files"].([]map[string]any)
	if !ok {
		t.Fatalf("expected []map[string]any files, got %T", result["files"])
	}
	if count != len(files) {
		t.Fatalf("count mismatch: count=%d len(files)=%d", count, len(files))
	}
}

func requireADOContext(t *testing.T) (org, project, repositoryID, pullRequestID string) {
	t.Helper()
	org = stringsOrDefault(os.Getenv("ADO_IT_ORG"), "")
	project = stringsOrDefault(os.Getenv("ADO_IT_PROJECT"), "")
	repositoryID = stringsOrDefault(os.Getenv("ADO_IT_REPO"), "")
	pullRequestID = stringsOrDefault(os.Getenv("ADO_IT_PR"), "")
	if org == "" || project == "" || repositoryID == "" || pullRequestID == "" {
		t.Skip("set ADO_IT_ORG, ADO_IT_PROJECT, ADO_IT_REPO, and ADO_IT_PR to run live integration tests")
	}

	patVar := "ADO_PAT_" + normalizePATVarSuffix(org)
	if stringsOrDefault(os.Getenv(patVar), "") == "" {
		t.Skipf("set %s to run live integration tests", patVar)
	}

	return org, project, repositoryID, pullRequestID
}

func latestIterationID(organization, project, repositoryID, pullRequestID string) (string, error) {
	payload, err := iterations.List(organization, project, repositoryID, pullRequestID)
	if err != nil {
		return "", err
	}

	maxValue := 0
	values, _ := payload["value"].([]any)
	for _, raw := range values {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if id, ok := item["id"].(float64); ok {
			intID := int(id)
			if intID > maxValue {
				maxValue = intID
			}
		}
	}
	if maxValue == 0 {
		return "", strconv.ErrSyntax
	}

	return strconv.Itoa(maxValue), nil
}

func normalizePATVarSuffix(organization string) string {
	suffix := invalidPATChars.ReplaceAllString(organization, "_")
	if suffix != "" && suffix[0] >= '0' && suffix[0] <= '9' {
		suffix = "_" + suffix
	}
	return suffix
}

func stringsOrDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
