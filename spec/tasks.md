# Implementation Tasks: CPS On-Call Roster

**Source specification:** [specification.md](./specification.md)

**Implementation plan:** [plan.md](./plan.md)

**Project principles:** [constitution.md](./constitution.md)

**Gap review:** [clarify.md](./clarify.md)

## Task execution rules

- Work in task order within each phase; a task is complete only when all of its
  acceptance criteria pass and evidence is recorded.
- Do not implement a production default for any decision listed as unresolved
  in `clarify.md`. Mark blocked tasks and proceed only with independent local
  prototype tasks.
- Use clearly labelled local/mock data. Do not use real CPS member data,
  production credentials, or live ServiceNow writes without explicit approval.
- Every roster edit must preserve revision, validation, and approval
  invariants. Never relax coverage, eligibility, overlap, or rest constraints
  to improve fairness.
- Keep the scheduling/domain layer independently testable and external
  ServiceNow behavior behind an adapter.

## Phase 1 — Backend setup: database and API skeleton

### BE-01 — Resolve backend implementation gates

**Description:** Confirm the product boundary, constitution applicability,
prototype/live ServiceNow boundary, database ownership, and local identity
approach before creating production-facing integration behavior.

**Dependencies:** None.

**Acceptance criteria:**

- The approved BE-01 decisions, owner, and date are recorded in
  [decisions.md](./decisions.md), with unresolved production decisions kept
  separate.
- Product owner decision is recorded for clarification C-01.
- Database ownership and draft persistence policy are recorded for C-03 and
  S-08.
- Prototype identity and whether publish is mock-only are recorded for A-05
  and A-06.
- No live ServiceNow writes are enabled while these decisions are unresolved.

### BE-02 — Initialize the Express backend package

**Description:** Create the Node.js 24.22.0 / Express 5.3.0 backend package in
`backend/`, with reproducible npm installation and scripts for development,
testing, and production startup.

**Dependencies:** BE-01 for product-scope confirmation; may proceed as a
local-only scaffold if scope remains unresolved.

**Acceptance criteria:**

- `backend/package.json` pins the approved runtime and dependencies using a
  committed lockfile.
- The backend starts from documented commands with configuration read from
  environment variables.
- No credentials or secrets are present in source control.
- Lint/test scripts exist and return non-zero on failure.

### BE-03 — Add Express application and health routes

**Description:** Add an Express application factory, server entry point,
versioned `/api/v1` router, and health/readiness endpoints.

**Dependencies:** BE-02.

**Acceptance criteria:**

- Unit tests can import the application without starting a listening socket.
- A liveness endpoint reports process health.
- Readiness reports database dependency failure accurately once DB wiring is
  available; it never reports ready when the configured database is
  unreachable.
- Unknown routes return a documented JSON 404 response.

### BE-04 — Establish request validation and API error conventions

**Description:** Define consistent JSON success/error response conventions,
request parsing/validation boundaries, and safe centralized error handling.

**Dependencies:** BE-03.

**Acceptance criteria:**

- Malformed JSON and invalid request shapes produce documented client errors.
- Internal errors do not expose stack traces, credentials, tokens, or
  sensitive SQL/API details to clients.
- Errors have stable codes suitable for frontend display and testing.
- Error responses are covered by route-level tests.

### BE-05 — Add local Docker Compose PostgreSQL 15 service

**Description:** Configure the root `docker-compose.yml` for PostgreSQL 15
local development, with safe environment-based credentials, a health check,
and a named development volume.

**Dependencies:** BE-01.

**Acceptance criteria:**

- `docker compose config` validates the Compose configuration.
- PostgreSQL reports healthy after startup and accepts a connection using
  documented local environment variables.
- Secrets are provided via local environment configuration and no real
  credentials are committed.
- Persistent development data is stored only in the named local volume.
- No destructive reset command runs automatically.

### BE-06 — Select and configure a migration tool

**Description:** Select one migration tool compatible with the Node.js
backend, document the choice, and add migration/test scripts.

**Dependencies:** BE-02, BE-05.

**Acceptance criteria:**

- The selected tool and commands are documented in the backend README.
- A fresh empty test database can apply migrations in order.
- Migration status can be queried and repeat application does not corrupt the
  schema.
