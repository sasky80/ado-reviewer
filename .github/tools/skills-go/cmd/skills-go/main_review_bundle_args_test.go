package main

import (
	"testing"
)

func TestParseReviewBundleOptions_InsufficientArgs(t *testing.T) {
	_, err := parseReviewBundleOptions([]string{"org", "proj", "repo"})
	if err == nil {
		t.Fatalf("expected usage error for insufficient args")
	}

	wantErr := "usage: skills-go get-pr-review-bundle <organization> <project> <repositoryId> <pullRequestId> [iterationId] [fileOffset] [fileLimit] [threadOffset] [threadLimit] [statusFilter] [excludeSystem] [includeLineMap]"
	if err.Error() != wantErr {
		t.Fatalf("expected error %q, got %q", wantErr, err.Error())
	}
}

func TestParseReviewBundleOptions_Defaults(t *testing.T) {
	options, err := parseReviewBundleOptions([]string{"org", "proj", "repo", "123"})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if options.Organization != "org" || options.Project != "proj" || options.RepositoryID != "repo" || options.PullRequestID != "123" {
		t.Fatalf("unexpected identity fields: %#v", options)
	}
	if options.IterationID != "" {
		t.Fatalf("expected empty iteration id, got %q", options.IterationID)
	}
	if options.FileOffset != 0 || options.ThreadOffset != 0 {
		t.Fatalf("expected zero offsets, got file=%d thread=%d", options.FileOffset, options.ThreadOffset)
	}
	if options.FileLimit != 100 || options.ThreadLimit != 100 {
		t.Fatalf("expected default limits 100/100, got file=%d thread=%d", options.FileLimit, options.ThreadLimit)
	}
	if !options.ExcludeSystemThreads {
		t.Fatalf("expected excludeSystemThreads=true by default")
	}
	if options.IncludeLineMap {
		t.Fatalf("expected includeLineMap=false by default")
	}
}

func TestParseReviewBundleOptions_ExplicitValues(t *testing.T) {
	args := []string{"org", "proj", "repo", "123", "9", "10", "20", "30", "40", "active", "false", "true"}
	options, err := parseReviewBundleOptions(args)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if options.IterationID != "9" || options.FileOffset != 10 || options.FileLimit != 20 || options.ThreadOffset != 30 || options.ThreadLimit != 40 {
		t.Fatalf("unexpected numeric values: %#v", options)
	}
	if options.ThreadStatusFilter != "active" {
		t.Fatalf("expected status filter active, got %q", options.ThreadStatusFilter)
	}
	if options.ExcludeSystemThreads {
		t.Fatalf("expected excludeSystemThreads=false")
	}
	if !options.IncludeLineMap {
		t.Fatalf("expected includeLineMap=true")
	}
}

func TestParseReviewBundleOptions_InvalidNumerics(t *testing.T) {
	tests := []struct {
		name    string
		args    []string
		wantErr string
	}{
		{name: "invalid fileOffset", args: []string{"org", "proj", "repo", "1", "", "-1"}, wantErr: "fileOffset must be a non-negative integer"},
		{name: "invalid fileLimit", args: []string{"org", "proj", "repo", "1", "", "0", "0"}, wantErr: "fileLimit must be a positive integer"},
		{name: "invalid threadOffset", args: []string{"org", "proj", "repo", "1", "", "0", "1", "-2"}, wantErr: "threadOffset must be a non-negative integer"},
		{name: "invalid threadLimit", args: []string{"org", "proj", "repo", "1", "", "0", "1", "0", "0"}, wantErr: "threadLimit must be a positive integer"},
	}

	for _, testCase := range tests {
		t.Run(testCase.name, func(t *testing.T) {
			_, err := parseReviewBundleOptions(testCase.args)
			if err == nil {
				t.Fatalf("expected error for %s", testCase.name)
			}
			if err.Error() != testCase.wantErr {
				t.Fatalf("expected error %q, got %q", testCase.wantErr, err.Error())
			}
		})
	}
}
