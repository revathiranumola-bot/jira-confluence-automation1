# get-time-windows Walkthrough

## Summary

`get-time-windows` is a local MCP server launched by the workspace's `.vscode/mcp.json`. It runs `.vscode/mcp-get-time.ps1` in PowerShell and provides the `get_time` tool.

Call `get_time` without arguments to receive the current local date and time. To request a specific time zone, supply its Windows time zone ID, for example:

```json
{"timezone":"India Standard Time"}
```

The result is formatted as `yyyy-MM-dd HH:mm:ss zzz`. An invalid time zone ID is reported as a tool error.

## Quiz

1. What is the tool name?
2. What does the server use when no time zone is supplied?
3. Which time zone ID format should be supplied?

<details>
<summary>Answers</summary>

1. `get_time`
2. The machine's local time.
3. A Windows time zone ID, such as `India Standard Time`.

</details>
