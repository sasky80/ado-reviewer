package repositories

import "testing"

func TestList_Validation(t *testing.T) {
	t.Setenv("ADO_PAT_testorg", "token")

	if _, err := List("testorg", ""); err == nil || err.Error() != "project is required" {
		t.Fatalf("expected project validation error, got: %v", err)
	}
}
