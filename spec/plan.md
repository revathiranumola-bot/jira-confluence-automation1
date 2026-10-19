# Implementation Plan: CPS On-Call Roster

**Source specification:** [specification.md](./specification.md)

**Project principles:** [constitution.md](./constitution.md)

**Review and open decisions:** [clarify.md](./clarify.md)
**Decision record:** [decisions.md](./decisions.md)
**Status:** Proposed — BE-01 prototype gates are approved; remaining
production and scheduling gates below remain open.

## Plan objectives

- Deliver the on-call roster as a sequence of independently verifiable
  milestones.
- Preserve the requested four-phase order: backend setup, frontend setup,
  feature implementation one feature at a time, then integration and testing.
- Keep the scheduling engine independent of HTTP, database, and ServiceNow
  transports.
- Never bypass hard coverage, eligibility, overlap, or rest requirements to
  improve fairness.
- Keep ServiceNow publishing mocked and clearly labelled until its API,
  authorization, product scope, and success/reconciliation contract are
  explicitly approved.

## Scope and prerequisite decisions

Before production implementation begins, the product owner must address:

1. **Product boundary (C-01): Resolved for prototype (DEC-001).** The roster
   is a distinct feature governed by the constitution alongside Sprint Pulse.
2. **Scheduling inputs (S-01–S-07):** Confirm the time-zone interpretation,
   final-night boundary, actual-hours fairness meaning, team membership and
   eligibility, weekend/holiday rules, and any availability policy.
3. **Prototype integration boundary (A-05, A-06): Resolved for prototype
   (DEC-004, DEC-005).** Use a mock-only publisher and localhost-only
   development identity. Production API, authorization, and
   outcome-reconciliation requirements remain open.
4. **Persistence (C-03, S-08): Resolved for prototype (DEC-002, DEC-003).**
   PostgreSQL owns local workflow state and infeasible generation fails
   atomically. Approval workflow, revision freshness, and production data
   retention remain open (L-01–L-03, D-01).

Until those decisions are resolved, implement only local, non-production
functionality that does not depend on guessed settings. Do not make live
ServiceNow writes.

## Phase 1: Backend setup — database and API skeleton

### Work

- Create the Node.js 24.22.0 / Express 5.3.0 backend package in `backend/`,
  following [the constitution](./constitution.md).
- Add an Express application entry point, configuration loading, request
  validation/error-handling boundary, and `/api/v1` routing skeleton.
- Add PostgreSQL 15 through the root `docker-compose.yml`, including health
  checks, a persistent local development volume, and environment-variable
  configuration. Do not commit credentials.
- Select and configure one migration tool; add the initial migration
  framework and a local-only seed/configuration path for explicitly supplied
  team members.
- Define API response/error conventions and request validation based on
  A-03. Use the documented localhost-only prototype identity (DEC-004);
  production identity and authorization remain out of scope until approved.
- Create backend test configuration and database-test setup that uses
  isolated test data and does not call ServiceNow.

### Milestone 1.1 — Backend boots

- Backend starts locally and exposes a health/readiness endpoint.
- Malformed requests and internal errors have a consistent JSON error shape;
  secrets are not returned or logged.
- The endpoint does not claim database readiness when PostgreSQL is
  unavailable.

### Milestone 1.2 — Database is reproducible

- `docker compose up` starts PostgreSQL 15 and the backend development
  dependency without exposing secrets in committed files.
- Migrations apply from an empty database and can be checked in automated
  tests.
- Local seeded member data is explicitly identified as development/test data.

### Milestone 1.3 — Logical schema and repository boundary

- Implement approved migrations for team members, rosters, roster membership
  snapshots, shift assignments, validation runs/issues, publish attempts, and
  audit events.
- Include roster revision and validation-freshness fields if D-01 is approved.
- Enforce primary keys, foreign keys, uniqueness, and assignment-to-eligible-
  roster-membership integrity at the database and domain boundaries where
  practical.
- Do not invent ServiceNow table names or external field mappings.

### Phase 1 exit criteria

- Fresh local setup, migration, and API-start instructions work from the
  repository root.
- Backend unit tests and database integration tests pass.
- Phase 1 provides an API/data foundation only; it does not contain a live
  ServiceNow integration or claim to generate valid production schedules.

## Phase 2: Frontend setup — UI skeleton and routing

### Work

- Create the React 18.3.1 / Vite 8.3.4 frontend package in `frontend/` with
  the agreed React plugin and locked dependency versions.
- Establish the single-page application entry point, shared layout,
  development scripts, API base URL configuration, and route-level not-found
  and error boundaries.
- Add logical routes/screens for:
  - Roster list (needed for existing drafts; see A-01).
  - Roster setup.
  - Draft generation result.
  - Roster review/edit.
  - Fairness summary.
  - Validation details.
  - Publish confirmation/result.
