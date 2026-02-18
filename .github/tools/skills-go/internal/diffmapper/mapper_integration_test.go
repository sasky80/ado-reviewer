package diffmapper

import (
	"os"
	"strconv"
	"testing"

	"ado-reviewer/.github/tools/skills-go/internal/iterations"
	"ado-reviewer/.github/tools/skills-go/internal/testutil"
)

func TestMapPRDiffLines_Live(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping live integration test in short mode")
	}

	org, project, repositoryID, pullRequestID := testutil.RequireADOContext(t)
	iterationID := testutil.StringOrDefault(os.Getenv("ADO_IT_ITERATION"), "")
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
