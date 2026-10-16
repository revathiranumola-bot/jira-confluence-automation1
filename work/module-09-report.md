# Module 09 Completion Report

## Tracked Files
TODO.md
backlog.md
project_spec.md
reports/example.md
reports/instructions.md
reports/template.md
work/jira-dashboard/README.md
work/jira-dashboard/index.html
work/jira-dashboard/requirements.md
work/module-03-report.md
work/module-08-report.md
work/module03-task
work/status-report-template.md

## Backlog Commit History
179864e Add CPS on-call roster implementation backlog

## backlog.md Contents
# CPS On-Call Roster — Implementation Backlog

Source: [project_spec.md](./project_spec.md)

**Stack:** Python + FastAPI web app (with a simple web UI). Scheduling core is a pure Python package, independent of the ServiceNow adapter.
**Phasing:** ServiceNow integration spike happens early to de-risk; the real adapter is built after the core, behind an interface.
**Scope:** All MVP items are in scope: draft generation, fairness summary, edit + revalidation, draft/published states, ServiceNow publish, audit metadata, holiday-aware fairness.
**Out of scope:** notifications/reminders, secondary/backup assignment, overwriting existing ServiceNow rosters.

---

## Decisions Gate (blocking / configurable defaults)

Each decision is a configuration input. Defaults are used for development only and must be confirmed before production use. The system must flag any default that is still unconfirmed (acceptance criterion 10).

- [ ] **D1 Time zone:** Confirm `CST` means `America/Chicago` (DST-aware) vs fixed UTC−6. *Default:* `America/Chicago`. Blocks production generate/publish.
- [ ] **D2 Team identities:** Obtain five member names/identifiers and confirm all are eligible for day and night shifts. *Default:* placeholder members `member-1..member-5`.
- [ ] **D3 Availability:** Decide leave = hard block / warning / ignored; decide whether preferences are supported. *Default:* leave ignored, no preferences.
- [ ] **D4 Max consecutive shifts:** Decide whether a cap is needed. *Default:* no cap (configurable, off).
- [ ] **D5 Weekend/holiday definitions:** Confirm weekend days and holiday calendar/region. *Default:* Sat/Sun, US federal holidays.
- [ ] **D6 ServiceNow target:** Confirm instance, application/module, data model, API, and auth method. Blocks real publish.
- [ ] **D7 ServiceNow roles:** Map the scrum master's create/edit/review/publish responsibility to ServiceNow roles/ACLs.
- [ ] **D8 Publishing policy:** Decide whether publishing creates versioned rosters and how corrections to published rosters are handled.
- [ ] Confirm the roster start (Nov 1, 2026) and end (Dec 12, 2026, inclusive) under the confirmed time zone.

---

## Phase 1: Setup

### 1.1 Project scaffolding
- [ ] Create repo layout: `roster/core/` (pure scheduling logic), `roster/servicenow/` (adapter), `roster/api/` (FastAPI), `roster/web/` (UI), `tests/`, `docs/`
- [ ] Choose Python version and set up `pyproject.toml` with dependency management
- [ ] Add dependencies: FastAPI, Uvicorn, Pydantic, `tzdata`, a holiday library (e.g. `holidays`), pytest, httpx
- [ ] Add linting/formatting/type-checking (ruff, mypy) and a pre-commit config
- [ ] Add a CI workflow to run lint, type-check, and tests
- [ ] Add `.gitignore` and `.env.example`; ensure no secrets are committed

### 1.2 Configuration and settings
- [ ] Define a settings model: time zone, roster start date, number of weeks (6), shift definitions, rest hours (12), max consecutive shifts (optional), weekend days, holiday calendar/region, fairness priority order
- [ ] Load settings from a config file and environment variables; keep credentials in environment variables or a secret store only
- [ ] Track which settings are confirmed vs defaulted, and expose that status through the API
- [ ] Fail with a clear error when a required setting is missing (time zone, holiday calendar)
- [ ] Ensure logging redacts credentials and tokens

### 1.3 Domain model
- [ ] Define `TeamMember` (stable ID, display name, eligibility flag)
- [ ] Define `ShiftType` (day, night) and `Shift` (date, type, start/end as tz-aware instants, tz identifier)
- [ ] Define `Assignment` (roster ID, shift, primary member ID, created/updated timestamps and actor)
- [ ] Define `Roster` (ID, state: draft/published, period, config snapshot, seed, assignments, audit metadata)
- [ ] Define `ValidationIssue` (severity, rule, shift/member references, message)

### 1.4 ServiceNow integration spike (de-risk early)
- [ ] Get access to a ServiceNow dev/test instance (blocked by D6)
- [ ] Investigate candidate data models/APIs for on-call schedules (e.g. Table API on rota/shift tables, on-call scheduling modules) and record findings
- [ ] Prototype authentication (OAuth or approved method) and confirm credentials are read from env/secret store only
- [ ] Prototype creating a single new roster with one shift assignment, including start/end and time-zone context
- [ ] Verify how DST and time-zone context are stored and returned
- [ ] Verify the ServiceNow API error responses for auth failure, permission denied, validation error, and network failure
- [ ] Verify whether a duplicate/existing roster can be detected (needed to avoid overwriting)
- [ ] Write spike results (chosen API, data mapping, limits, open risks) in `docs/servicenow-spike.md` and update D6/D7/D8

