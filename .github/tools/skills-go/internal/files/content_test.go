package files

import "testing"

func TestGetContent_Validation(t *testing.T) {
	t.Setenv("ADO_PAT_testorg", "token")

	if _, err := GetContent("testorg", "", "repo", "/a.txt", "", ""); err == nil || err.Error() != "project is required" {
		t.Fatalf("expected project validation error, got: %v", err)
	}

	if _, err := GetContent("testorg", "project", "", "/a.txt", "", ""); err == nil || err.Error() != "repositoryId is required" {
		t.Fatalf("expected repositoryId validation error, got: %v", err)
	}

	if _, err := GetContent("testorg", "project", "repo", "", "", ""); err == nil || err.Error() != "path is required" {
		t.Fatalf("expected path validation error, got: %v", err)
	}
}

func TestContentByPath(t *testing.T) {
	payload := map[string]any{
		"results": []any{
			map[string]any{"path": "/ok.txt", "status": "ok", "content": "hello"},
			map[string]any{"path": "/err.txt", "status": "error", "error": "boom"},
		},
	}

	content := ContentByPath(payload)
	if len(content) != 1 {
		t.Fatalf("expected 1 successful entry, got %d", len(content))
	}
	if content["/ok.txt"] != "hello" {
		t.Fatalf("expected /ok.txt content to be hello, got %q", content["/ok.txt"])
	}
}

func TestGetMultiple_EmptyPaths(t *testing.T) {
	result, err := GetMultiple("testorg", "project", "repo", "main", "branch", []string{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result["total"] != 0 || result["succeeded"] != 0 || result["failed"] != 0 {
		t.Fatalf("unexpected aggregate counts: %#v", result)
	}
}
