package commits

import "testing"

func TestGetDiffs_Validation(t *testing.T) {
	t.Setenv("ADO_PAT_testorg", "token")

	if _, err := GetDiffs("testorg", "", "repo", "base", "target", "", ""); err == nil || err.Error() != "project is required" {
		t.Fatalf("expected project validation error, got: %v", err)
	}

	if _, err := GetDiffs("testorg", "project", "", "base", "target", "", ""); err == nil || err.Error() != "repositoryId is required" {
		t.Fatalf("expected repositoryId validation error, got: %v", err)
	}

	if _, err := GetDiffs("testorg", "project", "repo", "", "", "", ""); err == nil || err.Error() != "baseVersion and targetVersion are required" {
		t.Fatalf("expected base/target validation error, got: %v", err)
	}
}
