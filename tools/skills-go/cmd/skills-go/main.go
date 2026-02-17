package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"

	"ado-reviewer/tools/skills-go/internal/advisories"
	"ado-reviewer/tools/skills-go/internal/commits"
	"ado-reviewer/tools/skills-go/internal/deprecated"
	"ado-reviewer/tools/skills-go/internal/diffmapper"
	"ado-reviewer/tools/skills-go/internal/files"
	"ado-reviewer/tools/skills-go/internal/iterations"
	"ado-reviewer/tools/skills-go/internal/projects"
	"ado-reviewer/tools/skills-go/internal/pullrequests"
	"ado-reviewer/tools/skills-go/internal/repositories"
	"ado-reviewer/tools/skills-go/internal/reviews"
)

func main() {
	if len(os.Args) < 2 {
		printUsageAndExit()
	}

	command := strings.ToLower(strings.TrimSpace(os.Args[1]))
	switch command {
	case "check-deprecated-dependencies":
		handleCheckDeprecatedDependencies(os.Args[2:])
	case "list-projects":
		handleListProjects(os.Args[2:])
	case "list-repositories":
		handleListRepositories(os.Args[2:])
	case "get-pr-details":
		handleGetPRDetails(os.Args[2:])
	case "get-pr-iterations":
		handleGetPRIterations(os.Args[2:])
	case "accept-pr":
		handleSetVote(os.Args[2:], 10, "accept-pr")
	case "approve-with-suggestions":
		handleSetVote(os.Args[2:], 5, "approve-with-suggestions")
	case "wait-for-author":
		handleSetVote(os.Args[2:], -5, "wait-for-author")
	case "reject-pr":
		handleSetVote(os.Args[2:], -10, "reject-pr")
	case "reset-feedback":
		handleSetVote(os.Args[2:], 0, "reset-feedback")
	case "get-commit-diffs":
		handleGetCommitDiffs(os.Args[2:])
	case "get-file-content":
		handleGetFileContent(os.Args[2:])
	case "get-pr-changes":
		handleGetPRChanges(os.Args[2:])
	case "get-pr-changed-files":
		handleGetPRChangedFiles(os.Args[2:])
	case "get-pr-threads":
		handleGetPRThreads(os.Args[2:])
	case "post-pr-comment":
		handlePostPRComment(os.Args[2:])
	case "update-pr-thread":
		handleUpdatePRThread(os.Args[2:])
	case "get-multiple-files":
		handleGetMultipleFiles(os.Args[2:])
	case "get-github-advisories":
		handleGetGitHubAdvisories(os.Args[2:])
	case "get-pr-dependency-advisories":
		handleGetPRDependencyAdvisories(os.Args[2:])
	case "get-pr-diff-line-mapper":
		handleGetPRDiffLineMapper(os.Args[2:])
	case "get-pr-review-bundle":
		handleGetPRReviewBundle(os.Args[2:])
	default:
		fatalf("unsupported command: %s", command)
	}
}

func handleSetVote(args []string, vote int, command string) {
	if len(args) < 4 {
		fatalf("usage: skills-go %s <organization> <project> <repositoryId> <pullRequestId>", command)
	}
	result, err := reviews.SetVote(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), vote)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetCommitDiffs(args []string) {
	if len(args) < 5 {
		fatalf("usage: skills-go get-commit-diffs <organization> <project> <repositoryId> <baseVersion> <targetVersion> [baseVersionType] [targetVersionType>")
	}
	baseType := "commit"
	targetType := "commit"
	if len(args) >= 6 {
		baseType = args[5]
	}
	if len(args) >= 7 {
		targetType = args[6]
	}
	result, err := commits.GetDiffs(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), strings.TrimSpace(args[4]), strings.TrimSpace(baseType), strings.TrimSpace(targetType))
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetFileContent(args []string) {
	if len(args) < 4 {
		fatalf("usage: skills-go get-file-content <organization> <project> <repositoryId> <path> [version] [versionType]")
	}
	version := ""
	versionType := "branch"
	if len(args) >= 5 {
		version = args[4]
	}
	if len(args) >= 6 {
		versionType = args[5]
	}
	result, err := files.GetContent(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), args[3], version, versionType)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetPRChanges(args []string) {
	if len(args) < 5 {
		fatalf("usage: skills-go get-pr-changes <organization> <project> <repositoryId> <pullRequestId> <iterationId>")
	}
	result, err := pullrequests.GetChanges(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), strings.TrimSpace(args[4]))
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetPRChangedFiles(args []string) {
	if len(args) < 5 {
		fatalf("usage: skills-go get-pr-changed-files <organization> <project> <repositoryId> <pullRequestId> <iterationId>")
	}
	changes, err := pullrequests.GetChanges(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), strings.TrimSpace(args[4]))
	if err != nil {
		fatalErr(err)
	}
	result := pullrequests.ProjectChangedFiles(changes, strings.TrimSpace(args[3]), strings.TrimSpace(args[4]))
	printJSON(result)
}