### 1.5 Persistence
- [ ] Choose local storage for draft/published rosters (e.g. SQLite via SQLAlchemy)
- [ ] Create the schema for rosters, assignments, config snapshots, and audit events
- [ ] Add migrations and a local dev seed script

---

## Phase 2: Core Features

### 2.1 Time and calendar utilities
- [ ] Build the shift calendar: for each of the 42 days, generate day (09:00–21:00) and night (21:00–09:00 next day) shifts as tz-aware instants
- [ ] Handle DST correctly (Nov 1, 2026 is the US DST end date; the overnight shift on Nov 1 is 13 hours long under `America/Chicago`)
- [ ] Compute shift duration from actual instants, not a fixed 12 hours
- [ ] Classify each shift as weekend/holiday using the configured weekend days and holiday calendar (define how a night shift crossing midnight is classified, and document it)
- [ ] Verify the generated calendar has 84 shifts with no gaps or overlaps

### 2.2 Validation engine (pure functions)
- [ ] Rule: every shift has exactly one primary
- [ ] Rule: continuous coverage with no gaps or overlaps across day/night intervals
- [ ] Rule: no person has overlapping shifts
- [ ] Rule: at least 12 hours between the end of a person's shift and the start of their next one (instant-based)
- [ ] Rule: all assignees are eligible members of the configured team
- [ ] Rule: required settings (time zone, holiday calendar) are present
- [ ] Rule (optional, configurable): maximum consecutive shifts
- [ ] Rule (configurable per D3): availability/leave as block, warning, or ignored
- [ ] Return structured issues identifying the shifts and members involved
- [ ] Classify rules as hard (block publish) vs. informational (fairness imbalance)

### 2.3 Fairness calculation
- [ ] Compute per-member totals: assigned hours, total shifts, night shifts, weekend/holiday shifts
- [ ] Compute imbalance metrics (max − min) for each of the three priorities
- [ ] Implement lexicographic comparison in priority order: hours, then nights, then weekend/holiday
- [ ] Flag unavoidable imbalance visibly in the summary

### 2.4 Draft generator
- [ ] Implement a scheduling algorithm that fills all 84 shifts under hard constraints (rest ≥ 12h, no overlap, eligibility)
- [ ] Choose the approach (greedy with lookahead/backtracking, or a constraint solver such as OR-Tools CP-SAT) and record the decision
- [ ] Optimize fairness in the specified priority order
- [ ] Make output deterministic for the same inputs, or accept and record a seed with all tie-breaking driven by it
- [ ] Never emit a silently invalid schedule: report unfilled shifts and unsatisfied hard constraints with the shifts/members involved
- [ ] Mark a generation result as `incomplete` or `failed` when hard constraints cannot be met
- [ ] Store the config snapshot and seed with the draft

### 2.5 Roster lifecycle and API
- [ ] Implement draft/published states and enforce valid transitions (draft → published only after validation passes)
- [ ] `POST /rosters/draft` — generate a draft from the current config
- [ ] `GET /rosters/{id}` — assignments in date order, with day and night shifts separate
- [ ] `GET /rosters/{id}/summary` — per-member fairness totals
- [ ] `PATCH /rosters/{id}/assignments/{shift}` — change a shift's primary
- [ ] `POST /rosters/{id}/validate` — run full validation and return issues
- [ ] Revalidate automatically after each edit; never discard or override an edit that violates a hard rule — keep it and show the issue
- [ ] Prevent edits to a published roster
- [ ] Record audit events for generate, edit, validate, and publish (who, when, what changed)
- [ ] Add scrum master authentication/authorization for the app (aligned with D7)

### 2.6 Review and edit UI
- [ ] Config page: team members, start date, time zone, and other settings, with unconfirmed defaults highlighted
- [ ] Roster view: assignments in date order, with separate day and night rows
- [ ] Clear visual distinction of draft vs. published state
- [ ] Fairness panel: per-member hours, shifts, nights, weekend/holiday shifts
- [ ] Validation panel: coverage gaps, rest violations, overlaps, with links to the affected shifts
- [ ] Inline edit of a shift's primary (dropdown of eligible members) with immediate revalidation
- [ ] Disable the publish button while hard validation failures exist; show the reason
- [ ] Show weekend/holiday markers and DST-affected shifts

---

## Phase 3: Integration

### 3.1 ServiceNow adapter
- [ ] Define a `RosterPublisher` interface in the core (publish, get status) so scheduling logic has no ServiceNow dependency
- [ ] Implement a mock/in-memory publisher for dev and tests
- [ ] Implement the real ServiceNow client based on spike findings (D6)
- [ ] Authenticate with the approved method; read credentials from env/secret store; never log them
- [ ] Map the domain roster to the ServiceNow data model: roster record plus one record per assignment with start/end, primary resource, and time-zone context
- [ ] Map internal member IDs to ServiceNow user/resource identifiers; fail on unmapped members
- [ ] Create a **new** CPS roster; refuse and report if a roster with the same identity already exists (no overwrite)
- [ ] Add timeouts, bounded retries for transient failures, and idempotency protection against duplicate creation
- [ ] Handle partial-failure publishing (e.g. roster created but some assignments failed): roll back or clearly mark the result as failed; never show success
- [ ] Verify post-publish by reading back and comparing record counts (84) and key fields

