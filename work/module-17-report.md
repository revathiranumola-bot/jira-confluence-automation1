# Module 17 Completion Report

## Specification Contents
# Feature Specification: CPS On-Call Roster

**Feature branch**: `cps-on-call-roster`
**Source**: `project_spec.md`
**Status**: Draft — prototype boundaries for product scope, persistence,
infeasible generation, local identity, and publishing are approved in
[decisions.md](./decisions.md). Scheduling and production-integration blockers
remain listed in
[Clarifications](#clarifications-required-before-production-implementation).

## Overview

Create and maintain a six-week on-call roster for the five-person CPS team.
The system must provide continuous day and night primary coverage, help the
scrum master distribute shifts fairly, and support drafting, review, editing,
validation, and simulating the publish workflow for an approved roster. Live
ServiceNow publishing is a separate production capability and is not enabled
by this specification's prototype scope.

This is a distinct feature from the CPS Sprint Pulse Jira/Confluence
dashboard. For the prototype, PostgreSQL is the system of record for local
roster drafts, edits, validation history, and publish attempts; ServiceNow is
the destination system of record for a confirmed published roster. Prototype
publishing uses a clearly labelled mock only and performs no live ServiceNow
writes. The local-development identity is limited to localhost demonstrations
and tests and does not authorize deployment or production access.

The roster is on-call duty assignment, not a claim that the assigned person
actively works for the full shift. The scrum master owns review, editing, and
publishing. The initial target period is November 1 through December 12, 2026,
inclusive, subject to confirmation of the time-zone interpretation.

This specification describes intended behavior; it does not select the
ServiceNow integration point, define its data model, or authorize overwriting
an existing roster.

## User scenarios and testing

### Scenario 1 — Configure and generate a draft (Priority: P1)

As the scrum master, I can configure the roster period, the five CPS team
members, eligibility, and confirmed scheduling settings, then request a draft
so that every required day and night shift has an eligible primary.

**Why this priority**: A complete, constraint-valid draft is the prerequisite
for review, editing, and publishing.

**Independent test**: Supply five eligible team members and confirmed time-zone
and calendar settings. Generate the six-week period and verify the 84 expected
assignments, continuous coverage, eligibility, rest, and fairness calculations.

**Acceptance scenarios**:

1. **Given** a six-week period of 42 calendar days and complete, confirmed
   scheduling inputs, **when** the scrum master requests a draft, **then** the
   system creates one day and one night primary assignment for each day.
2. **Given** a draft-generation request with an unresolved required setting,
   **when** generation would require guessing that setting, **then** the system
   identifies it and does not present the roster as a valid production draft.
3. **Given** identical team, period, calendar, time-zone, and rule inputs,
   **when** draft generation is repeated, **then** the result is reproducible;
   if randomized tie-breaking is used, its seed/configuration is exposed.
4. **Given** no eligible resource can be assigned to a required shift while
   preserving hard constraints, **when** generation finishes, **then** the
   system identifies the unfilled shift or unsatisfied constraint and does not
   label the roster complete or valid.

### Scenario 2 — Review assignments and fairness (Priority: P1)

As the scrum master, I can review the date-ordered assignments and each
person's hours and shift totals so that I can assess coverage and fairness
before approval.

**Why this priority**: The user responsible for the roster needs enough
information to detect imbalance and gaps before changes are published.

**Independent test**: Load a valid roster and verify chronological day/night
assignments and all required per-person totals.

**Acceptance scenarios**:

1. **Given** a generated draft, **when** the scrum master opens its review,
   **then** assignments are shown in date order with day and night shifts
   distinguishable.
2. **Given** any configured team member, **when** fairness results are shown,
   **then** they include total assigned hours, total shifts, night shifts, and
   weekend/holiday shifts.
3. **Given** an unavoidable imbalance, **when** the roster is reviewed,
   **then** the imbalance is visible rather than silently described as equal.
4. **Given** missing time-zone or holiday-calendar settings required to
   interpret the schedule, **when** review is requested, **then** the system
   identifies the unresolved settings and does not imply fully validated
   fairness or timing results.

### Scenario 3 — Edit and revalidate a draft (Priority: P1)

As the scrum master, I can change a shift's primary before publishing and
revalidate the edited roster so that an edit cannot silently introduce a
coverage, eligibility, overlap, or rest violation.

**Why this priority**: Human review and correction are part of the defined
roster workflow, but edits must preserve hard scheduling rules.

**Independent test**: Change an assignment to an eligible member and verify
that all hard constraints and fairness totals are recalculated; then submit an
edit that violates rest or eligibility and verify the failure is clearly
reported.

**Acceptance scenarios**:

1. **Given** a draft assignment, **when** the scrum master changes its primary
   and saves, **then** the system revalidates coverage, eligibility, overlap,
   rest, and fairness using the updated assignment.
2. **Given** an edit that creates an overlap or less than 12 hours of rest,
   **when** the edit is validated, **then** the violating assignments and
   affected resource are identified and the draft is not marked valid.
3. **Given** an assignment to someone outside the configured eligible team,
   **when** the edit is validated, **then** the eligibility failure is
   identified and the roster cannot be treated as valid.
4. **Given** an invalid edit, **when** the system reports the result,
   **then** it does not silently discard or represent the change as a
   successfully validated roster.

### Scenario 4 — Simulate publishing an approved draft
(Prototype scope)

As the scrum master, I can simulate publishing a reviewed and valid roster so
that I can review the prototype workflow without making a live ServiceNow
change.

Live ServiceNow publishing remains a future production capability and is not
part of this prototype.

**Independent test**: With an approved valid draft, exercise deterministic
mock success, failure, and uncertain outcomes. Verify every outcome is
labelled simulated and no ServiceNow request is made.

**Acceptance scenarios**:

1. **Given** a reviewed draft that passes all required hard validations and
   the local prototype identity, **when** the scrum master requests publish,
   **then** the mock reports a simulated outcome without making a live
   ServiceNow write.
2. **Given** a draft with a missing shift or an unresolved hard-constraint
   failure, **when** publishing is requested, **then** the system prevents
   publication and identifies the reason.
3. **Given** the mock rejects the request, **when** publishing is attempted,
   **then** the failure is surfaced and is not represented as a successful
   publish.
4. **Given** an uncertain or partial publish outcome, **when** the system
   reports the result, **then** it remains clearly simulated and does not
   claim a real ServiceNow outcome.
5. The prototype makes no ServiceNow network request and cannot overwrite an
   existing ServiceNow roster.
6. **Given** a successful publish, **when** the operation completes, **then**
   no shift reminders or schedule-change notifications are sent.

## Functional requirements

### Roster generation

- **FR-001**: The system MUST support a configurable roster period and produce
  day and night on-call shifts for every calendar day in that period.
- **FR-002**: The initial target period MUST be November 1 through
  December 12, 2026, inclusive, representing 42 calendar days, once its
  time-zone interpretation is confirmed.
- **FR-003**: Each required shift MUST have exactly one primary assignment.
- **FR-004**: The eligible resource pool MUST consist of the five configured
  CPS team members. Member names and stable identifiers are supplied later;
  they MUST NOT be fabricated.
- **FR-005**: The system MUST NOT silently produce a complete/valid status if
  a shift is unfilled or a hard constraint is unsatisfied.
- **FR-005a**: If generation cannot satisfy every required shift or hard
  constraint, it MUST fail atomically: no roster or partial assignment set is
  persisted, and no roster ID is returned. A later approved requirement may
  define a separate incomplete-draft workflow.
- **FR-006**: Draft generation MUST be reproducible for the same inputs and
  rules. If randomized tie-breaking is used, the seed/configuration MUST be
  exposed.

### Fairness and validation

- **FR-007**: The generator MUST apply fairness priorities in this order:
  first balance total assigned hours, then minimize differences in night
  shifts, then minimize differences in weekend/holiday shifts.
- **FR-008**: The system MUST calculate and present each person's total
  assigned hours, total shifts, night shifts, and weekend/holiday shifts.
- **FR-009**: The system MUST report unavoidable imbalance; it MUST NOT imply
  perfect fairness if the totals differ.
- **FR-010**: The system MUST enforce at least 12 hours between the end of one
  assignment and the start of the same person's next assignment.
- **FR-011**: The system MUST prevent overlapping assignments for the same
  person and MUST validate continuity and non-overlap of overall coverage.
- **FR-012**: Validation MUST ensure each assignment belongs to an eligible
  configured CPS team member.
- **FR-013**: Rest calculations MUST use actual time-zone-aware instants, not
  calendar-date comparisons alone.
- **FR-014**: The system MUST identify the shifts, people, and hard constraints
  involved in an incomplete or invalid roster.

### Review, edit, and lifecycle

- **FR-015**: The system MUST present assignments in date order and distinguish
  day from night shifts.
- **FR-016**: The scrum master MUST be able to change a shift's primary while
  the roster is a draft.
- **FR-017**: After an edit, the system MUST revalidate coverage, eligibility,
  overlaps, minimum rest, and fairness.
- **FR-018**: The system MUST clearly distinguish draft and published roster
  states.
- **FR-019**: The system MUST NOT silently discard an edit or mark a hard-rule
  violation as valid.

### ServiceNow publishing

- **FR-020**: The prototype MUST publish an approved valid draft only through
  a clearly labelled mock adapter. It MUST NOT make live ServiceNow writes.
  Live publishing as a **new** CPS roster in ServiceNow requires a separately
  approved production integration specification and gate.
- **FR-021**: Published assignment data MUST include shift date and type,
  start/end instants, the primary resource identifier, and applicable
  time-zone context.
- **FR-022**: The system MUST confirm publish success or surface an explicit
  failure; an unconfirmed or failed operation MUST NOT be presented as a
  successful publish.
- **FR-023**: The system MUST NOT overwrite an existing published roster.
  Corrections or updates to an existing roster are out of scope pending a
  separately approved workflow.
- **FR-024**: The system MUST NOT send shift reminders or schedule-change
  notifications.
- **FR-025**: Prototype API operations MUST use a documented local-development
  identity and the backend MUST bind only to localhost. This identity MUST
  NOT be treated as production authentication or authorization. Live
  ServiceNow credentials and writes are prohibited in the prototype.

## Key entities and data

### Team member

- Stable ServiceNow or application identifier.
- Display name.
- Eligibility status for CPS on-call assignments.

The five members' identities and eligibility are not supplied yet.

### Roster

- Roster identifier.
- Configured start and end dates and the confirmed time-zone context.
- Lifecycle state: draft or published.
- Creation/update metadata sufficient to review changes.
- Generation seed/configuration if randomized tie-breaking is used.

### Shift assignment

- Roster identifier.
- Shift date and type (day or night).
- Time-zone-aware start and end instants.
- Assigned primary resource identifier.
- Creation/update metadata sufficient to review changes.

### Scheduling configuration

- Roster period.
- Eligible team member set.
- Confirmed time-zone interpretation.
- Weekend definition and holiday calendar needed for fairness.
- Any explicitly approved availability policy.

Do not infer unprovided identities, availability, holiday calendars,
ServiceNow fields, or identifiers.

## Scheduling rules

- Day shift: 09:00–21:00 local time.
- Night shift: 21:00–09:00 on the following calendar day.
- The two shifts are consecutive and MUST provide continuous coverage without
  a gap or overlap.
- Each shift has one primary; no secondary/backup assignment is included.
- Each person MUST have at least 12 hours between the end of one assignment and
  the start of their next assignment.
- No maximum-consecutive-shift limit has been specified; do not invent one.
- Fairness MUST follow the ordered priorities in FR-007.
- Weekend and holiday fairness MUST use the confirmed weekend definition and
  team-selected regional holiday calendar.
- The roster covers weekends and holidays; holiday/weekend shifts are not
  exempt from coverage or rest rules.

## User workflow

1. The scrum master supplies/configures the team, period, and confirmed
   scheduling inputs.
2. The scrum master requests draft generation.
3. The system generates assignments and validates hard constraints.
4. The scrum master reviews coverage, fairness totals, and all warnings or
   failures.
5. The scrum master edits assignments as needed and reruns validation.
6. The scrum master publishes the approved valid roster to ServiceNow as a new
   roster.
7. The system reports a confirmed success or an explicit failure/uncertain
   outcome. It sends no notifications.

## Use-case summary

| ID | Actor | Use case | Result |
|---|---|---|---|
| UC-01 | Scrum master | Configure period, team eligibility, time zone, and fairness calendar | A configuration ready for generation, or a clear list of missing decisions |
| UC-02 | Scrum master | Generate a roster draft | Persisted draft shifts, validation outcome, and reproducibility information |
| UC-03 | Scrum master | Review assignments and fairness | Date-ordered shifts, validation status, and fairness totals |
| UC-04 | Scrum master | Reassign a draft shift and revalidate | Updated draft and current validation/fairness results |
| UC-05 | Scrum master | Publish an approved valid draft | New ServiceNow roster and an accurately reported publish outcome |

## User interface screens

The frontend MUST make the roster lifecycle and hard-constraint failures
visible. These are logical screens; they may be implemented as routes, tabs, or
panels.

### 1. Roster setup

- Collect the roster start/end dates, eligible team members, confirmed
  time-zone identifier, weekend definition, and selected holiday calendar.
- Identify required-but-unconfirmed settings before enabling production
  generation.
- Show that availability and preferences are not configured unless a policy
  is approved.
- Provide a generate-draft action and communicate when generation is blocked
  by missing required configuration.

### 2. Draft generation result

- Show draft or blocked/invalid state, covered versus unfilled shifts, and
  validation warnings/failures.
- Show the generation seed/configuration when tie-breaking is randomized.
- Provide navigation to assignment review; do not describe an incomplete
  draft as complete or valid.

### 3. Roster review and editing

- Display date-ordered day and night shifts, each with its date, local shift
  times, time-zone context, primary assignee, and validation status.
- Allow the scrum master to change an assignee only while the roster is a
  draft.
- After a change, show that validation and fairness are being recalculated;
  identify affected shifts/resources when a hard constraint fails.
- Clearly distinguish draft from published state.

### 4. Fairness summary

- Show total assigned hours, total shifts, night shifts, and
  weekend/holiday shifts for each configured team member.
- Explain visible imbalances; do not imply that an unavoidable imbalance is
  equal or validly resolved.
- Identify when missing time-zone or holiday-calendar configuration prevents
  a reliable total.

### 5. Validation details

- Summarize coverage gaps, missing or duplicate primaries, ineligible
  assignments, overlaps, rest violations, unresolved settings, and fairness
  differences.
- Identify the affected shift and resource where applicable.
- Make the publish action unavailable while required hard validations fail.

### 6. Publish confirmation and result

- Before publishing, identify the roster being sent to ServiceNow and confirm
  that the action creates a new roster rather than overwriting an existing
  one.
- After submission, show confirmed success, explicit failure, or uncertain/
  partial outcome without success-shaped fallbacks.
- Do not offer or trigger shift reminders or schedule-change notifications.

All screens MUST include understandable loading, empty, success, and error
states appropriate to their data and actions.

## Application API contract

The following are proposed **application-owned Express API** endpoints, not
ServiceNow endpoints. Use a versioned `/api/v1` prefix and JSON requests and
responses. In the prototype, the API is restricted to localhost and uses only
the documented local-development identity. Do not expose it beyond the
development environment. A production identity provider and role mapping
remain unresolved and are required before deployment or live integration.

| Method and path | Purpose and request data | Response data / behavior |
|---|---|---|
| `GET /api/v1/team-members` | List the configured CPS team members and eligibility; no request body. | Member IDs, display names, eligibility. Do not fabricate missing members. |
| `POST /api/v1/rosters/drafts` | Generate and persist a draft. Body: `startDate`, `endDate`, `timeZoneId`, `teamMemberIds`, `weekendDefinition`, `holidayCalendarId`, and optional `generationSeed`. | On success, return `rosterId`, `status`, generated shifts, validation outcome, fairness totals, and seed/configuration when applicable. If required inputs are unresolved or constraints make complete generation infeasible, fail atomically, return an actionable error, and persist no roster or partial assignments. |
| `GET /api/v1/rosters/{rosterId}` | Retrieve roster detail. | Roster configuration/state, ordered shifts, validation summary, fairness totals, and publication outcome if any. |
| `GET /api/v1/rosters/{rosterId}/fairness` | Retrieve or recalculate fairness for a roster. | Per-member total hours, total shifts, night shifts, weekend/holiday shifts, and visible imbalance indicators. |
| `PATCH /api/v1/rosters/{rosterId}/assignments/{assignmentId}` | Reassign a draft shift. Body: `primaryMemberId`. | Updated assignment and recalculated validation/fairness outcome. Reject changes to a published roster and identify hard-constraint failures. |
| `POST /api/v1/rosters/{rosterId}/validate` | Revalidate current assignments; no request body required. | `valid` status, structured failures/warnings identifying affected shifts/resources, and recalculated fairness totals. |
| `POST /api/v1/rosters/{rosterId}/publish` | Simulate publishing an approved valid draft through the mock adapter; no body required. | Clearly labelled simulated outcome: confirmed mock success, failure, or uncertain/partial, plus a safe diagnostic. Never report a mock result as a real ServiceNow publish. |

### API data and error conventions

- Dates use ISO `YYYY-MM-DD`; instants use ISO 8601 timestamps with an
  explicit offset or UTC `Z`; the IANA/approved time-zone identifier is
  provided separately as `timeZoneId`.
- IDs are opaque to clients. A member ID references a configured member, not
  a display name supplied as an assignment key.
- A shift response includes `assignmentId`, `shiftDate`, `shiftType`,
  `startsAt`, `endsAt`, `timeZoneId`, and nullable `primaryMemberId` for
  unfilled generated shifts.
- Validation issues include a stable `code`, human-readable `message`,
  `severity`, and relevant `assignmentIds` and/or `memberIds`.
- Use standard HTTP status codes for malformed/invalid requests, missing
  resources, authorization failures, and server/integration failures. A
  response MUST NOT turn a failed or uncertain ServiceNow operation into a
  successful publish state.
- Do not expose credentials, tokens, or unnecessary issue/person data in
  errors or logs.
- These routes describe the roster application boundary only. The eventual
  ServiceNow endpoint paths, payloads, fields, authentication, and
  reconciliation behavior require the clarifications listed below.

## Proposed PostgreSQL data model

The following is the application-side logical model for PostgreSQL 15. It
supports the required roster workflow without assuming ServiceNow table names
or field names. Physical types, migration syntax, and ServiceNow mappings are
confirmed during planning.

PostgreSQL is authoritative for local drafts, edits, validation history, and
publish attempts. ServiceNow is authoritative for a roster only after a
separately approved live integration confirms publication; the prototype does
not write to ServiceNow.

### `team_members`

One configured CPS resource per row.

| Field | Meaning |
|---|---|
| `id` | Application primary key (UUID). |
| `servicenow_resource_id` | External resource identifier; nullable until supplied. |
| `display_name` | Human-readable name; supplied by the roster owner. |
| `is_eligible` | Whether the member is eligible for CPS on-call assignments. |
| `created_at`, `updated_at` | Audit timestamps. |

### `rosters`

One draft or published roster per row.

| Field | Meaning |
|---|---|
| `id` | Application primary key (UUID). |
| `start_date`, `end_date` | Inclusive configured roster dates. |
| `time_zone_id` | Confirmed time-zone identifier; required before production generation. |
| `weekend_definition`, `holiday_calendar_id` | Fairness configuration; unresolved values must not be guessed. |
| `status` | Lifecycle state, at minimum `draft` or `published`; uncertain publish state must not be represented as published. |
| `generation_seed` | Nullable deterministic seed/configuration when tie-breaking requires it. |
| `service_now_roster_id` | External roster reference, nullable until confirmed by ServiceNow. |
| `created_by`, `updated_by`, `published_by` | Application actor identifiers, nullable where not yet available. |
| `created_at`, `updated_at`, `published_at` | Audit timestamps. |

### `roster_members`

Join table recording which team members and eligibility state were used for a
specific roster.

| Field | Meaning |
|---|---|
| `roster_id` | Foreign key to `rosters`. |
| `team_member_id` | Foreign key to `team_members`. |
| `is_eligible` | Eligibility snapshot for this roster's generation and validation. |

The pair (`roster_id`, `team_member_id`) MUST be unique.

### `shift_assignments`

One row for each required day/night shift in a roster, including an unfilled
shift so coverage gaps remain explicit.

| Field | Meaning |
|---|---|
| `id` | Application primary key (UUID). |
| `roster_id` | Foreign key to `rosters`. |
| `shift_date` | Local calendar date on which the shift begins. |
| `shift_type` | `day` or `night`. |
| `starts_at`, `ends_at` | Actual time-zone-aware instants, stored as PostgreSQL `timestamptz`. |
| `time_zone_id` | Confirmed zone used to interpret local shift boundaries. |
| `primary_member_id` | Nullable foreign key to `team_members`; null represents an unfilled shift and must fail complete-coverage validation. |
| `created_at`, `updated_at` | Audit timestamps. |

The pair (`roster_id`, `shift_date`, `shift_type`) MUST be unique. Store
instants as `timestamptz` and retain the zone identifier separately; do not
rely on the database session time zone to preserve the original zone.

### `validation_runs` and `validation_issues`

- `validation_runs` records a roster validation attempt: roster ID,
  valid/invalid result, execution time, and actor or system origin.
- `validation_issues` records each finding: validation-run ID, stable issue
  code, severity, message, and related assignment/member IDs where applicable.
- A new run supersedes prior validation for publish eligibility; publish uses
  validation for the current roster revision, not stale results.

### `publish_attempts`

One row per attempt to publish a roster as a **new** ServiceNow roster.

- Store roster ID, initiating actor, attempt time, outcome (`pending`,
  `succeeded`, `failed`, or `uncertain`), external reference when confirmed,
  and a safe diagnostic that excludes secrets.
- A failure or uncertain result MUST NOT set the roster to `published`.
- Retrying/reconciliation semantics depend on the confirmed ServiceNow API and
  must avoid duplicate external side effects.

### `audit_events`

Record roster creation, assignment edits, validation, and publish attempts
with actor, action, entity, timestamp, and the minimum before/after metadata
needed to audit changes. Exclude credentials and avoid copying unnecessary
personal or external issue content.

### Data integrity rules

- Use foreign keys for roster/member/assignment relationships and transactions
  for multi-row roster creation or edits that must be atomic.
- Enforce unique roster shift keys and roster membership keys at the database
  boundary.
- Validate that assignment members are part of that roster's eligible
  membership before treating the roster as valid.
- Validate time ordering, actual instant overlaps, and the 12-hour rest rule
  in scheduling/domain logic; do not rely only on date-level database checks.
- Schema changes MUST be delivered through versioned migrations in accordance
  with the project constitution.

## Error handling and states

- Missing required configuration MUST be identified by name; the system MUST
  NOT silently substitute a guessed value.
- Unfilled shifts, missing primaries, ineligible assignments, coverage gaps,
  overlaps, and rest violations MUST be reported as validation failures.
- Fairness differences MUST remain visible even where hard constraints prevent
  perfect balance.
- ServiceNow authentication, authorization, API, and network failures MUST be
  surfaced to the scrum master.
- A failed or uncertain publish MUST NOT transition the roster to a falsely
  successful published state.
- No specific retry, reconciliation, or idempotency mechanism is prescribed
  until the ServiceNow integration behavior is known.

## Non-functional requirements

- **Correctness**: Shift boundaries and rest calculations MUST be
  time-zone-aware and based on actual instants.
- **Auditability**: Preserve enough metadata to identify the roster and the
  scrum master who reviewed/published it, subject to ServiceNow capabilities
  and policy.
- **Security**: Use approved authentication/authorization; never commit
  credentials or expose them in logs.
- **Usability**: Make roster state, assignment ownership, coverage gaps, rest
  violations, fairness totals, and publish outcomes easy to distinguish.
- **Reliability**: Do not show success for incomplete generation or an
  unconfirmed/failed publish. Clearly distinguish mock outcomes from live
  external effects.
- **Maintainability**: Keep schedule-generation rules separate from the
  ServiceNow adapter so the scheduling logic can be tested independently.
- **Technology alignment**: Follow the project stack and development
  constraints in [the constitution](./constitution.md); this feature spec does
  not choose unconfirmed ServiceNow APIs or authentication details.

## Success criteria

- **SC-001**: After required time-zone confirmation, the system can generate
  the configured six-week roster for November 1–December 12, 2026.
- **SC-002**: A complete 42-day roster contains exactly 84 assignments:
  one day primary and one night primary per day.
- **SC-003**: All 84 assignments provide continuous coverage without gaps or
  overlaps.
- **SC-004**: Every assignment uses an eligible configured team member, and
  no member has overlapping shifts or less than 12 hours of rest.
- **SC-005**: The scrum master can review date-ordered assignments and all
  four required fairness totals for each member.
- **SC-006**: Editing a draft triggers revalidation, and a hard-constraint
  violation cannot be silently marked valid or published.
- **SC-007 (prototype)**: Mock publishing accurately reports a simulated
  outcome and makes no ServiceNow request or write. Live creation of a new
  ServiceNow CPS roster is a separate production acceptance criterion and is
  not satisfied by mock success.
- **SC-008**: The system sends no notifications.
- **SC-009**: Unresolved configuration is named explicitly rather than
  silently guessed.

## Out of scope

- Notifications or reminders.
- Secondary/backup assignments.
- Overwriting or updating an already-published roster.
- Live ServiceNow writes, credentials, and publish reconciliation in the
  prototype; these require a separately approved production integration gate.
- A maximum-consecutive-shift rule.
- Availability, planned leave, or preference behavior until a policy is
  approved.
- Choosing a ServiceNow module, endpoint, schedule data model, instance, or
  authentication method before those details are supplied.
- Assuming ServiceNow roles or permissions not yet mapped to the scrum
  master's responsibilities.

## Clarifications required before production implementation

The following are implementation-blocking decisions where they affect
correctness, authorization, or integration. Do not make a production guess.

1. **Time zone**: Does “CST” mean a daylight-saving-aware regional time zone
   such as `America/Chicago`, or a fixed UTC−6 offset? Confirm before
   generating or publishing the production schedule.
2. **Team and eligibility**: What are the five member names/identifiers, and
   are all eligible for both day and night shifts?
3. **Availability**: Are leave/availability constraints hard blocks, warnings,
   or excluded? Are preferences in scope?
4. **Consecutive shifts**: Is any maximum-consecutive-shift policy required?
   None is defined by the source requirements.
5. **Weekend and holiday fairness**: Which weekend definition, regional
   holiday calendar, and holiday inputs should be used?
6. **ServiceNow integration**: Which instance, environment, module, schedule
   data model, API/integration point, and approved authentication method are
   required?
7. **ServiceNow authorization**: Which platform roles permit the scrum master
   to create, review, edit, and publish rosters?
8. **Published-roster policy**: Are published rosters versioned? How should a
   future correction be handled through a separately approved update workflow?
9. **Feasibility**: Confirm the eligible-resource and availability rules make
   complete coverage with the 12-hour rest constraint feasible for the
   configured period.

## Assumptions and dependencies

- The initial target roster is 42 calendar days beginning November 1, 2026,
  and ending December 12, 2026, inclusive, once the time-zone interpretation
  confirms those intended calendar dates.
- The roster has two shifts per day, nominally 12 local clock hours each, so
  full coverage requires 84 assignments and 1,008 nominal local clock hours.
  Actual elapsed shift durations MUST be derived from the confirmed time-zone
  rules; they may differ when daylight-saving transitions apply.
- The team contains five CPS members; their identities and eligibility data
  will be provided by the scrum master.
- The scrum master is the confirmed roster owner for review, edit, and
  publish. Platform access roles remain unconfirmed.
- ServiceNow is the destination for the new roster, but its API/data contract
  and application-side persistence details have not been selected.
- The implementation depends on approved ServiceNow access and on the
  decisions listed above; until resolved, affected production workflows MUST
  remain blocked or explicitly report that they are not configured.

## Commit History
d485d18 feat: complete prototype per specification.
a0fdb26 chore: configure local PostgreSQL service
41ff309 feat: scaffold roster prototype apps
19a895e docs: complete roster specification package
ee8db18 docs: add SpecKit project constitution and specification
259528e chore: project skeleton for prototype
ae21284 Add MCP tooling and offline Markdown validation
632e510 Document validator use in ServiceNow backlog
0d810e1 Link Phase 1 backlog tasks to GitHub issues
994103e Add Module 14 GitHub integration report
083a6e3 Add GitHub issue numbers to Phase 1 backlog
579426f Commit current workspace changes
dab0e98 Add MCP Server folder with echo-windows config and script
e342949 Add Module 13 MCP completion report
4fe2e7d Add compound interest tool and agent instructions
e1c483a Add charts to October 2026 CPS status report
fc96aa1 Add October 2026 CPS status report (sample data)
bae2e4f Add VS Code settings, weekly status report, and Module 9 report
be4f419 Add Module 10 completion report
223dc24 Add TODO, reports, and work files
179864e Add CPS on-call roster implementation backlog
c8047b1 Add CPS on-call roster specification

## Commit Count
22

## Project Files
.env.example
.github
.gitignore
.vscode/github.ps1
.vscode/mcp-calculate.ps1
.vscode/mcp-echo.ps1
.vscode/mcp-get-time.ps1
.vscode/mcp.json
.vscode/settings.json
MCP Server/.vscode/mcp-echo.ps1
MCP Server/.vscode/mcp.json
MCP Server/calculate-windows/walkthrough.md
MCP Server/echo-windows/walkthrough.md
MCP Server/get-time-windows/walkthrough.md
MCP Server/github-write-windows/walkthrough.md
MCP Server/github/walkthrough.md
TODO.md
backend/.env.example
backend/.gitignore
backend/.gitkeep
backend/README.md
backend/eslint.config.js
backend/package-lock.json
backend/package.json
backend/src/.gitkeep
backend/src/app.js
backend/src/middleware/.gitkeep
backend/src/routes/.gitkeep
backend/src/scheduling/.gitkeep
backend/src/server.js
backend/src/servicenow/.gitkeep
backend/src/services/.gitkeep
backlog.md
docker-compose.yml
docs/.gitkeep
frontend/.env.example
frontend/.gitignore
frontend/.gitkeep
frontend/README.md
frontend/eslint.config.js
frontend/index.html
frontend/package-lock.json
frontend/package.json
frontend/src/.gitkeep
frontend/src/App.jsx
frontend/src/App.test.jsx
frontend/src/api/.gitkeep
frontend/src/components/.gitkeep
frontend/src/main.jsx
frontend/src/pages/.gitkeep
frontend/src/styles.css
frontend/src/test-setup.js
frontend/src/types/.gitkeep
frontend/vite.config.js
instructions
project_spec.md
reports/example.md
reports/instructions.md
reports/status-2026-10-cps-sample.md
reports/template.md
reports/weekly-status-2026-10-16.md
roster/__init__.py
roster/core.py
roster/dry_run.py
roster/publish.py
roster/publisher.py
spec/analyze.md
spec/checklist.md
spec/clarify.md
spec/constitution.md
spec/decisions.md
spec/plan.md
spec/specification.md
spec/tasks.md
tests/api/.gitkeep
tests/api/backend-app.test.js
tests/scheduling/.gitkeep
tests/servicenow/.gitkeep
tests/test_publish.py
tools/compound_interest.py
tools/validate_files_with_ai.py
validation-reports/Interest_calculator.agent.validation.md
validation-reports/calculate-compound-interest.agent.validation.md
validation-reports/create-status-report.agent.validation.md
validation-reports/creating-instructions.agent.validation.md
validation-reports/main.agent.validation.md
validation-reports/publish-roster.agent.validation.md
validation-reports/validate-roster.agent.validation.md
validation-reports/verify-publish-result.agent.validation.md
validation-rules.md
work/compound_interest.py
work/jira-dashboard/README.md
work/jira-dashboard/index.html
work/jira-dashboard/requirements.md
work/module-03-report.md
work/module-08-report.md
work/module-09-report.md
work/module-10-report.md
work/module-12-report.md
work/module-13-report.md
work/module-14-report.md
work/module-14-report1.md
work/module-14-report2.md
work/module-15-report.md
work/module-16-report.md
work/module03-task
work/status-report-template.md

