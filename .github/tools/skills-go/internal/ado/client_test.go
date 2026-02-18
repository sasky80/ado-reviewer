package ado

import "testing"

func TestNormalizeADOFilePath(t *testing.T) {
	testCases := []struct {
		name    string
		input   string
		want    string
		wantErr bool
	}{
		{name: "empty stays empty", input: "", want: ""},
		{name: "dash passthrough", input: "-", want: "-"},
		{name: "relative path gets leading slash", input: "src/app.js", want: "/src/app.js"},
		{name: "leading dot slash removed", input: "./src/app.js", want: "/src/app.js"},
		{name: "windows separators normalized", input: ".\\src\\app.js", want: "/src/app.js"},
		{name: "double slashes collapsed", input: "/src//nested///app.js", want: "/src/nested/app.js"},
		{name: "windows absolute path rejected", input: "C:\\repo\\app.js", wantErr: true},
		{name: "unc path rejected", input: "//server/share/file.js", wantErr: true},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			got, err := NormalizeADOFilePath(testCase.input)
			if testCase.wantErr {
				if err == nil {
					t.Fatalf("expected error, got nil")
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != testCase.want {
				t.Fatalf("NormalizeADOFilePath(%q) = %q, want %q", testCase.input, got, testCase.want)
			}
		})
	}
}
