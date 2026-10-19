# github-write-windows Walkthrough

## Summary

`github-write-windows` is a local MCP server launched by the workspace's `.vscode/mcp.json`. It runs `.vscode/github.ps1` in PowerShell and uses the GitHub REST API for repository and issue operations.

The server exposes these tools:

- `get_repo` — retrieve basic repository information.
- `create_issue` — create an issue, optionally with a body and existing labels.
- `update_issue` — update an issue's title, body, or open/closed state.
- `add_issue_labels` and `remove_issue_labels` — modify issue labels.
- `create_label` — create a repository label.
- `add_issue_comment` — add a comment to an issue.

The server requires the `githubToken` input configured in `.vscode/mcp.json`. Provide a token with the permissions needed for the requested operation. Before making changes, verify the owner, repository, issue number, and requested update.

## Quiz

1. Which configuration input supplies the token?
2. Name two tools that can change GitHub data.
3. What information should be verified before updating an issue?

<details>
<summary>Answers</summary>

1. `githubToken`.
2. For example, `create_issue` and `update_issue` (also label and comment tools).
3. The repository owner and name, issue number, and intended change.

</details>