func handleGetPRThreads(args []string) {
	if len(args) < 4 {
		fatalf("usage: skills-go get-pr-threads <organization> <project> <repositoryId> <pullRequestId> [statusFilter] [excludeSystem]")
	}
	statusFilter := ""
	excludeSystem := false
	if len(args) >= 5 {
		statusFilter = strings.TrimSpace(args[4])
	}
	if len(args) >= 6 {
		excludeSystem = strings.EqualFold(strings.TrimSpace(args[5]), "true")
	}
	result, err := pullrequests.GetThreads(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), statusFilter, excludeSystem)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handlePostPRComment(args []string) {
	if len(args) < 7 {
		fatalf("usage: skills-go post-pr-comment <organization> <project> <repositoryId> <pullRequestId> <filePath> <line> <comment>")
	}
	comment := strings.Join(args[6:], " ")
	result, err := pullrequests.PostComment(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), args[4], args[5], comment)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleUpdatePRThread(args []string) {
	if len(args) < 6 {
		fatalf("usage: skills-go update-pr-thread <organization> <project> <repositoryId> <pullRequestId> <threadId> [reply] [status]")
	}
	reply := args[5]
	status := ""
	if len(args) >= 7 {
		status = args[6]
	}
	result, err := pullrequests.UpdateThread(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), strings.TrimSpace(args[4]), reply, status)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetMultipleFiles(args []string) {
	if len(args) < 6 {
		fatalf("usage: skills-go get-multiple-files <organization> <project> <repositoryId> <version> <versionType> '<json_paths_array>'")
	}
	var paths []string
	if err := json.Unmarshal([]byte(args[5]), &paths); err != nil {
		fatalErr(fmt.Errorf("invalid json_paths_array: %w", err))
	}
	result, err := files.GetMultiple(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), strings.TrimSpace(args[4]), paths)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetGitHubAdvisories(args []string) {
	if len(args) < 2 {
		fatalf("usage: skills-go get-github-advisories <ecosystem> <package> [version] [severity] [per_page]")
	}
	version := ""
	severity := ""
	perPage := 30
	if len(args) >= 3 {
		version = strings.TrimSpace(args[2])
	}
	if len(args) >= 4 {
		severity = strings.TrimSpace(args[3])
	}
	if len(args) >= 5 {
		if parsed, err := strconv.Atoi(strings.TrimSpace(args[4])); err == nil {
			perPage = parsed
		}
	}
	result, err := advisories.GetGitHubAdvisories(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), version, severity, perPage)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetPRDependencyAdvisories(args []string) {
	if len(args) < 4 {
		fatalf("usage: skills-go get-pr-dependency-advisories <organization> <project> <repositoryId> <pullRequestId> [iterationId] [per_page]")
	}
	iterationID := ""
	perPage := 20
	if len(args) >= 5 {
		iterationID = strings.TrimSpace(args[4])
	}
	if len(args) >= 6 {
		if parsed, err := strconv.Atoi(strings.TrimSpace(args[5])); err == nil {
			perPage = parsed
		}
	}
	result, err := advisories.GetPRDependencyAdvisories(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), iterationID, perPage)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetPRDiffLineMapper(args []string) {
	if len(args) < 5 {
		fatalf("usage: skills-go get-pr-diff-line-mapper <organization> <project> <repositoryId> <pullRequestId> <iterationId>")
	}
	if err := diffmapper.ValidateInputs(args[0], args[1], args[2], args[3], args[4]); err != nil {
		fatalErr(err)
	}
	result, err := diffmapper.MapPRDiffLines(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]), strings.TrimSpace(args[4]))
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func handleGetPRIterations(args []string) {
	if len(args) < 4 {
		fatalf("usage: skills-go get-pr-iterations <organization> <project> <repositoryId> <pullRequestId>")
	}
	response, err := iterations.List(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]))
	if err != nil {
		fatalErr(err)
	}
	printJSON(response)
}