### 3.2 Publish workflow
- [ ] `POST /rosters/{id}/publish` — re-run full validation, then call the publisher
- [ ] Block publish on any hard validation failure, incomplete coverage, or unconfirmed required settings
- [ ] On success: mark the roster published, store the ServiceNow roster ID/link, and record the publishing user and timestamp
- [ ] On failure: keep the roster as draft, surface the error category (auth, permission, validation, network, unknown) and message to the scrum master
- [ ] Ensure no notifications are triggered anywhere in the flow
- [ ] UI: publish confirmation dialog summarizing fairness and validation status, plus a success/failure result screen
- [ ] Implement the versioning/correction behavior decided in D8 (or document it as deferred)

### 3.3 Security and access
- [ ] Map the scrum master role to ServiceNow roles/ACLs (D7) and verify the integration account has least-privilege access
- [ ] Verify no secrets in source, logs, error responses, or audit records
- [ ] Add dependency vulnerability scanning to CI

---

## Phase 4: Testing

### 4.1 Unit tests — core
- [ ] Shift calendar: 84 shifts, correct start/end instants, no gaps/overlaps
- [ ] DST: the Nov 1, 2026 fall-back day produces correct durations and rest calculations under `America/Chicago`; compare against fixed UTC−6 behavior
- [ ] Weekend/holiday classification, including Thanksgiving (Nov 26, 2026) and night shifts that span midnight
- [ ] Each validation rule: passing case and failing case, including the exact 12-hour boundary and 11h59m
- [ ] Fairness metrics and priority-order comparison
- [ ] Generator: fills all 84 shifts, meets hard constraints, balanced hours/nights/weekend-holiday within the best achievable bounds
- [ ] Generator determinism: same input and seed produce identical output
- [ ] Generator infeasibility: reports unfilled shifts/violations rather than a silent invalid result (e.g. only one eligible member, or too few members to satisfy rest)
- [ ] Settings: missing required settings produce errors; unconfirmed defaults are flagged

### 4.2 API and lifecycle tests
- [ ] Draft generation endpoint and response shape
- [ ] Edit that violates rest/overlap is kept, flagged, and blocks publish
- [ ] Edit revalidates and updates fairness summary
- [ ] Published roster cannot be edited
- [ ] Invalid state transitions are rejected
- [ ] Authorization: unauthorized users cannot edit or publish
- [ ] Audit events are recorded for each action

### 4.3 ServiceNow adapter tests
- [ ] Contract tests against the mock publisher
- [ ] HTTP-level tests with recorded/stubbed responses: success, 401, 403, 4xx validation error, 5xx, timeout
- [ ] Partial-failure and duplicate-roster scenarios never report success
- [ ] Credentials never appear in logs or error output
- [ ] End-to-end publish against a ServiceNow test instance (manual or gated CI job)

### 4.4 UI and end-to-end tests
- [ ] E2E: configure → generate draft → review fairness → edit → fix violation → publish (mock publisher)
- [ ] UI shows draft/published state, validation issues, and fairness totals correctly
- [ ] Publish button disabled when hard failures exist

### 4.5 Acceptance verification (spec section 10)
- [ ] AC1: draft generated for Nov 1–Dec 12, 2026 after the time-zone confirmation
- [ ] AC2: exactly 84 assignments (one day and one night primary per day)
- [ ] AC3: continuous, non-overlapping coverage across all weekends and holidays
- [ ] AC4: no rest gaps under 12 hours
- [ ] AC5: fairness summary exposes hours, nights, weekend/holiday shifts in priority order
- [ ] AC6: review, edit, and revalidation work
- [ ] AC7: invalid or incomplete roster cannot be published
- [ ] AC8: publish to a new ServiceNow CPS roster with clear success/failure
- [ ] AC9: no notifications are sent
- [ ] AC10: unresolved configuration requirements are identified, not guessed
- [ ] Run a dry-run with the real team and the confirmed configuration and get scrum master sign-off

---

## Phase 5: Documentation

- [ ] README: purpose, architecture (core vs. adapter), setup, and run instructions
- [ ] Configuration reference: every setting, its default, and whether it is confirmed
- [ ] Scheduling rules reference: shift times, DST handling, rest rule, fairness priority order, weekend/holiday classification
- [ ] Scrum master user guide: generate, review, edit, interpret validation messages, publish
- [ ] ServiceNow integration guide: required roles, auth setup, data mapping, error codes and remedies (from the spike)
- [ ] Decision log recording the resolution of D1–D8
- [ ] Runbook: troubleshooting failed publishes, regenerating with the same seed, and handling post-publish corrections
- [ ] Security notes: credential handling, log redaction, least privilege
- [ ] Known limitations and future work (availability/leave policy, notifications, secondary on-call, update workflow for published rosters)
