# CPS On-Call Roster Frontend

React 18.3.1 and Vite 8.3.4 prototype UI. Roster setup accepts explicit start
and end dates, a named time zone, and unique local demo member IDs (one per
line). "Preview setup" validates these inputs and displays a setup summary
on the generation-result route. "Edit setup" retains the inputs.
This is an in-memory preview only: reloading clears the inputs and summary.
It does not generate or persist a roster, verify team eligibility, or check
scheduling constraints. Other workflow screens remain presentation shells;
no roster records or team identities are fabricated.
Publishing is labelled as simulated and does not call ServiceNow.

## Requirements

- Node.js 24.22.0
- npm 11.19.1

## Run locally

From a PowerShell terminal, select the pinned Node version, then start Vite:

```powershell
nvm use 24.22.0
npm.cmd ci
npm.cmd run dev
```

Vite binds to `127.0.0.1` and prints the local URL (by default,
`http://127.0.0.1:5173/`). `VITE_API_BASE_URL` may be set for future API
integration; no credentials belong in frontend environment variables.

## Checks

```powershell
npm.cmd test
npm.cmd run lint
npm.cmd run build
```

## Chrome DevTools MCP

The workspace [MCP configuration](../.vscode/mcp.json) invokes the
[Windows launcher](../.vscode/start-chrome-devtools-mcp.ps1). The launcher lets
the MCP server start installed Google Chrome over a debugging pipe, rather
than connecting to port 9222. PWA tools require this pipe connection.
Chrome uses a separate `%LOCALAPPDATA%\ChromeDevToolsMcp\all-tools-profile`;
your regular profile and the earlier port-9222 profile are not reused.
Chrome starts on the first tool call that needs a browser.

All documented tool categories are enabled, including extensions, memory,
experimental third-party/WebMCP, and PWA tools. Optional memory-debugging,
DevTools UI, and coordinate-based vision capabilities are enabled too.
WebMCP requires Chrome 150+ and the launcher supplies its feature flag.
Deprecated ffmpeg-based recording is not enabled; the default recorder is used.
Page-provided WebMCP tools depend on what the inspected application exposes;
enabling a category does not create tools absent from that application.

Use this profile only for trusted local testing. Third-party tool discovery
exposes tools supplied by inspected pages, and DevTools UI tools can execute
JavaScript in those pages. File-tool access is scoped to this repository.
Usage statistics and CrUX URL sharing are disabled.

After changing the launcher, restart `chrome-devtools` through **MCP: List
Servers** in VS Code, approve the trust prompt, and enable its tools in the
chat tool picker. Server configuration alone does not expose tools in an
already-running chat. Tool availability follows the installed
`chrome-devtools-mcp@latest` package; see the
[upstream configuration reference](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/configuration.md).

### Testing tools already enabled

The configured server advertised the following QA tools during the MCP
`initialize` / `tools/list` verification (server version 1.11.0). No separate
testing category or additional server is needed.

The requested browser-testing capabilities are included:

| Capability | Tools / behavior |
|---|---|
| Open URLs | `new_page`, `navigate_page` navigate to application pages |
| Inspect elements | `take_snapshot` reads page text and identifies controls; `get_css_styles` checks styles; `evaluate_script` inspects DOM details |
| Click elements | `click`, `click_at` activate buttons, follow links, and open menus |
| Fill in forms | `fill`, `fill_form` populate inputs and select native drop-down options; `type_text` types text; custom drop-downs may require `click` and `press_key` |
| Take screenshots | `take_screenshot` captures the current rendered page |
| Read console logs | `list_console_messages`, `get_console_message` inspect logs, warnings, and JavaScript errors |
| Evaluate JavaScript | `evaluate_script` runs diagnostic scripts in the page context; the launcher explicitly sets `--javascriptEvaluation=true` |

| Testing task | Tools |
|---|---|
| Navigate and manage test pages | `new_page`, `navigate_page`, `list_pages`, `select_page`, `close_page` |
| Exercise forms and user flows | `fill`, `fill_form`, `type_text`, `click`, `click_at`, `press_key`, `hover`, `drag`, `upload_file`, `handle_dialog`, `wait_for` |
| Inspect rendered output and capture evidence | `take_snapshot`, `take_screenshot`, `get_css_styles`, `evaluate_script`, `screencast_start`, `screencast_stop` |
| Check console errors and warnings | `list_console_messages`, `get_console_message` |
| Check failed requests and API responses | `list_network_requests`, `get_network_request` |
| Test viewport and emulated conditions | `resize_page`, `emulate` |
| Audit page quality and investigate performance | `lighthouse_audit`, `performance_start_trace`, `performance_stop_trace`, `performance_analyze_insight` |
| Investigate memory | `take_heapsnapshot`, `get_heapsnapshot_summary`, `compare_heapsnapshots`, `get_heapsnapshot_retainers` |
| Discover and execute page-provided testable actions | `list_webmcp_tools`, `execute_webmcp_tool`, `list_3p_developer_tools`, `execute_3p_developer_tool` |

For this application's smoke test, open the overview, use Configure roster,
check empty-field errors, fill local demo inputs, submit Preview setup, and
compare the summary with those inputs. Inspect console and network messages
and save a screenshot. Keep assertions explicit: tool execution alone is not
a passing test. Chrome DevTools MCP does not run the repository's Vitest suite;
use the npm checks above for repeatable automated regression tests.

These tools were verified as advertised, not all executed. Restart the MCP
server and enable its tools in the chat before requesting MCP-based testing.
