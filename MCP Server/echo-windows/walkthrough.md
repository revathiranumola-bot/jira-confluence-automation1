# echo-windows Walkthrough

## Summary

`echo-windows` is a local MCP server launched by the workspace's `.vscode/mcp.json`. It runs `.vscode/mcp-echo.ps1` in PowerShell and exposes the `echo` tool, which returns the supplied message unchanged.

To try it, call `echo` with a `message` string, for example:

```json
{"message":"Hello from MCP"}
```

The tool responds with the same text. This server is useful for checking that the MCP connection and tool-call flow are working.

## Quiz

1. What is the name of the tool exposed by this server?
2. Which required input does the tool accept?
3. What does the tool return?

<details>
<summary>Answers</summary>

1. `echo`
2. A `message` string.
3. The same message string.

</details>