func handleGetPRDetails(args []string) {
	if len(args) < 4 {
		fatalf("usage: skills-go get-pr-details <organization> <project> <repositoryId> <pullRequestId>")
	}
	response, err := pullrequests.GetDetails(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]), strings.TrimSpace(args[2]), strings.TrimSpace(args[3]))
	if err != nil {
		fatalErr(err)
	}
	printJSON(response)
}

func handleListRepositories(args []string) {
	if len(args) < 2 {
		fatalf("usage: skills-go list-repositories <organization> <project>")
	}
	response, err := repositories.List(strings.TrimSpace(args[0]), strings.TrimSpace(args[1]))
	if err != nil {
		fatalErr(err)
	}
	printJSON(response)
}

func handleListProjects(args []string) {
	if len(args) < 1 {
		fatalf("usage: skills-go list-projects <organization>")
	}
	response, err := projects.List(strings.TrimSpace(args[0]))
	if err != nil {
		fatalErr(err)
	}
	printJSON(response)
}

func handleCheckDeprecatedDependencies(args []string) {
	if len(args) < 2 {
		fatalf("usage: skills-go check-deprecated-dependencies <ecosystem> <package> [version]")
	}
	ecosystem := strings.ToLower(strings.TrimSpace(args[0]))
	if ecosystem == "pypi" {
		ecosystem = "pip"
	}
	pkg := strings.TrimSpace(args[1])
	version := ""
	if len(args) >= 3 {
		version = strings.TrimSpace(args[2])
	}
	result, err := deprecated.Check(ecosystem, pkg, version)
	if err != nil {
		fatalErr(err)
	}
	printJSON(result)
}

func printJSON(value any) {
	encoded, err := json.Marshal(value)
	if err != nil {
		fatalErr(err)
	}
	fmt.Println(string(encoded))
}

func handleGetPRReviewBundle(args []string) {
	if len(args) < 4 {
		fatalf("usage: skills-go get-pr-review-bundle <organization> <project> <repositoryId> <pullRequestId> [iterationId] [fileOffset] [fileLimit] [threadOffset] [threadLimit] [statusFilter] [excludeSystem] [includeLineMap]")
	}

	options, err := parseReviewBundleOptions(args)
	if err != nil {
		fatalf(err.Error())
	}

	result, err := pullrequests.GetReviewBundle(options)
	if err != nil {
		fatalErr(err)
	}

	printJSON(result)
}

