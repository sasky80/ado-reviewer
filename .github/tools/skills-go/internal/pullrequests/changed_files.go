package pullrequests

func ProjectChangedFiles(changes map[string]any, pullRequestID, iterationID string) map[string]any {
	files := make([]map[string]any, 0)
	changeEntries, _ := changes["changeEntries"].([]any)
	for _, raw := range changeEntries {
		entry, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		item, _ := entry["item"].(map[string]any)
		path := ""
		if item != nil {
			if p, ok := item["path"].(string); ok {
				path = p
			}
		}
		if path == "" {
			if p, ok := entry["originalPath"].(string); ok {
				path = p
			}
		}
		if path == "" {
			continue
		}
		isFolder := false
		if item != nil {
			if v, ok := item["isFolder"].(bool); ok {
				isFolder = v
			}
		}
		files = append(files, map[string]any{
			"path":             path,
			"changeType":       entry["changeType"],
			"changeTrackingId": entry["changeTrackingId"],
			"isFolder":         isFolder,
		})
	}

	return map[string]any{
		"pullRequestId": pullRequestID,
		"iterationId":   iterationID,
		"count":         len(files),
		"files":         files,
	}
}
