# Specification Implementation Checklist

**Checked:** 2026-10-19

**Baseline commit:** `a0fdb26`

**Source:** [specification.md](./specification.md)

**Approved prototype boundaries:** [decisions.md](./decisions.md)

## Overall result

**The roster application is not functionally implemented.** The React
navigation/empty-state shell, Express root endpoint, and local PostgreSQL
service work independently. There is no end-to-end roster workflow, no
application database schema, and no implemented `/api/v1` route.

Older standalone Python scheduling/publishing code exists, but is not called
by the React/Express application. Its presence is reported separately rather
than credited as an implemented application feature. The Python checks could
not pass in the current environment.

This review changes no application code, installs no dependencies, writes no
roster data, and performs no live ServiceNow operation. It does not mark
requirements passed merely because the corresponding operation is absent.

## Status and evidence conventions

- **No / Not working:** Required application behavior is missing.
- **Partial / Limited:** Some supporting code or presentation exists, but the
  full requirement is neither available nor verified.
- **Yes / Pass:** The stated bounded behavior was checked successfully.
- **Boundary / Observed:** An exclusion is respected by the inspected code;
  this is not proof of a functional positive workflow.
- **Blocked:** An unresolved decision or environment prerequisite prevents
  acceptance. A missing implementation can also be blocked; those are
  distinct reasons and are stated where applicable.

### Evidence collected for this review

| Ref | Check | Result and limits |
|---|---|---|
| E1 | [Express app](../backend/src/app.js), [server](../backend/src/server.js), source inventory | Only `GET /` exists. No JSON request parsing, roster routing, identity middleware, database client, repositories, or domain-service integration. Server binds to `127.0.0.1`. |
| E2 | [React shell](../frontend/src/App.jsx), [UI tests](../frontend/src/App.test.jsx) | Overview plus six workflow placeholder routes and a not-found page. No setup form, roster requests, editable assignments, or actual publish action. |
| E3 | [Compose](../docker-compose.yml), runtime database inspection | `docker compose config --quiet` passes; `hello-genai-db-1` is healthy, mapped to `127.0.0.1:5432`. SQL reports database `cps_roster_dev`, PostgreSQL `15.19`; querying non-system tables returns **0 rows**. |
| E4 | Backend test/lint commands | `npm.cmd test --prefix backend`: **1 passed**. `npm.cmd run lint --prefix backend`: passes. Test covers only the root response. |
| E5 | Frontend test/lint/build commands | **3 tests passed**; lint and production build pass. Tests cover overview labelling, setup placeholder/navigation, and not-found rendering, not full roster flows or every route interaction. |
| E6 | HTTP probes using an isolated Express app on an ephemeral loopback port | `GET /` returns 200 JSON. All seven specification endpoints return **404 `text/html`**, not the specified JSON/domain responses. Test server closed after probing. |
| E7 | [Older core](../roster/core.py), [publish workflow](../roster/publish.py), [mock](../roster/publisher.py), [dry run](../roster/dry_run.py), [Python tests](../tests/test_publish.py) | Static inspection finds in-memory round-robin generation, validation, fairness counts, and mock publishing. No React/Express integration or PostgreSQL persistence. `python -m pytest tests\test_publish.py -q` fails because pytest is not installed. Directly invoking all nine plain test functions also fails: each raises `ZoneInfoNotFoundError` for `America/Chicago`. These are environment-blocked checks, not passing tests. |
| E8 | Secret-file boundary | `git check-ignore .env` confirms local `.env` is ignored. Compose reads environment credentials; the committed example uses a placeholder. No credential values were printed in this review. This is not a full historical secret scan or production security assessment. |

JavaScript commands used the installed nvm Node directory on the process
`PATH`. The database was already running; no reset, migration, volume removal,
or record mutation was performed. No backend/frontend listener on ports 3001
or 5173 was present when inspected; E4-E6 execute the current source
independently of a previously running dev server.

## 1. Functional requirements

All 26 functional identifiers are included, including FR-005a.

