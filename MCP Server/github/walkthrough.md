# github Walkthrough

## Summary

The `github` server in the workspace's `.vscode/mcp.json` connects to GitHub's hosted MCP endpoint at `https://api.githubcopilot.com/mcp/` over HTTP. It provides GitHub tools to interact with repositories, issues, pull requests, and other GitHub resources. The exact available tools depend on the GitHub MCP service and the authenticated account.

Use the GitHub tools for the requested operation and provide the repository owner/name and any required issue or pull request details. Prefer read operations when inspecting information; confirm the target and intended changes before requesting write operations.

## Quiz

1. Is this server launched as a local PowerShell script or connected over HTTP?
2. Where does the server connect?
3. What repository details are commonly needed when using a repository or issue tool?

<details>
<summary>Answers</summary>

1. It is connected over HTTP.
2. `https://api.githubcopilot.com/mcp/`
3. The repository owner and repository name; issue or pull request operations also need the corresponding number.

</details>
