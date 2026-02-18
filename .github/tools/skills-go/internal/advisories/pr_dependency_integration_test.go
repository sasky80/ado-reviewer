package advisories

import (
	"os"
	"testing"

	"ado-reviewer/.github/tools/skills-go/internal/testutil"
)

func TestGetPRDependencyAdvisories_Live(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping live integration test in short mode")
	}

	org, project, repositoryID, pullRequestID := testutil.RequireADOContext(t)
	if testutil.StringOrDefault(os.Getenv("GH_SEC_PAT"), "") == "" {
		t.Skip("set GH_SEC_PAT to run live integration tests")
	}

	iterationID := testutil.StringOrDefault(os.Getenv("ADO_IT_ITERATION"), "")
	result, err := GetPRDependencyAdvisories(org, project, repositoryID, pullRequestID, iterationID, 20)
	if err != nil {
		t.Fatalf("GetPRDependencyAdvisories failed: %v", err)
	}

	if _, ok := result["manifestFiles"].([]string); !ok {
		t.Fatalf("expected []string manifestFiles, got %T", result["manifestFiles"])
	}
	if _, ok := result["dependencies"].([]any); !ok {
		t.Fatalf("expected []any dependencies, got %T", result["dependencies"])
	}
	if _, ok := result["advisories"].([]any); !ok {
		t.Fatalf("expected []any advisories, got %T", result["advisories"])
	}

	depsChecked, ok := result["dependenciesChecked"].(int)
	if !ok {
		t.Fatalf("expected int dependenciesChecked, got %T", result["dependenciesChecked"])
	}
	advisoriesFound, ok := result["advisoriesFound"].(int)
	if !ok {
		t.Fatalf("expected int advisoriesFound, got %T", result["advisoriesFound"])
	}
	if advisoriesFound > depsChecked*20 && depsChecked > 0 {
		t.Fatalf("unexpected advisory count: dependenciesChecked=%d advisoriesFound=%d", depsChecked, advisoriesFound)
	}
}
