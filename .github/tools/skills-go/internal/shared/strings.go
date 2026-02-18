package shared

import "strings"

func TrimmedString(value any) string {
	str, _ := value.(string)
	return strings.TrimSpace(str)
}