- Build empty/loading/error states and reusable status/validation display
  components. Do not add real scheduling or persistence logic in this phase.
- Keep sample fixtures clearly labelled and isolated from production API
  responses.

### Milestone 2.1 — Frontend boots and routes

- The React app starts using Vite, all named screens are reachable, and
  navigation does not expose credentials or require a live external service.
- API configuration is environment-based and has a safe local default.

### Milestone 2.2 — Screen contracts are represented

- Screens have accessible form labels and clear loading, empty, success, and
  error states.
- UI types/components represent draft versus published lifecycle separately
  from validation and publish-attempt outcome.
- No screen indicates that a mock publish is a real ServiceNow write.

### Phase 2 exit criteria

- Frontend production build succeeds.
- Route/navigation and basic UI component tests pass.
- Each screen can render representative states from local fixtures without a
  running ServiceNow instance.

## Phase 3: Feature implementation — one feature at a time

Implement each feature as a vertical slice: domain behavior, persistence/API,
UI, targeted tests, and documentation. Do not begin the next slice until its
milestone criteria pass.

### Milestone 3.1 — Team and roster configuration

- Provide the approved five-member development configuration and expose
  `GET /api/v1/team-members`.
- Add roster listing per A-01, with pagination and ownership filtering if the
  approved identity model requires it.
- Implement roster setup inputs and validate date ranges, unique member IDs,
  eligibility, time-zone identifiers, weekend definitions, and explicit
  holiday-date inputs.
- Persist an immutable snapshot of generation inputs needed for reproducible
  results, as approved by A-04/D-03.
- Reject or explicitly report unresolved required configuration rather than
  silently supplying defaults.

**Acceptance gate:** Setup and list flows pass API/UI tests; unknown/duplicate
members and invalid inputs receive clear errors; development fixtures are not
presented as real CPS identities.

### Milestone 3.2 — Scheduling domain and draft generation

- Implement pure scheduling-domain modules separately from Express, database,
  and ServiceNow adapters.
- Generate exactly a day and night shift for each configured local
  shift-start date.
- Derive actual instants from the approved time-zone interpretation.
- Enforce hard constraints: one primary per valid shift, eligible team
  membership, continuous coverage, no overlap, and at least 12 actual elapsed
  hours of rest.
- Optimize fairness in the approved order: total hours, night shifts, then
  weekend/holiday shifts. Use deterministic tie-breaking or persist the
  approved seed.
- Handle infeasibility according to the approved atomic-failure policy
  (DEC-003): report affected shifts and constraints, and never relax hard
  constraints.
- Persist successful generation outcome, shifts, and reproducibility inputs
  atomically. On infeasibility, persist no roster or partial assignments and
  return no roster ID.

**Acceptance gate:** Unit tests cover ordinary dates, period boundaries,
weekends/holidays, DST transitions for the approved zone, minimum-rest
boundaries, infeasible resource sets, deterministic output, and fairness
priority ordering.

### Milestone 3.3 — Roster detail, validation, and fairness

- Implement:
  - `GET /api/v1/rosters/{rosterId}`.
  - `GET /api/v1/rosters/{rosterId}/fairness` as a read-only operation.
  - `POST /api/v1/rosters/{rosterId}/validate`.
- Store validation runs/issues against a specific roster revision.
- Return structured issue codes, severity, messages, and affected assignment
  and member IDs.
- Display ordered assignments, per-member totals, visible imbalance, and
  validation findings in the review/fairness/validation screens.
- Prevent stale validation from qualifying a changed roster for approval or
  publishing.

**Acceptance gate:** A complete 42-day target period produces 84 shifts when
inputs permit; invalid or incomplete rosters remain visibly invalid; current
revision controls validation freshness.

### Milestone 3.4 — Draft assignment editing

- Implement `PATCH /api/v1/rosters/{rosterId}/assignments/{assignmentId}`.
- Allow changes only on drafts; apply an approved revision/optimistic
  concurrency check.
- Persist a well-formed edit according to the approved invalid-edit policy,
  increment revision atomically, invalidate prior validation/approval, then
  revalidate and recalculate fairness.
- Show the changed assignee and any resulting constraint failures in the UI.
- Reject edits to published rosters.

**Acceptance gate:** Valid reassignment updates fairness; invalid reassignment
is not silently discarded or marked valid; stale concurrent edits are
rejected without overwriting newer data.

### Milestone 3.5 — Review and approval lifecycle

- Implement the approved single-scrum-master review/approval model, including
  actor attribution and approval tied to the current roster revision.
- Approval is permitted only after current-revision validation passes all
  hard constraints.