- Migration tests do not connect to production systems.

### BE-07 — Define PostgreSQL repository and migration schema

**Description:** Implement the approved logical entities: `team_members`,
`rosters`, `roster_members`, `shift_assignments`, `validation_runs`,
`validation_issues`, `publish_attempts`, and `audit_events`.

**Dependencies:** BE-01, BE-06; depends on approval of C-03 and D-01–D-03.

**Acceptance criteria:**

- Migration definitions include primary keys, required foreign keys,
  timestamps, roster lifecycle, and documented uniqueness constraints.
- Roster membership and eligibility snapshots can be represented.
- Shift rows can represent an explicitly unfilled draft shift if S-08 is
  approved; otherwise generation persistence follows the approved atomic
  failure policy.
- Revision, validation freshness, approval, and publish-attempt revision data
  are modeled if their recommended decisions are approved.
- Database integrity tests reject duplicate roster/date/shift-type keys and
  invalid foreign-key relationships.
- ServiceNow-specific table/column names are not invented.

### BE-08 — Add backend configuration validation

**Description:** Load backend configuration from environment variables and
fail startup with actionable messages when required local configuration is
missing or malformed.

**Dependencies:** BE-02, BE-05.

**Acceptance criteria:**

- Database URL and runtime mode are validated at startup.
- Missing required configuration is reported without printing secret values.
- Demo/test mode and any mock integration mode are explicit, not inferred
  from a production-looking configuration.
- Unit tests cover missing and malformed configuration.

### BE-09 — Add isolated backend and database test harness

**Description:** Configure unit and database integration tests with isolated
fixtures and cleanup limited to the test database.

**Dependencies:** BE-06, BE-07.

**Acceptance criteria:**

- Unit tests run without Docker or external Jira, Confluence, or ServiceNow
  credentials.
- Database integration tests identify and use a dedicated test database.
- Tests cannot silently target a production database URL.
- Test setup/teardown never deletes unspecified user data.

## Phase 2 — Frontend setup: UI skeleton and routing

### FE-01 — Initialize React/Vite frontend package

**Description:** Create the React 18.3.1 / Vite 8.3.4 frontend package in
`frontend/` with the agreed React plugin and lockfile.

**Dependencies:** BE-01.

**Acceptance criteria:**

- `frontend/package.json` and lockfile pin the approved dependency versions.
- Development and production-build commands run successfully.
- API base URL is configurable without embedding credentials in browser code.
- Lint/test scripts exist and return non-zero on failure.

### FE-02 — Create application shell and route structure

**Description:** Add the React entry point, shared page layout, and routes for
roster list, setup, generation result, review/edit, fairness, validation, and
publish result.

**Dependencies:** FE-01.

**Acceptance criteria:**

- Every route loads without a backend or ServiceNow connection.
- Unknown routes render an understandable not-found state.
- Navigation labels identify the workflow and lifecycle state.
- Routing behavior has automated tests.

### FE-03 — Add reusable screen state and accessibility primitives

**Description:** Add shared loading, empty, error, success, validation issue,
and lifecycle status components.

**Dependencies:** FE-02.

**Acceptance criteria:**

- Each screen can render representative loading, empty, success, and failure
  states using local fixtures.
- Form controls have programmatic labels and keyboard-operable interactions.
- Validation errors are associated with the relevant controls or assignments.
- Draft/published state is visually distinct from validation and publish
  attempt outcomes.
- A mock result is always labelled as simulated.

### FE-04 — Define frontend API client and domain types

**Description:** Create a centralized `/api/v1` client, request/response
types, and error mapping for the approved API contract.

**Dependencies:** FE-01, BE-04.

**Acceptance criteria:**

- Components do not construct API URLs or parse backend errors ad hoc.
- API base URL is configurable for local development and production builds.
- Client errors preserve stable backend error codes without exposing secrets.
- Type definitions distinguish roster lifecycle, validation result, revision,
  and publish attempt status.

## Phase 3 — Feature implementation, one vertical slice at a time

### FT-01 — Configure development team members

**Description:** Provide the approved five-person development/test team as
explicit local seed/configuration data and read-only API listing.

**Dependencies:** BE-07, BE-08.