| Requirement | Implemented? | Does it work? Evidence / limitation |
|---|---|---|
| FR-001 - Configurable period and two shifts per day | No in application; partial standalone code | Not working through API/UI. Python accepts start date/weeks and constructs day/night shifts, but is disconnected and runtime-blocked (E1, E6, E7). |
| FR-002 - November 1-December 12, 2026 target | No in application | Not verified; timezone policy remains open. Python test fixture uses this period but cannot currently execute successfully (E7). |
| FR-003 - Exactly one primary per required shift | No in application; partial Python validator | Not working in app. Python checks expected date/type keys and membership, but no approved eligible-team configuration or application validation exists (E1, E7). |
| FR-004 - Five supplied eligible CPS members; no fabrication | Partial boundary only | UI fabricates no members, but there is no team configuration/listing/eligibility service. Python dry-run members are synthetic fixtures, not approved CPS identities (E2, E7). |
| FR-005 - Never label incomplete/invalid generation valid | No in application; partial Python validator | No generation/status enforcement. Python has `valid` and hard-failure results, but current tests are blocked (E7). An absent generator is not a pass. |
| FR-005a - Atomic infeasible generation, no partial roster/ID | No | Decision is documented, but there is no transaction or infeasible-generation API. Python returns an in-memory roster without enforcing this generation policy (E1, E3, E7). |
| FR-006 - Reproducible generation and exposed seed/config | No in application; partial standalone code | Python round-robin is deterministic by inspection and has a seed field, but no application input snapshot/reproducibility response exists; runtime verification blocked (E7). |
| FR-007 - Ordered hours/night/weekend-holiday optimization | No | Python round-robin is not an optimizer and has no assigned-hours objective. Fairness/calendar semantics remain unresolved (E7). |
| FR-008 - Hours, total shifts, nights, weekend/holiday totals | No in application; incomplete Python counts | Fairness page is a placeholder. Python counts shifts/nights/weekends/holidays but does not calculate assigned hours (E2, E7). |
| FR-009 - Show unavoidable imbalance | No | No imbalance explanation, calculated tolerances, or fairness UI (E2, E7). |
| FR-010 - Minimum 12 elapsed hours of rest | No in application; partial standalone validator | Python compares UTC instants with a 12-hour threshold, but is not used by Express and cannot currently pass its tests (E7). |
| FR-011 - Member overlap and complete continuous coverage | No in application; partial standalone validator | Python has adjacent-interval and missing-key checks; no application enforcement or verified period-boundary suite (E7). |
| FR-012 - Eligible configured members only | No in application; partial Python membership check | Python tests inclusion in `roster.members`, not a persisted eligibility snapshot. No application team/assignment validation (E1, E3, E7). |
| FR-013 - Timezone-aware instant-based rest | No in application; partial standalone code | UTC conversion exists in Python; timezone policy and runtime timezone data are unresolved/unavailable respectively (E7). |
| FR-014 - Report affected shifts, people, hard constraints | No in application; partial Python diagnostics | Python returns rule/shifts/members dictionaries; app has no validation payload/UI (E1, E2, E7). |
| FR-015 - Date-ordered day/night review | No | Review route is only explanatory text, no assignments (E2). |
| FR-016 - Scrum master edits a draft primary | No | No editor, PATCH route, identity enforcement, or persistence (E1-E3, E6). |
| FR-017 - Recalculate validation/fairness after edit | No | No edit orchestration or automatic recalculation (E1, E2). |
| FR-018 - Distinguish draft/published lifecycle | Partial | Python has in-memory state; UI shows prototype labels, not record lifecycle. No persisted lifecycle or state transitions in app (E2, E3, E7). |
| FR-019 - Explicit invalid-edit outcome; no silent discard | No | Editing is absent; no invalid-edit response or tests (E1, E6). |
| FR-020 - Approved valid draft via labelled mock only | Partial | UI labels mock-only scope and no live adapter is wired. Actual mock publishing/approval is absent in app. Python mock lacks approval/revision enforcement and only adds the explicit simulation note when `dry_run=True` (E1, E2, E7). |
| FR-021 - Publish date/type, instants, primary, timezone | No in application; incomplete Python payload | Python `_to_records` sends start/end/primary/timezone but omits explicit shift date/type (E7). |
| FR-022 - Confirmed outcome or explicit failure/uncertainty | No in application; partial Python handling | Python models success/failure/read-back and rollback, not a complete persisted uncertain-outcome protocol. No app publish route/UI behavior (E6, E7). |
| FR-023 - Never overwrite published roster | Boundary; partial Python guard | No live update path is present. Python checks existing identity/state, but its runtime tests are blocked; app enforcement cannot be accepted without publishing (E7). |
| FR-024 - No reminders/change notifications | Boundary | Observed respected: no notification implementation or send call in inspected app/Python workflow (E1, E2, E7). No positive publish E2E exists to test this after success. |
| FR-025 - Local identity, localhost backend, no live credentials/writes | Partial | Server explicitly binds to loopback; prototype identity is documented/displayed but not implemented as an API actor/policy. No live adapter is wired (E1, E2, E8). |

