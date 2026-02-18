package advisories

import (
	"reflect"
	"testing"
)

func TestFindManifestPaths_SortsAndDeduplicates(t *testing.T) {
	projected := map[string]any{
		"files": []any{
			map[string]any{"path": "/z/ignore.txt"},
			map[string]any{"path": "/b/package.json"},
			map[string]any{"path": "/a/requirements.txt"},
			map[string]any{"path": "/b/package.json"},
			map[string]any{"path": "/c/go.mod"},
		},
	}

	paths := findManifestPaths(projected)
	expected := []string{"/a/requirements.txt", "/b/package.json", "/c/go.mod"}
	if !reflect.DeepEqual(paths, expected) {
		t.Fatalf("unexpected manifest paths\nexpected: %#v\nactual:   %#v", expected, paths)
	}
}

func TestParsePackageJSON(t *testing.T) {
	content := `{
	  "dependencies": {"lodash": "^4.17.21"},
	  "devDependencies": {"vitest": "1.6.0"}
	}`
	deps := parseDependencies("/app/package.json", content)

	if len(deps) != 2 {
		t.Fatalf("expected 2 deps, got %d", len(deps))
	}
	if deps[0].Ecosystem != "npm" || deps[1].Ecosystem != "npm" {
		t.Fatalf("expected npm ecosystem, got %#v", deps)
	}
}

func TestParseRequirements_IgnoresFlagsAndComments(t *testing.T) {
	content := "# base\nrequests==2.31.0\n-r other.txt\npydantic>=2.0\n"
	deps := parseDependencies("/svc/requirements.txt", content)

	if len(deps) != 2 {
		t.Fatalf("expected 2 parsed deps, got %d (%#v)", len(deps), deps)
	}
	if deps[0].Package != "requests" || deps[0].Version != "2.31.0" {
		t.Fatalf("unexpected first dep: %#v", deps[0])
	}
	if deps[1].Package != "pydantic" || deps[1].Version != "2.0" {
		t.Fatalf("unexpected second dep: %#v", deps[1])
	}
}

func TestParseGoMod_RequireBlockAndSingleLine(t *testing.T) {
	content := `module example.com/test

go 1.23

require (
	github.com/pkg/errors v0.9.1
	rsc.io/quote v1.5.2
)

require golang.org/x/text v0.18.0
`
	deps := parseDependencies("/api/go.mod", content)

	if len(deps) != 3 {
		t.Fatalf("expected 3 deps, got %d (%#v)", len(deps), deps)
	}
	if deps[0].Ecosystem != "go" {
		t.Fatalf("expected go ecosystem, got %#v", deps[0])
	}
}

func TestParseCargoLock(t *testing.T) {
	content := `[[package]]
name = "serde"
version = "1.0.203"

[[package]]
name = "tokio"
version = "1.39.2"
`
	deps := parseDependencies("/rust/Cargo.lock", content)

	if len(deps) != 2 {
		t.Fatalf("expected 2 deps, got %d", len(deps))
	}
	if deps[0].Ecosystem != "rust" || deps[1].Ecosystem != "rust" {
		t.Fatalf("expected rust ecosystem deps, got %#v", deps)
	}
}

func TestMaxIterationID(t *testing.T) {
	payload := map[string]any{
		"value": []any{
			map[string]any{"id": float64(2)},
			map[string]any{"id": float64(8)},
			map[string]any{"id": float64(4)},
		},
	}
	if got := maxIterationID(payload); got != 8 {
		t.Fatalf("expected max id 8, got %d", got)
	}
}
