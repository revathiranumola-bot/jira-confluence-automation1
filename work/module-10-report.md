# Module 10 Completion Report

## Instruction Files
```
    Directory: C:\Users\RevathiAnumola\Desktop\Workspace1\hello-genai\instructions


Mode          LastWriteTime Length Name                          
----          ------------- ------ ----                          
-a---- 16-10-2026     12:57   1304 create-status-report.agent.md 
-a---- 16-10-2026     13:05  16576 creating-instructions.agent.md
-a---- 16-10-2026     13:30   2534 main.agent.md                 
-a---- 16-10-2026     13:30   3066 publish-roster.agent.md       
-a---- 16-10-2026     13:30   1125 validate-roster.agent.md      
-a---- 16-10-2026     13:30   1315 verify-publish-result.agent.md
```

## main.agent.md Contents
```markdown
# Instructions Catalog

Each entry below is an instruction file with a one-line description. Optional sub-fields after `+`:
- **Keywords** — trigger words/phrases: if user's request matches, load this instruction.
- **Target** — file glob pattern: if current file or context matches, consider this instruction relevant.
- **Exceptions** — edge cases or clarifications that don't fit in the one-liner.

---

- [`./instructions/creating-instructions.agent.md`](./creating-instructions.agent.md) — how to create, update, and register instructions, skills, and IDE wrappers.
  + Keywords: create instruction, update instruction, new instruction, add skill, shortcut, prompt wrapper, instruction catalog
  + Target: `instructions/**`, `.github/prompts/*.prompt.md`, `.github/copilot-instructions.md`
- [`./instructions/create-status-report.agent.md`](./create-status-report.agent.md) — generate a concise weekly status report in Markdown.
  + Keywords: status report, weekly report, weekly status, team update, accomplishments, blockers
  + Target: `reports/weekly-status-*.md`
  + Exceptions: full-template reports in `reports/template.md` follow `reports/instructions.md` instead.

- [`./instructions/publish-roster.agent.md`](./publish-roster.agent.md) — publish an approved draft on-call roster to ServiceNow: input, processing steps, output, constraints.
  + Keywords: publish, publish roster, ServiceNow, on-call roster, CPS roster, draft to published
  + Target: `roster/servicenow/**`, `roster/api/**`, `backlog.md`
  + Exceptions: updating or overwriting an already-published roster is out of scope (needs a separate update workflow).
- [`./instructions/validate-roster.agent.md`](./validate-roster.agent.md) — validate a draft on-call roster (coverage, overlaps, 12h rest, eligibility, fairness).
  + Keywords: validate roster, validation, coverage gaps, rest violation, fairness totals
  + Target: `roster/core/**`
  + Exceptions: called by `publish-roster.agent.md` before every publish.
- [`./instructions/verify-publish-result.agent.md`](./verify-publish-result.agent.md) — verify a ServiceNow publish by read-back and record success or failure.
  + Keywords: verify publish, read back, publish result, partial failure, audit
  + Target: `roster/servicenow/**`
  + Exceptions: called by `publish-roster.agent.md` after the publisher call.

---

## Global Rules

- After executing any prompt, end your response with this exact line:

The AI Agent has referred to main file
```

## Sample Instruction
- File: publish-roster.agent.md
- Contents:
```markdown
- **Purpose:** publish an approved draft CPS on-call roster as a new roster in ServiceNow. Source: `project_spec.md` §4.3, §7, §8; `backlog.md` §3.1–3.2.

- **Input format:**
  + Roster ID of a roster in `draft` state (`POST /rosters/{id}/publish`).
  + Roster payload: period (start/end dates), time-zone ID (e.g. `America/Chicago`), config snapshot, seed, assignments.
  + Assignment: `date`, `shift` (`day` 09:00–21:00 / `night` 21:00–09:00 next day), `start` and `end` instants with time-zone ID, `primary` member ID.
  + Publishing user identity (scrum master) from the authenticated session.
  + Member ID → ServiceNow user/resource ID mapping.
  + Credentials from env/secret store only, never from the request.
  + Example: `{"roster_id": "r-2026-11", "user": "scrum.master", "confirm": true}`.

- **Processing steps:**
  + Load the roster; reject if state is not `draft`.
  + Check required settings are confirmed: time zone, holiday calendar, ServiceNow target (D1, D6).
  + Validate by following `./instructions/validate-roster.agent.md`; stop on any hard failure and return its `hard_failures`.
  + Map every member ID to a ServiceNow ID; fail on unmapped members.
  + Check no ServiceNow roster with the same identity exists; refuse if it does.
  + Call `RosterPublisher.publish` (mock publisher in dev/tests): create the roster record, then one record per assignment.
    + Use timeouts, bounded retries for transient errors, and an idempotency key.
  + Verify and record the result by following `./instructions/verify-publish-result.agent.md`.

- **Output format:**
  + Success: `{"status": "published", "roster_id": "...", "servicenow_id": "...", "servicenow_link": "...", "published_by": "...", "published_at": "<ISO-8601 with offset>", "records": 84}`.
  + Failure: `{"status": "failed", "roster_state": "draft", "error_category": "validation|auth|permission|network|unknown", "message": "...", "details": [...]}`.
  + Validation failure `details`: affected shifts and members.
  + Show a plain success or failure message to the scrum master.
  + Dates use ISO-8601; the time-zone ID is always included.

- **Constraints:**
  + Create a **new** roster only; never overwrite an existing ServiceNow roster.
  + Only a `draft` roster can be published; a published roster cannot be edited or republished.
  + Valid transition: `draft` → `published` only after validation passes.
  + A failed publish keeps the roster as `draft`.
  + Never show a misleading success state.
  + No notifications, reminders, or change alerts anywhere in the flow.
  + Only authorized users (scrum master role mapped to ServiceNow ACLs, D7) may publish.
  + Use the approved ServiceNow auth method with a least-privilege integration account.
  + No secrets in source, logs, error responses, or audit records.
  + Keep scheduling logic free of ServiceNow dependencies; ServiceNow calls live only behind `RosterPublisher`.
  + Versioning and correction of published rosters follow D8; if undecided, treat as unsupported.
```