## 2. User scenarios and individual acceptance cases

Scenario identifiers below append the acceptance-scenario number from the
specification. A route title alone does not satisfy a user story.

| Case | Required behavior | Implemented? | Does it work? |
|---|---|---|---|
| Scenario 1.1 | Generate 84 assignments for a confirmed 42-day period | No in app | Not working; E6. Python fixture exists but is runtime-blocked, E7. |
| Scenario 1.2 | Name unresolved required generation settings | No | No request validation/generation endpoint; generic guidance is not a per-request diagnosis. |
| Scenario 1.3 | Repeat identical inputs reproducibly, expose seed if needed | No in app | Not verified; standalone deterministic loop is not an integrated workflow. |
| Scenario 1.4 | Report infeasibility/unfilled constraints without success | No | No generation failure contract or transactional implementation. |
| Scenario 2.1 | Chronological, distinct day/night assignment review | No | Review placeholder only. |
| Scenario 2.2 | Four per-member fairness totals | No | No hours calculation or data-driven fairness screen. |
| Scenario 2.3 | Visible unavoidable imbalance | No | No optimizer or explanation. |
| Scenario 2.4 | Identify missing timezone/calendar before reliable review | No | No input-aware review or fairness computation. |
| Scenario 3.1 | Save reassignment and revalidate all hard rules/fairness | No | PATCH returns HTML 404, E6. |
| Scenario 3.2 | Identify affected resource/shifts for rest/overlap violation | No in app | Standalone validator only; blocked Python checks. |
| Scenario 3.3 | Reject invalid eligibility from valid/publishable state | No in app | No eligibility source or state gate. |
| Scenario 3.4 | Do not silently discard or falsely validate an edit | No | No editing workflow to verify. |
| Scenario 4.1 | Approved/current valid draft returns mock outcome | No in app | No approval action or mock-publish API. |
| Scenario 4.2 | Block invalid/missing-shift publish with explanation | No in app | No domain-aware publish gate; HTML 404 is not the required refusal. |
| Scenario 4.3 | Surface simulated publish rejection as failure | No in app | Standalone mock failure exists but is not connected. |
| Scenario 4.4 | Clearly simulated uncertain/partial outcome | No | No uncertain-outcome state/UI; Python rollback is not this protocol. |
| Scenario 4.5 | No ServiceNow request or overwrite | Boundary | No concrete live ServiceNow HTTP adapter in the inspected implementation. |
| Scenario 4.6 | No notification after successful publish | Boundary only | No notification code; no app success path available for E2E proof. |

### Use cases and overall workflow

| Use case | Implemented? | Does it work? |
|---|---|---|
| UC-01 - Configure inputs or list missing decisions | No | Setup route has no form or per-input validation. |
| UC-02 - Generate and persist a reproducible draft | No | No route/service/schema; Python returns in-memory objects only. |
| UC-03 - Review assignments, validation, fairness | No | All relevant screens are placeholders. |
| UC-04 - Reassign and revalidate | No | No editing route/service/UI. |
| UC-05 - Publish approved draft | No in app | Only mock-only scope labels exist; Python is separate and environment-blocked. The use-case wording still says new ServiceNow roster, unlike approved prototype scope. |

