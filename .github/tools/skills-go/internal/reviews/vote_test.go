package reviews

import "testing"

func TestSetVote_Validation(t *testing.T) {
	t.Setenv("ADO_PAT_testorg", "token")

	if _, err := SetVote("testorg", "", "repo", "123", 10); err == nil || err.Error() != "project is required" {
		t.Fatalf("expected project validation error, got: %v", err)
	}

	if _, err := SetVote("testorg", "project", "", "123", 10); err == nil || err.Error() != "repositoryId is required" {
		t.Fatalf("expected repositoryId validation error, got: %v", err)
	}

	if _, err := SetVote("testorg", "project", "repo", "", 10); err == nil || err.Error() != "pullRequestId is required" {
		t.Fatalf("expected pullRequestId validation error, got: %v", err)
	}
}
