package diffmapper

import "testing"

func TestBuildSimpleLineMap_EqualContentReturnsEmpty(t *testing.T) {
	result := buildSimpleLineMap("a\nb\n", "a\nb\n")

	if result["hunkCount"] != 0 {
		t.Fatalf("expected hunkCount 0, got %v", result["hunkCount"])
	}
	if result["totalAdded"] != 0 || result["totalDeleted"] != 0 {
		t.Fatalf("expected no adds/deletes, got added=%v deleted=%v", result["totalAdded"], result["totalDeleted"])
	}
}

func TestBuildSimpleLineMap_SameLineCountMarksReplace(t *testing.T) {
	result := buildSimpleLineMap("a\nb\n", "x\ny\n")

	if result["hunkCount"] != 1 {
		t.Fatalf("expected one hunk, got %v", result["hunkCount"])
	}
	if result["totalAdded"] != 3 {
		t.Fatalf("expected totalAdded 3, got %v", result["totalAdded"])
	}
	if result["totalDeleted"] != 3 {
		t.Fatalf("expected totalDeleted 3, got %v", result["totalDeleted"])
	}

	hunks, ok := result["hunks"].([]map[string]any)
	if !ok || len(hunks) != 1 {
		t.Fatalf("expected one typed hunk entry, got %T / len=%d", result["hunks"], len(hunks))
	}
}

func TestBuildSimpleLineMap_AddedLines(t *testing.T) {
	result := buildSimpleLineMap("a\n", "a\nb\nc\n")

	if result["totalAdded"] != 2 {
		t.Fatalf("expected totalAdded 2, got %v", result["totalAdded"])
	}
	if result["totalDeleted"] != 0 {
		t.Fatalf("expected totalDeleted 0, got %v", result["totalDeleted"])
	}
}

func TestSplitLines_NormalizesCRLF(t *testing.T) {
	lines := splitLines("a\r\nb\r\n")
	if len(lines) != 3 {
		t.Fatalf("expected 3 lines including trailing empty, got %d", len(lines))
	}
	if lines[0] != "a" || lines[1] != "b" {
		t.Fatalf("unexpected split result: %#v", lines)
	}
}

func TestValidateInputs(t *testing.T) {
	if err := ValidateInputs("org", "proj", "repo", "12", "3"); err != nil {
		t.Fatalf("expected no error for valid inputs, got %v", err)
	}
	if err := ValidateInputs(" ", "proj", "repo", "12", "3"); err == nil {
		t.Fatal("expected error when required input is blank")
	}
}