None of the specification's seven-step user workflow is complete end to end.
Configuration, generation, review, editing, approval, and outcome reporting
are missing. The no-notification boundary is respected by inspected code.
Workflow step 6's live-ServiceNow wording must be interpreted against the
approved mock-only prototype requirement, not as authorization for a live write.

## 3. Scheduling rules

| Rule | Implemented? | Does it work? |
|---|---|---|
| Day 09:00-21:00 local | Partial standalone code | Python defines the boundaries; no application implementation; execution blocked by timezone data. |
| Night 21:00-next-day 09:00 local | Partial standalone code | Python defines next-day end; app absent; final-night policy still needs confirmation. |
| Consecutive shifts, no coverage gap/overlap | Partial standalone code | Python constructs/checks intervals, but application and boundary/DST tests are absent. |
| One primary, no backup | Partial standalone code / boundary | Python assignment has one primary field; no integrated assignment model. No backup feature observed. |
| At least 12 hours between same-person assignments | Partial standalone code | UTC comparison exists, but app missing and Python execution blocked. |
| Do not invent maximum-consecutive-shift limit | Boundary | No such added constraint observed. |
| Apply FR-007 ordered fairness | No | Round-robin is not lexicographic optimization. |
| Use confirmed weekend/calendar settings | No | Python hard-codes Saturday/Sunday and a small US holiday set; not an approved request-supplied calendar. |
| Cover weekends/holidays under the same hard rules | Partial standalone code | Python iterates every day; no integrated scheduling/validation and no passing runtime evidence. |

The five-person pool and 42-day/84-assignment/1,008 nominal-hour figures are
requirements/fixtures, not generated application results. Actual elapsed-hour
totals must still follow an approved timezone policy.

## 4. UI screens and required states

All listed routes are present in source. Only overview, setup rendering, and
not-found rendering have automated test evidence (E5); there was no new browser
visual/interaction test in this review.

| Screen requirement | Implemented? | Does it work? |
|---|---|---|
| Overview/navigation (supporting shell) | Yes, shell only | Pass: empty state and local/mock labels render in tests; navigation is present. |
| Setup: dates, team/eligibility, timezone, weekend/calendar collection | No | `/setup` renders a placeholder, no controls. |
| Setup: identify unconfirmed settings and availability/preferences status | Partial guidance only | Overview names timezone/weekends/holidays/team as open; no request-specific or availability/preference state. |
| Setup: generate action and blocking explanation | No | "Configure roster" navigates to a placeholder, it does not generate. |
| Generation: draft/blocked status, covered/unfilled counts, issues | No | `/generation` is placeholder text. |
| Generation: seed/configuration and review navigation | No | No generated data, seed display, or result-to-review action. |
| Review: date/time/zone/primary/status rows | No | `/review` has no table or assignment records. |
| Review: draft-only edit and recalculation/violation feedback | No | No editor, validation call, or pending/error state. |
| Review: draft versus published state | No | Static prototype badges do not represent a roster lifecycle. |
| Fairness: four totals, imbalance, missing-settings warning | No | `/fairness` describes intent only. |
| Validation: detailed rule issues and affected records | No | `/validation` contains no findings or record references. |
| Validation: disable publishing for hard failures | No | No actual publish action or validation gate exists. |
| Publish: identify target and confirm create-only operation | No | `/publish` is explanatory placeholder text, no confirmation workflow. |
| Publish: show success/failure/uncertain outcome accurately | No | Static "simulated" label is not an actual attempt result. |
| Publish: no reminder/notification controls | Boundary | No such controls observed. |
| Every screen: loading/empty/success/error states | Partial | Overview has static empty/prototype states; other routes have only a static placeholder. No data-driven loading, success, or error transitions. |

## 5. Application API contract

The following probes used the real app factory, not a mocked route handler.
Sample IDs and empty method requests test route availability, not validation
of valid business payloads. Source inspection confirms these routes are
absent; the observed 404s are not passes for request validation.

