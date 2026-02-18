package pullrequests

import "testing"

func TestPaginateMaps_ReturnsExpectedWindowAndHasMore(t *testing.T) {
	items := []map[string]any{
		{"id": 1},
		{"id": 2},
		{"id": 3},
		{"id": 4},
	}

	window, hasMore := paginateMaps(items, 1, 2)
	if !hasMore {
		t.Fatalf("expected hasMore=true")
	}
	if len(window) != 2 {
		t.Fatalf("expected 2 items, got %d", len(window))
	}
	if window[0]["id"] != 2 || window[1]["id"] != 3 {
		t.Fatalf("unexpected page contents: %#v", window)
	}
}

func TestPaginateMaps_OffsetBeyondLength(t *testing.T) {
	items := []map[string]any{{"id": 1}, {"id": 2}}

	window, hasMore := paginateMaps(items, 10, 5)
	if hasMore {
		t.Fatalf("expected hasMore=false")
	}
	if len(window) != 0 {
		t.Fatalf("expected empty page, got %d items", len(window))
	}
}

func TestPaginateMaps_LastPageHasNoMore(t *testing.T) {
	items := []map[string]any{{"id": 1}, {"id": 2}, {"id": 3}}

	window, hasMore := paginateMaps(items, 2, 5)
	if hasMore {
		t.Fatalf("expected hasMore=false on last page")
	}
	if len(window) != 1 {
		t.Fatalf("expected 1 item, got %d", len(window))
	}
	if window[0]["id"] != 3 {
		t.Fatalf("unexpected last-page item: %#v", window[0])
	}
}

func TestNormalizeBundleLimit_DefaultAndCap(t *testing.T) {
	tests := []struct {
		name         string
		value        int
		defaultValue int
		maxValue     int
		want         int
	}{
		{name: "uses default when zero", value: 0, defaultValue: 100, maxValue: 500, want: 100},
		{name: "uses default when negative", value: -1, defaultValue: 100, maxValue: 500, want: 100},
		{name: "keeps valid value", value: 150, defaultValue: 100, maxValue: 500, want: 150},
		{name: "caps at max", value: 999, defaultValue: 100, maxValue: 500, want: 500},
	}

	for _, testCase := range tests {
		t.Run(testCase.name, func(t *testing.T) {
			got := normalizeBundleLimit(testCase.value, testCase.defaultValue, testCase.maxValue)
			if got != testCase.want {
				t.Fatalf("normalizeBundleLimit(%d, %d, %d) = %d, want %d", testCase.value, testCase.defaultValue, testCase.maxValue, got, testCase.want)
			}
		})
	}
}
