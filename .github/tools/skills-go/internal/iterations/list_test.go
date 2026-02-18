package iterations

import "testing"

func TestList_Validation(t *testing.T) {
	t.Setenv("ADO_PAT_testorg", "token")

	if _, err := List("testorg", "", "repo", "123"); err == nil || err.Error() != "project is required" {
		t.Fatalf("expected project validation error, got: %v", err)
	}

	if _, err := List("testorg", "project", "", "123"); err == nil || err.Error() != "repositoryId is required" {
		t.Fatalf("expected repositoryId validation error, got: %v", err)
	}

	if _, err := List("testorg", "project", "repo", ""); err == nil || err.Error() != "pullRequestId is required" {
		t.Fatalf("expected pullRequestId validation error, got: %v", err)
	}
}