| Endpoint | Implemented? | Does it work? |
|---|---|---|
| `GET /api/v1/team-members` | No | 404 HTML; cannot list approved IDs/display names/eligibility. |
| `POST /api/v1/rosters/drafts` | No | 404 HTML; no input validation, generation, atomic persistence, or result fields. |
| `GET /api/v1/rosters/{rosterId}` | No | 404 HTML; no configuration/shifts/fairness/validation/outcome response. |
| `GET /api/v1/rosters/{rosterId}/fairness` | No | 404 HTML; no per-member totals. |
| `PATCH /api/v1/rosters/{rosterId}/assignments/{assignmentId}` | No | 404 HTML; no editing or hard-rule checks. |
| `POST /api/v1/rosters/{rosterId}/validate` | No | 404 HTML; no structured validation. |
| `POST /api/v1/rosters/{rosterId}/publish` | No | 404 HTML; no simulated attempt. |
| Supporting `GET /` (not a roster requirement) | Yes | 200 JSON: `{"service":"cps-on-call-roster-backend","status":"running"}`. Does not test database readiness. |

### API conventions

| Requirement | Implemented? | Does it work? |
|---|---|---|
| Versioned JSON `/api/v1` boundary | No | Only root JSON response; missing endpoints return default Express HTML. |
| Local-development identity and localhost-only API | Partial | Loopback bind exists; no request identity/actor attribution or protected-operation policy. |
| ISO dates/instants and separate timezone ID | No in app | Python uses ISO timestamps in its mock records but is not the API contract. |
| Opaque IDs and configured member references | No in app | No UUID/key validation, member endpoint, or schema. |
| Shift response with assignment/date/type/instants/zone/primary | No | No shift response serializer or endpoint. |
| Structured code/message/severity/assignment/member issues | No | Python `rule/shifts/members` output is not this schema. |
| Documented client/auth/not-found/server/domain status behavior | No | Current missing routes return generic HTML 404, no stable error envelope. |
| No credentials or unnecessary personal data in errors/logs | Partial boundary | Root response has neither; `.env` is ignored. No roster/integration error handling exists to verify fully. |
| No invented ServiceNow endpoint/auth/reconciliation contract | Boundary | No concrete live ServiceNow adapter configured; future production decisions remain open. |

## 6. Entities, persistence, and data integrity

Database availability is verified; application persistence is not implemented.
E3 found zero non-system tables, so **every field, foreign key, timestamp,
uniqueness constraint, and revision/history rule in the proposed tables below
is absent from the current PostgreSQL schema**.

| Entity / table | Implemented? | Does it work? |
|---|---|---|
| `team_members` | No | No UUID/display-name/eligibility/external-reference/timestamp columns or records. Python string member IDs are not this schema. |
| `rosters` | No | No persisted date/zone/calendar/state/seed/actor/timestamp/external-reference fields. Python dataclass is in-memory only. |
| `roster_members` | No | No membership/eligibility snapshot, composite uniqueness, or foreign keys. |
| `shift_assignments` | No | No UUID/roster/date/type/instant/zone/nullable-primary/timestamp fields or unique roster/date/type key. |
| `validation_runs` | No | No persisted result, actor/time, or current-revision freshness. |
| `validation_issues` | No | No structured findings or assignment/member/run relationships. |
| `publish_attempts` | No | No pending/succeeded/failed/uncertain persistence or revision/reference/diagnostics. |
| `audit_events` | No | Python appends to an in-memory list for publish only; no persisted creation/edit/validation/publish audit. |
| Scheduling configuration entity/input snapshot | No | No persisted immutable period/eligibility/timezone/calendar/approved-policy snapshot. |
| PostgreSQL owns local workflow state | Partial infrastructure | Database is accessible but backend has no DB driver/repository or migrations; it stores no workflow data. |
| ServiceNow authoritative only after confirmed live publish | Boundary | No live integration; not exercisable in mock-only prototype. |

