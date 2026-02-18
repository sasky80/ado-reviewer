package deprecated

import "testing"

func TestFindReplacement(t *testing.T) {
	testCases := []struct {
		name    string
		message string
		want    string
	}{
		{name: "empty", message: "", want: ""},
		{name: "use replacement", message: "This package is deprecated, use @scope/new-pkg instead", want: "@scope/new-pkg"},
		{name: "switch to replacement", message: "Please switch to new.module", want: "new.module"},
		{name: "no replacement text", message: "deprecated but no migration target", want: ""},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			got := findReplacement(testCase.message)
			if got != testCase.want {
				t.Fatalf("findReplacement(%q) = %q, want %q", testCase.message, got, testCase.want)
			}
		})
	}
}

func TestLatestVersion(t *testing.T) {
	versions := map[string]npmVersionMeta{
		"1.0.0": {},
		"1.2.0": {},
		"1.1.0": {},
	}
	if got := latestVersion(versions); got != "1.2.0" {
		t.Fatalf("latestVersion() = %q, want %q", got, "1.2.0")
	}
}

func TestTruncate(t *testing.T) {
	if got := truncate("abcdef", 3); got != "abc" {
		t.Fatalf("truncate() = %q, want %q", got, "abc")
	}
	if got := truncate("abc", 10); got != "abc" {
		t.Fatalf("truncate() = %q, want %q", got, "abc")
	}
}
