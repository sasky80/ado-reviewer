package projects

import "testing"

func TestList_RequiresOrganization(t *testing.T) {
	if _, err := List(""); err == nil || err.Error() != "organization is required" {
		t.Fatalf("expected organization validation error, got: %v", err)
	}
}