- Any subsequent roster change invalidates approval and requires revalidation
  and reapproval.
- Add explicit UI indication and confirmation for approval.

**Acceptance gate:** Unreviewed, invalid, or stale drafts cannot be approved or
published; an approved state is auditable and tied to the approved revision.

### Milestone 3.6 — ServiceNow adapter boundary and prototype publish

- Define a transport-independent ServiceNow adapter interface.
- Implement a deterministic mock/simulator for local development and
  automated tests; identify all simulated outcomes as mock data.
- Implement publish-attempt persistence and the publish-result UI for
  confirmed mock success, failure, and uncertain outcomes.
- Gate the live adapter behind approved ServiceNow instance, API, auth,
  uniqueness/idempotency, and read-back/reconciliation decisions.
- Do not retry an uncertain non-idempotent create blindly.

**Acceptance gate:** Invalid or unapproved drafts cannot publish. Mock
outcomes are never represented as real external success. Live ServiceNow
writes remain disabled unless the integration decision gate is signed off.

## Phase 4: Integration and testing

### Work

- Integrate React screens with the versioned Express API and verify request,
  response, error, authorization, and revision behavior.
- Run migrations and the full local stack with PostgreSQL 15 using Docker
  Compose.
- Add end-to-end scenarios for configuration, generation, review, editing,
  validation, approval, and mock publish outcomes.
- Test hard constraints and edge cases, including missing settings, unfilled
  shifts, ineligible resources, overlapping assignments, less-than-12-hour
  rest, DST transitions, stale revisions, and failed/uncertain publication.
- Verify no notifications are sent and existing published rosters cannot be
  overwritten.
- Test safe configuration, secret redaction, authorization enforcement, and
  that routine tests do not call production Jira, Confluence, or ServiceNow.
- Run frontend lint/build/tests, backend lint/tests, migration tests, and
  end-to-end tests. Document any check that cannot run in the local
  environment.
- Update developer documentation with startup, migration, seed, test, and
  mock-versus-live integration instructions.

### Milestone 4.1 — Local integrated prototype

- A developer can start the local frontend, backend, and PostgreSQL services
  from documented instructions.
- A scrum master can configure a supported roster, generate it, review and
  edit a draft, validate and approve the current revision, and observe a
  clearly labelled mock publish result.

### Milestone 4.2 — Acceptance and regression suite

- Specification success criteria SC-001 through SC-009 have corresponding
  automated checks or documented manual acceptance evidence.
- All applicable automated tests pass; no hard constraint is skipped or
  downgraded.
- Failures and uncertain publish outcomes remain explicit from API through UI.

### Milestone 4.3 — Production integration readiness (conditional)

- Product/constitution scope is aligned.
- Time-zone, team, fairness, availability, and ServiceNow decisions are
  approved.
- ServiceNow sandbox credentials and required authorization are provided
  through an approved secret-management mechanism.
- The real adapter has explicit create-only semantics, success verification,
  duplicate prevention, and safe handling of ambiguous outcomes.
- Security and operational review is complete before enabling any production
  write path.

**This milestone does not authorize production deployment or live writes by
itself.** Those require separate approval and environment-specific validation.

## Milestone summary

| Milestone | Outcome | Depends on |
|---|---|---|
| 1.1 | Backend boots with safe API skeleton | Product/constitution scope (DEC-001) |
| 1.2 | PostgreSQL 15 and migrations run locally | Docker configuration |
| 1.3 | Approved logical schema and persistence boundary | Database ownership (DEC-002) |
| 2.1 | React/Vite app and routes run locally | API contract baseline |
| 2.2 | UI states and screen contracts are represented | Screen/API response mapping |
| 3.1 | Team, roster setup, and listing | Team and configuration policies |
| 3.2 | Deterministic constrained draft generation | Time zone, team, holiday, fairness decisions |
| 3.3 | Validation, fairness, and roster detail | Domain model and revision rule |
| 3.4 | Safe draft editing | Invalid-edit and concurrency policy |
| 3.5 | Review and approval lifecycle | Scrum-master identity/authorization |
| 3.6 | Mock ServiceNow publish boundary | Publish lifecycle; live integration remains gated |
| 4.1 | End-to-end local prototype | Phases 1–3 |
| 4.2 | Verified acceptance suite | Acceptance criteria and stable contracts |
| 4.3 | Production integration readiness | All external decisions and security approvals |

## Definition of done

A milestone is done only when its stated deliverables exist, its acceptance
gate passes, its relevant tests pass, and failures/known limitations are
recorded. No phase may mark a roster valid, approved, or published unless the
corresponding specification rules are verified for the current roster
revision. Unresolved owner decisions remain explicit blockers, not implied
defaults.