**Acceptance criteria:**

- `GET /api/v1/team-members` returns configured IDs, display names, and
  eligibility.
- Seed data is clearly marked fictional/test-only and is not presented as
  real CPS membership.
- Unknown/duplicate member IDs are rejected in subsequent roster requests.
- Member CRUD is absent unless separately approved.

### FT-02 — Create and list draft rosters

**Description:** Implement roster creation configuration and
`GET /api/v1/rosters` list pagination; persist immutable scheduling inputs.

**Dependencies:** BE-07, BE-08, FT-01, A-01, A-04, D-03 decisions.

**Acceptance criteria:**

- `GET /api/v1/rosters` returns only rosters visible to the configured
  prototype identity, ordered by most recently updated, with stable opaque
  pagination.
- `POST /api/v1/rosters/drafts` validates date range, unique team IDs,
  eligibility, time zone, weekend definition, and holiday input shape.
- The roster stores the exact input snapshot needed to reproduce generation.
- Unresolved production settings are returned as named issues rather than
  silently defaulted.
- Database and API tests cover valid and invalid requests.

### FT-03 — Implement time-zone-aware shift construction

**Description:** Implement pure domain functions that convert local shift
boundaries into actual instants using the confirmed time-zone policy.

**Dependencies:** FT-02; blocked on S-01–S-03.

**Acceptance criteria:**

- Day shifts use local 09:00–21:00 boundaries.
- Night shifts use local 21:00 to 09:00 the following calendar day.
- Start/end dates are inclusive local shift-start dates and final-night
  behavior follows the approved policy.
- Actual elapsed durations are derived from instants and follow the approved
  fairness definition.
- DST transition cases for the selected zone are deterministic and tested.
- No schedule is marked production-ready while the zone policy is unresolved.

### FT-04 — Implement scheduling hard-constraint validator

**Description:** Create pure validation for coverage, assignment count,
eligibility, overlap, and minimum rest.

**Dependencies:** FT-03; member eligibility and interval rules approved.

**Acceptance criteria:**

- Each valid required shift has exactly one eligible primary.
- Coverage has no interval gaps or overlaps using half-open interval
  semantics if that recommendation is approved.
- No member has overlapping assignments or less than 12 elapsed hours of
  rest.
- Findings include stable code, severity, affected shifts, and members.
- Tests include exact 12-hour rest boundary, just-under-boundary, overlaps,
  missing primary, duplicate shift, ineligible member, and period boundaries.

### FT-05 — Implement fairness metrics and ordered optimizer

**Description:** Calculate per-member hours, shifts, night shifts, and
weekend/holiday shifts, then implement the approved lexicographic fairness
objective.

**Dependencies:** FT-03, FT-04; blocked on S-04 and S-05 decisions.

**Acceptance criteria:**

- Hard constraints are never relaxed to improve fairness.
- Fairness priority order is verified with cases where objectives conflict.
- Weekend/holiday counting follows the approved definition and does not
  double-count a shift unless explicitly approved.
- Unavoidable imbalance remains visible with per-member totals.
- Identical inputs and seed/configuration produce identical assignments.

### FT-06 — Generate and persist a draft

**Description:** Implement `POST /api/v1/rosters/drafts` using the pure
scheduler; store shifts, generation outcome, and reproducibility inputs.

**Dependencies:** FT-02, FT-04, FT-05, BE-07; blocked on S-08 partial-draft
policy.

**Acceptance criteria:**

- A feasible 42-day roster has 84 shift records, exactly one day and one
  night shift per local shift-start date.
- Infeasible assignments are reported without weakening hard constraints.
- Partial drafts are persisted only if that policy is approved; otherwise
  failure is atomic and no misleading roster is returned.
- Database writes are transactional according to the approved persistence
  policy.
- Repeated identical inputs yield deterministic results or expose the
  persisted seed/configuration.

### FT-07 — Retrieve roster detail and fairness summary

**Description:** Implement roster detail and read-only fairness endpoints and
connect the review/fairness screens.

**Dependencies:** FT-06, FE-04.

**Acceptance criteria:**

- `GET /api/v1/rosters/{rosterId}` returns current configuration, state,
  ordered shifts, current validation, fairness, and publish outcome.