func parseReviewBundleOptions(args []string) (pullrequests.ReviewBundleOptions, error) {
	if len(args) < 4 {
		return pullrequests.ReviewBundleOptions{}, fmt.Errorf("usage: skills-go get-pr-review-bundle <organization> <project> <repositoryId> <pullRequestId> [iterationId] [fileOffset] [fileLimit] [threadOffset] [threadLimit] [statusFilter] [excludeSystem] [includeLineMap]")
	}

	iterationID := ""
	if len(args) >= 5 {
		iterationID = strings.TrimSpace(args[4])
	}

	fileOffset := 0
	if len(args) >= 6 {
		parsed, err := strconv.Atoi(strings.TrimSpace(args[5]))
		if err != nil || parsed < 0 {
			return pullrequests.ReviewBundleOptions{}, fmt.Errorf("fileOffset must be a non-negative integer")
		}
		fileOffset = parsed
	}

	fileLimit := 100
	if len(args) >= 7 {
		parsed, err := strconv.Atoi(strings.TrimSpace(args[6]))
		if err != nil || parsed <= 0 {
			return pullrequests.ReviewBundleOptions{}, fmt.Errorf("fileLimit must be a positive integer")
		}
		fileLimit = parsed
	}

	threadOffset := 0
	if len(args) >= 8 {
		parsed, err := strconv.Atoi(strings.TrimSpace(args[7]))
		if err != nil || parsed < 0 {
			return pullrequests.ReviewBundleOptions{}, fmt.Errorf("threadOffset must be a non-negative integer")
		}
		threadOffset = parsed
	}

	threadLimit := 100
	if len(args) >= 9 {
		parsed, err := strconv.Atoi(strings.TrimSpace(args[8]))
		if err != nil || parsed <= 0 {
			return pullrequests.ReviewBundleOptions{}, fmt.Errorf("threadLimit must be a positive integer")
		}
		threadLimit = parsed
	}

	statusFilter := ""
	if len(args) >= 10 {
		statusFilter = strings.TrimSpace(args[9])
	}

	excludeSystem := true
	if len(args) >= 11 {
		excludeSystem = strings.EqualFold(strings.TrimSpace(args[10]), "true")
	}

	includeLineMap := false
	if len(args) >= 12 {
		includeLineMap = strings.EqualFold(strings.TrimSpace(args[11]), "true")
	}

	return pullrequests.ReviewBundleOptions{
		Organization:         strings.TrimSpace(args[0]),
		Project:              strings.TrimSpace(args[1]),
		RepositoryID:         strings.TrimSpace(args[2]),
		PullRequestID:        strings.TrimSpace(args[3]),
		IterationID:          iterationID,
		FileOffset:           fileOffset,
		FileLimit:            fileLimit,
		ThreadOffset:         threadOffset,
		ThreadLimit:          threadLimit,
		ThreadStatusFilter:   statusFilter,
		ExcludeSystemThreads: excludeSystem,
		IncludeLineMap:       includeLineMap,
	}, nil
}

func printUsageAndExit() {
	fatalf("usage: skills-go <command> [args]\ncommands:\n  check-deprecated-dependencies <ecosystem> <package> [version]\n  list-projects <organization>\n  list-repositories <organization> <project>\n  get-pr-details <organization> <project> <repositoryId> <pullRequestId>\n  get-pr-iterations <organization> <project> <repositoryId> <pullRequestId>\n  get-pr-changes <organization> <project> <repositoryId> <pullRequestId> <iterationId>\n  get-pr-changed-files <organization> <project> <repositoryId> <pullRequestId> <iterationId>\n  get-pr-review-bundle <organization> <project> <repositoryId> <pullRequestId> [iterationId] [fileOffset] [fileLimit] [threadOffset] [threadLimit] [statusFilter] [excludeSystem] [includeLineMap]\n  get-pr-threads <organization> <project> <repositoryId> <pullRequestId> [statusFilter] [excludeSystem]\n  post-pr-comment <organization> <project> <repositoryId> <pullRequestId> <filePath> <line> <comment>\n  update-pr-thread <organization> <project> <repositoryId> <pullRequestId> <threadId> [reply] [status]\n  get-file-content <organization> <project> <repositoryId> <path> [version] [versionType]\n  get-multiple-files <organization> <project> <repositoryId> <version> <versionType> '<json_paths_array>'\n  get-commit-diffs <organization> <project> <repositoryId> <baseVersion> <targetVersion> [baseVersionType] [targetVersionType]\n  get-github-advisories <ecosystem> <package> [version] [severity] [per_page]\n  get-pr-dependency-advisories <organization> <project> <repositoryId> <pullRequestId> [iterationId] [per_page]\n  get-pr-diff-line-mapper <organization> <project> <repositoryId> <pullRequestId> <iterationId>\n  accept-pr <organization> <project> <repositoryId> <pullRequestId>\n  approve-with-suggestions <organization> <project> <repositoryId> <pullRequestId>\n  wait-for-author <organization> <project> <repositoryId> <pullRequestId>\n  reject-pr <organization> <project> <repositoryId> <pullRequestId>\n  reset-feedback <organization> <project> <repositoryId> <pullRequestId>")
}

func fatalErr(err error) {
	var usageErr *deprecated.UsageError
	if errors.As(err, &usageErr) {
		fmt.Fprintln(os.Stderr, usageErr.Error())
		os.Exit(2)
	}
	fmt.Fprintln(os.Stderr, err.Error())
	os.Exit(1)
}

func fatalf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(2)
}