| Integrity requirement | Implemented? | Does it work? |
|---|---|---|
| Foreign keys and atomic multi-row creation/edits | No | No application tables or transactions. |
| Unique roster membership and roster/date/shift keys | No | No constraints. Python duplicate detection is not a database constraint. |
| Assignment references eligible roster snapshot member | No | No snapshots/relational integrity; Python membership check is incomplete substitute. |
| `timestamptz` plus retained timezone identifier | No in database | No shift columns or storage. |
| Instant ordering, overlaps, coverage, 12-hour rest in domain validation | Partial standalone code | Unconnected Python checks exist; no verified application domain service. |
| Current-revision validation used for publish | No | No revision model, freshness check, approval record, or app publish path. |
| Failed/uncertain publish never becomes published | Partial standalone behavior | Python handles tested-intent failure rollback but cannot execute current fixtures; uncertain result protocol is missing. |
| Versioned schema migrations | No | No migration tool, files, or schema artifact implemented. |

## 7. Error handling and non-functional requirements

| Requirement | Implemented? | Does it work? |
|---|---|---|
| Missing configuration named, never guessed | Partial | Compose requires named DB env variables and server rejects invalid port; scheduling inputs are not validated in app. Python defaults to Chicago/US/Saturday-Sunday, contrary to approved-input-only scheduling. |
| Coverage/primary/eligibility/overlap/rest failures surfaced | No in app | Standalone diagnostics exist, but no API/UI validation workflow. |
| Fairness differences remain visible | No | No hours, optimizer, or visible comparison. |
| External authentication/authorization/API/network failures surfaced | No in app | No adapter or API outcomes. Live behavior is out of scope; simulated failure feedback is still required and missing. |
| No false published state for failure/uncertainty | No in app | No lifecycle implementation to verify; Python has some failure guards, no uncertain protocol. |
| No guessed retry/reconciliation/idempotency protocol | Boundary / partial legacy divergence | App has no external retry behavior. Python mock uses a seed-based idempotency key and rollback; that is not an approved live contract. |
| Correctness: instant-aware shift/rest calculations | No in app | Python UTC rest code exists, but no integrated calculation or DST evidence and no elapsed-hour fairness. |
| Auditability: reviewed/published roster and actor metadata | No in app | UI "Local demo" is not an authenticated/attributed actor; Python publish-only metadata is not durable history. |
| Security: approved access, no committed/logged credentials | Partial | Loopback bind and ignored `.env` observed. No API identity/authorization or domain error redaction tests; no production readiness claim. |
| Usability: distinguish lifecycle/ownership/rule failures/fairness/outcomes | Partial | Shell is readable and labelled, but none of these data-driven views exist. |
| Reliability: accurate generation and publish outcome | Partial | Shell avoids claiming existing roster data; no generation or publish outcome processing exists. Python's non-dry-run mock success is not explicitly labelled simulated. |
| Maintainability: domain separate from ServiceNow adapter | Partial | Python separates core/publisher; JS has separate empty domain/adapter folders but no implementations. |
| Technology alignment | Partial | React 18.3.1/Vite 8.3.4/plugin 6.1.2 build, Express 5.3.0 test, and PostgreSQL 15.19 run. Backend pins Node 24.22.0/npm 11.19.1. Old Python implementation is not the approved Express feature stack; Compose currently orchestrates only DB, not frontend/backend. |

## 8. Success criteria

| Criterion | Implemented? | Does it work? |
|---|---|---|
| SC-001 - Generate the target six-week period after timezone approval | No | Missing app generator and blocked by unconfirmed timezone. Python fixture cannot pass in current environment. |
| SC-002 - Exactly 84 day/night assignments | No in app | No generated/persisted assignment records. Python test intent is not successful evidence. |
| SC-003 - Continuous gap/overlap-free coverage | No in app | No integrated validator or E2E coverage evidence. |
| SC-004 - Eligibility, no overlap, at least 12-hour rest | No in app | Missing configured eligibility and validator integration; standalone Python checks blocked. |
| SC-005 - Ordered review and all four fairness totals | No | No review data or assigned-hours metric/UI. |
| SC-006 - Edit triggers validation; invalid cannot publish | No | No edit, approval, revision validation, or publish endpoint. |
| SC-007 - Accurate simulated publish, no ServiceNow request | Partial | No live adapter is wired and UI labels simulation, but no actual simulated outcome workflow exists. Cannot pass combined criterion. |
| SC-008 - Send no notifications | Boundary / observed | No notification sender or controls in inspected implementations. After-publish E2E proof unavailable. |
| SC-009 - Name unresolved settings instead of guessing | Partial | Overview provides generic guidance; Python assumes scheduling defaults. No structured app request-level validation. |

