# calculate-windows Walkthrough

## Summary

`calculate-windows` is a local MCP server launched by the workspace's `.vscode/mcp.json`. It runs `.vscode/mcp-calculate.ps1` in PowerShell and provides basic arithmetic through the `calculate` tool.

The tool requires an `operation`, `a`, and `b`. Supported operations are `add`, `subtract`, `multiply`, and `divide`. For example:

```json
{"operation":"multiply","a":6,"b":7}
```

The result is returned as text. Division by zero and unsupported operations produce tool errors.

## Quiz

1. Which four operations are supported?
2. What inputs are required by `calculate`?
3. What happens when `b` is zero and the operation is `divide`?

<details>
<summary>Answers</summary>

1. `add`, `subtract`, `multiply`, and `divide`.
2. `operation`, `a`, and `b`.
3. The tool returns an error instead of a numeric result.

</details>
