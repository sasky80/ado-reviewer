package advisories

import (
	"os"
	"regexp"
	"testing"
)

var invalidPATChars = regexp.MustCompile(`[^A-Za-z0-9_]`)

func TestGetPRDependencyAdvisories_Live(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping live integration test in short mode")
	}

	org, project, repositoryID, pullRequestID := requireADOContext(t)
	if stringsOrDefault(os.Getenv("GH_SEC_PAT"), "") == "" {
		t.Skip("set GH_SEC_PAT to run live integration tests")
	}

	iterationID := stringsOrDefault(os.Getenv("ADO_IT_ITERATION"), "")
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