- `GET /api/v1/rosters/{rosterId}/fairness` is read-only and reflects the
  current roster revision.
- UI shows assigned hours, total shifts, nights, weekend/holiday shifts, and
  any imbalance.
- A missing roster returns a documented not-found response; no secret data
  is included.

### FT-08 — Persist current-revision validation runs

**Description:** Implement `POST /api/v1/rosters/{rosterId}/validate`, storing
structured results against the roster revision.

**Dependencies:** FT-04, BE-07, D-01.

**Acceptance criteria:**

- Validation records include roster ID, revision, result, timestamp, and
  structured issues.
- Validation of an unchanged roster is deterministic.
- Editing a roster makes prior validation stale for approval/publishing.
- UI exposes all hard failures and affected assignment/member references.

### FT-09 — Edit draft assignment with revision protection

**Description:** Implement the draft assignment PATCH endpoint and editing
flow with atomic revision update and revalidation.

**Dependencies:** FT-07, FT-08, L-02, A-03, D-01.

**Acceptance criteria:**

- Only draft assignments can be changed.
- Unknown roster/assignment/member IDs return documented errors.
- Each successful syntactic edit increments revision atomically and
  invalidates stale approval and validation.
- A stale `If-Match`/revision is rejected with conflict and does not overwrite
  newer data.
- Invalid-but-well-formed edit behavior follows the approved policy and is
  never silently discarded or marked valid.
- Fairness and validation shown in the UI correspond to the current revision.

### FT-10 — Add review and approval lifecycle

**Description:** Add explicit approval action, actor/audit metadata, and
approval tied to the current validated revision.

**Dependencies:** FT-08, FT-09, L-01, L-03, A-06.

**Acceptance criteria:**

- Approval requires successful current-revision validation and the
  configured authorized scrum-master identity.
- Approval records actor, timestamp, and approved revision.
- Every subsequent edit invalidates approval.
- API and UI distinguish draft, validation result, approval, and publication
  status.
- Unauthenticated or unauthorized operations fail explicitly.

### FT-11 — Implement ServiceNow adapter contract and mock

**Description:** Define an adapter boundary and deterministic mock for local
tests and demos.

**Dependencies:** BE-01, FT-10, A-05.

**Acceptance criteria:**

- Scheduling/business logic depends on an application-owned adapter
  interface, not ServiceNow HTTP details.
- The mock can simulate confirmed success, explicit failure, and uncertain/
  partial outcome deterministically.
- Simulated outcomes are clearly labelled in the API/UI and cannot set a
  false real-ServiceNow success state.
- Automated tests use the mock and never need production credentials.
- No live adapter exists unless the product owner approves the production
  integration decision gate.

### FT-12 — Publish approved draft through the mock

**Description:** Implement `POST /api/v1/rosters/{rosterId}/publish`,
publish-attempt persistence, and publish result UI using the mock adapter.

**Dependencies:** FT-10, FT-11, BE-07.

**Acceptance criteria:**

- Invalid, unapproved, stale, or already-published rosters cannot be
  published.
- Each attempt records initiating actor, roster revision, timestamp, and
  outcome.
- Confirmed mock success, failure, and uncertain outcomes are all represented
  accurately and visibly as simulated.
- Failure/uncertain outcome never marks the roster published.
- No automatic retry occurs after an uncertain non-idempotent outcome.
- No reminders or schedule-change notifications are sent.

## Phase 4 — Integration and testing

### IT-01 — Integrate frontend with backend API

**Description:** Connect all UI flows to the versioned API and remove
production-path dependence on hard-coded fixtures.

**Dependencies:** FE-04, FT-02, FT-07–FT-12 as applicable.

**Acceptance criteria:**

- Setup, roster list, generation, review, fairness, validation, editing,
  approval, and mock publish flows use the documented API.
- Loading, empty, success, and error states render from actual API responses.
- API errors and stale revision conflicts are understandable and actionable.
- Fixture data is isolated to tests/demo mode and labelled as simulated.

### IT-02 — Run migrations and full local stack from clean state

**Description:** Verify repository-root setup of frontend, backend, and
PostgreSQL 15 with Docker Compose.

