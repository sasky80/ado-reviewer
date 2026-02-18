package testutil

import (
	"os"
	"regexp"
	"testing"
)

var invalidPATChars = regexp.MustCompile(`[^A-Za-z0-9_]`)

func RequireADOContext(t *testing.T) (org, project, repositoryID, pullRequestID string) {
	t.Helper()

	org = StringOrDefault(os.Getenv("ADO_IT_ORG"), "")
	project = StringOrDefault(os.Getenv("ADO_IT_PROJECT"), "")
	repositoryID = StringOrDefault(os.Getenv("ADO_IT_REPO"), "")
	pullRequestID = StringOrDefault(os.Getenv("ADO_IT_PR"), "")
	if org == "" || project == "" || repositoryID == "" || pullRequestID == "" {
		t.Skip("set ADO_IT_ORG, ADO_IT_PROJECT, ADO_IT_REPO, and ADO_IT_PR to run live integration tests")
	}

	patVar := "ADO_PAT_" + NormalizePATVarSuffix(org)
	if StringOrDefault(os.Getenv(patVar), "") == "" {
		t.Skipf("set %s to run live integration tests", patVar)
	}

	return org, project, repositoryID, pullRequestID
}

func NormalizePATVarSuffix(organization string) string {
	suffix := invalidPATChars.ReplaceAllString(organization, "_")
	if suffix != "" && suffix[0] >= '0' && suffix[0] <= '9' {
		suffix = "_" + suffix
	}
	return suffix
}

func StringOrDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
