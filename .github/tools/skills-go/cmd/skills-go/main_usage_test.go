package main

import "testing"

func TestUsageGetCommitDiffs(t *testing.T) {
	want := "usage: skills-go get-commit-diffs <organization> <project> <repositoryId> <baseVersion> <targetVersion> [baseVersionType] [targetVersionType]"
	if usageGetCommitDiffs != want {
		t.Fatalf("usageGetCommitDiffs mismatch\nwant: %q\n got: %q", want, usageGetCommitDiffs)
	}
}