## 9. Exclusions and unresolved decisions

| Scope exclusion / gate | Current implementation and verification |
|---|---|
| Notifications/reminders | No sender or controls observed; boundary respected. |
| Secondary/backup assignments | No backup feature observed; boundary respected. |
| Updating/overwriting published roster | No app update integration; Python has duplicate/state guards but checks are blocked. |
| Live ServiceNow writes/credentials/reconciliation | No live concrete adapter wired; boundary respected. No real integration executed. |
| Maximum-consecutive-shift rule | None added; boundary respected. |
| Availability/leave/preferences pending policy | No implementation; boundary respected, but setup does not explicitly show policy status. |
| Choosing ServiceNow instance/module/API/data/auth before approval | None configured in app. Mock records are not an approved live payload contract. |
| Assuming ServiceNow roles | No mapped role/access implementation; production remains blocked. |
| Timezone interpretation | Still open. Python's Chicago default is not stakeholder confirmation. |
| Five team identities/eligibility | Still open for real CPS data; fixture strings are not authoritative. |
| Availability policy | Still open; do not invent constraints. |
| Consecutive-shift policy | No maximum defined; keep excluded unless approved. |
| Weekend/holiday fairness | Still open; Python's hard-coded US dates do not resolve it. |
| ServiceNow instance/API/auth | Still open; mock-only scope does not require live setup. |
| ServiceNow platform roles | Still open for production. Local development identity boundary does not supply a production role mapping. |
| Published corrections/versioning | Still open for separate future workflow; overwrite remains excluded. |
| Feasibility of confirmed team/policy | Not established with real settings. No passing app scheduling test. |

The approved BE-01 decisions settle feature scope, local persistence ownership,
atomic infeasibility, local-only identity boundary, and mock-only publishing.
They do not themselves implement those domain behaviors.

## 10. Specification discrepancies affecting acceptance

1. **Prototype versus live language:** Scenario 4, FR-020, the publish API,
   and SC-007 explicitly require mock-only prototype behavior, but workflow
   step 6, UC-05, and some publish-screen text still describe creating a
   ServiceNow roster. Use approved mock-only scope; do not claim the live
   capability is required or verified for this prototype.
2. **Partial-draft representation:** FR-005a requires atomic generation
   failure, whereas data/UI text still describes unfilled generated drafts.
   Failed-generation diagnostics and later invalid edits need clarification;
   they must not silently reintroduce persisted partial generation.
3. **Lifecycle contracts:** Approval/current-revision validation are implied
   by the workflow and data rules, but there is still no approval API in the
   endpoint table or complete revision schema.
4. **Old code is not the app:** Standalone Python defaults, payload shapes,
   in-memory audit, rollback, and unlabelled non-dry-run mock results cannot
   be accepted as the approved JavaScript API implementation.

## Recommended next implementation order

1. Add Express API/error baseline and identity/configuration boundaries,
   migration tooling, schema, and isolated database tests.
2. Confirm timezone/team/calendar/fairness inputs before implementing the pure
   JS scheduler and validator; prove exact 84-shift and boundary behavior.
3. Implement setup/generation/detail/fairness through the API and UI.
4. Add revision-safe editing, validation freshness, and explicit approval.
5. Add a labelled deterministic mock publisher with success/failure/uncertain
   cases and durable attempts/audit; keep live writes disabled.
6. Run integrated workflow and failure tests and reassess this checklist.

No application acceptance claim in this document is based only on package
installation, static labels, or an accessible but empty database.