**Dependencies:** BE-05–BE-09, FE-01.

**Acceptance criteria:**

- Documented clean setup starts all required local services.
- Health checks accurately represent service readiness.
- Migrations succeed on a new database and application starts against it.
- PostgreSQL data survives application container restart when the named
  development volume is retained.

### IT-03 — Add end-to-end workflow tests

**Description:** Automate scrum-master flows from roster configuration through
mock publication.

**Dependencies:** IT-01, IT-02, FT-12.

**Acceptance criteria:**

- E2E tests cover successful generation/review/edit/validate/approve/mock
  publish and blocked/failed variants.
- Tests assert exactly 84 assignments for the feasible 42-day fixture.
- Tests assert incomplete or invalid rosters cannot be approved/published.
- Tests assert current revision and approval are required.
- E2E tests do not call Jira, Confluence, or live ServiceNow.

### IT-04 — Verify scheduling edge cases and acceptance criteria

**Description:** Map all specification success criteria to automated checks
or documented manual acceptance evidence.

**Dependencies:** FT-03–FT-08, IT-03.

**Acceptance criteria:**

- SC-001–SC-009 each have a test/evidence reference.
- Test coverage includes DST, period boundaries, holidays/weekends,
  infeasible resource sets, ineligible assignment, coverage gap/overlap, and
  minimum-rest boundaries.
- Fairness tests prove objective ordering and visible unavoidable imbalance.
- Any criterion blocked by unresolved decisions is marked blocked, not passed.

### IT-05 — Verify security and failure handling

**Description:** Exercise API authorization, safe configuration, redaction,
and integration failure behavior.

**Dependencies:** BE-04, BE-08, FT-10–FT-12.

**Acceptance criteria:**

- Unauthorized access to protected operations is rejected.
- Logs, HTTP responses, and audit metadata contain no secrets.
- Database outage, ServiceNow mock failure, and uncertain outcome never
  produce success-shaped responses.
- Tests prove no blind retry after ambiguous publish outcome and no overwrite
  path exists.

### IT-06 — Complete developer documentation

**Description:** Document local startup, migrations, test/seed data, API
endpoints, and mock-versus-live publish boundaries.

**Dependencies:** IT-02, IT-03, IT-05.

**Acceptance criteria:**

- A new developer can start the local stack and run tests using documented
  commands.
- Documentation clearly identifies fictional seed data and mock publish
  behavior.
- Unresolved product, scheduling, identity, and ServiceNow decisions are
  listed as blockers for production.

### IT-07 — Production integration readiness gate (conditional)

**Description:** Prepare, but do not automatically enable, production
ServiceNow writes after all required decisions and reviews.

**Dependencies:** BE-01, S-01–S-07, L-01, A-05/A-06, D-01–D-03, IT-04–IT-06.

**Acceptance criteria:**

- Constitution and feature scope are aligned and approved.
- Time zone, team/eligibility, fairness/calendar, availability, and
  ServiceNow instance/API/auth decisions are documented.
- Sandbox testing establishes create-only semantics, success verification,
  duplicate prevention, and handling of ambiguous outcomes.
- Credentials are supplied through approved secret management and never
  committed.
- Security/operations approval is recorded before enabling any live write.
- Passing this task alone does not authorize production deployment; a
  separate deployment approval is required.

## Dependency and phase gates

| Gate | Required before proceeding |
|---|---|
| Phase 1 → Phase 2 | Backend API/error baseline and local database setup are reproducible; UI can proceed with agreed mock API contracts. |
| Phase 2 → Phase 3 | Routes, screen states, and API client contracts are represented and tested. |
| Feature slice → next slice | The slice acceptance criteria pass, including targeted tests; unresolved decisions are recorded as blockers. |
| Phase 3 → Phase 4 | All prototype vertical slices are integrated; live ServiceNow remains disabled unless separately approved. |
| Prototype → production readiness | IT-07 decision gate and all specification clarifications are approved. |

## Completion report

Track each task as `Not started`, `In progress`, `Blocked`, or `Done` in the
project's issue/task tracker. For a blocked task, record the unresolved
clarification ID and the decision owner. Do not change task status to `Done`
until every listed acceptance criterion has objective test output or
documented review evidence.
