# Implementation Task Analysis: CPS On-Call Roster

**Reviewed artifacts:** [constitution.md](./constitution.md),
[specification.md](./specification.md), [plan.md](./plan.md),
[tasks.md](./tasks.md), [clarify.md](./clarify.md), and
[decisions.md](./decisions.md).

**Purpose:** Assess the complexity, dependencies, and material risks for every
implementation task, then identify cross-document gaps and contradictions
before work starts. The original analysis predates BE-01 completion; the
post-BE-01 status below supersedes affected pre-decision observations.

## Assessment conventions

- **Low:** bounded setup or documentation work with few domain decisions.
- **Medium:** multiple interfaces, persistence, or failure cases, but
  established patterns can keep scope contained.
- **High:** correctness-critical domain logic, unresolved product decisions,
  external side effects, concurrency, or security boundaries.
- Dependencies below include task dependencies and important decision gates.
  Any proposed resolution in `clarify.md` remains a recommendation until the
  owner approves it. BE-01 decisions have since been approved and recorded in
  `decisions.md`.

## Post-BE-01 status update (2026-10-19)

- BE-01 is complete: product scope, local data ownership, atomic infeasible
  generation, localhost-only prototype identity, and mock-only publishing are
  recorded in `decisions.md`.
- The constitution now governs the distinct Sprint Pulse and On-Call Roster
  features. The C-01 scope mismatch is resolved for the prototype.
- Prototype publishing is explicitly simulated and makes no ServiceNow calls;
  this neither satisfies nor authorizes future live integration.
- C-03 and S-08 are resolved for the prototype. Scheduling rules, lifecycle
  details, and production integration decisions remain open.
- Task-level risk notes below that describe these BE-01 choices as unresolved
  are historical and superseded by this update.

## Summary

- **High complexity:** 15 tasks; **Medium:** 14 tasks; **Low:** 3 tasks.
- The critical path is remaining scheduling policy decisions → backend/database
  foundation → time-zone-aware scheduling and validation → revision-safe
  editing/approval → mock publish → end-to-end acceptance.
- Live ServiceNow publishing is not a safe prototype dependency until
  integration, identity, duplicate prevention, and ambiguous-outcome handling
  are approved.
- The former product-scope mismatch is resolved for the prototype; scheduling
  policy and production integration remain gated.

## Phase 1 — Backend setup

| Task | Complexity | Dependencies and decision gates | Main risks |
|---|---|---|---|
| **BE-01 — Resolve backend implementation gates** | High | C-01, C-03, A-05, A-06, S-08; now recorded in `decisions.md`. | Decision-heavy gate is complete for the prototype. It does not resolve remaining production integration/security approvals or separate scheduling rules. |
| **BE-02 — Initialize the Express backend package** | Medium | BE-01; product scope is confirmed, but only a local prototype is authorized. | Lockfile/runtime compatibility, missing package scripts, and ensuring development configuration cannot enable live writes remain risks. |
| **BE-03 — Add Express application and health routes** | Low | BE-02; database wiring from BE-05/BE-07 for true readiness. | Readiness can be confused with liveness if DB dependency behavior is implemented later. Test the app factory independently and distinguish DB readiness from process health. |
| **BE-04 — Establish request validation and API error conventions** | Medium | BE-03; align with A-03 and the eventual frontend contract. | Error status mapping, envelopes, and domain-validation behavior are proposals in `clarify.md`, not approved API decisions. No API schema artifact currently captures these contracts. |
| **BE-05 — Add local Docker Compose PostgreSQL 15 service** | Medium | BE-01; root Compose file and local secret/configuration policy. | Compose setup can accidentally expose weak credentials, persist unintended data, or add destructive reset behavior. Docker Desktop is installed in this environment, but its engine was previously unavailable because WSL 2 setup was unfinished; actual Compose runtime validation may be blocked until Docker is operational. |
| **BE-06 — Select and configure a migration tool** | Medium | BE-02, BE-05. | Tool choice is delegated to implementation with no decision criteria, upgrade policy, or artifact documenting the selection. Migration ordering, rollback expectations, and test isolation are not fully specified. |
| **BE-07 — Define PostgreSQL repository and migration schema** | High | BE-01, BE-06; C-03 resolved for prototype, D-01–D-03 and lifecycle decisions remain. | Revision, approval, membership integrity, and audit details remain open. Atomic failure on infeasible generation is now settled. A simple FK does not enforce roster-eligible membership, and `draft`/`published` alone cannot encode validation, approval, or uncertain publication. |
| **BE-08 — Add backend configuration validation** | Medium | BE-02, BE-05. | Mode selection must fail safely: a mistaken environment setting must not turn a mock into a live ServiceNow adapter or permit unauthenticated access. No canonical environment-variable list or `.env.example` artifact is required explicitly. |
| **BE-09 — Add isolated backend and database test harness** | Medium | BE-06, BE-07; isolated test database. | Test cleanup must never point at a developer/production database. The task says to identify a dedicated DB but does not require a destructive-operation guard or test connection-name allowlist. |

## Phase 2 — Frontend setup

| Task | Complexity | Dependencies and decision gates | Main risks |
|---|---|---|---|
| **FE-01 — Initialize React/Vite frontend package** | Medium | BE-01 product scope is resolved; may proceed with mock contracts. | Vite/plugin/runtime versions are pinned in the constitution but can change; lockfile and Node compatibility must agree. Constitution says JavaScript unless TypeScript is approved, while FE-04 asks for “types.” |
| **FE-02 — Create application shell and route structure** | Low | FE-01; screen inventory from the specification. | The plan calls for a roster-list route absent from the specification’s explicit API table. Without a route/API contract, the screen may become a fixture-only dead end. |
| **FE-03 — Add reusable screen state and accessibility primitives** | Medium | FE-02; UX/error semantics from the specification. | “Accessible” is not tied to a measurable standard or automated checks. Lifecycle, validation, and simulated-publish states can be accidentally collapsed into one status indicator. |
| **FE-04 — Define frontend API client and domain types** | Medium | FE-01, BE-04; requires stable response/error contract. | Backend API envelope and auth behavior are still undecided. Static “types” conflict with the JavaScript-only default unless represented with JSDoc/schema validation or TypeScript is explicitly approved. |

## Phase 3 — Feature implementation

| Task | Complexity | Dependencies and decision gates | Main risks |
|---|---|---|---|
| **FT-01 — Configure development team members** | Medium | BE-07, BE-08; owner-supplied member identities/eligibility or fictional fixtures. | “Approved five-person development configuration” could be mistaken for real CPS data. The test-only fixture policy must be explicit; no member CRUD is in scope. |
| **FT-02 — Create and list draft rosters** | High | BE-07, BE-08, FT-01; A-01, A-04, D-03; prototype identity/ownership recorded in DEC-002/004. | It combines listing, input validation, snapshotting, and draft creation. `POST /drafts` is also implemented by FT-06, so task ownership of the route is ambiguous. Pagination, authorization scope, response shape, and behavior for unresolved scheduling inputs need a stable contract. |
| **FT-03 — Implement time-zone-aware shift construction** | High | FT-02; blocked on S-01–S-03. | DST gaps/folds, local dates versus UTC instants, the inclusive final night, fixed offset versus regional zone, and elapsed-hours fairness all affect correctness. A timezone-database update can alter future calculations unless version/reproducibility requirements are defined. |
| **FT-04 — Implement scheduling hard-constraint validator** | High | FT-03; approved eligibility and interval semantics, including S-03/S-06. | Must validate interval-level coverage, duplicates, null assignees, eligibility snapshots, overlaps, and exact 12-hour rest. Database uniqueness alone cannot establish these global properties. |
| **FT-05 — Implement fairness metrics and ordered optimizer** | High | Stated: FT-03, FT-04; blocked on S-04 and S-05. Additional relevant gates: S-02 and A-04. | Fairness is not mathematically fixed. The task incorrectly cites **S-05** as a fairness decision; S-05 is the exactly-one/unfilled-draft rule, while fairness is primarily S-04 and actual elapsed hours are S-02. Holiday/weekend counting is in A-04. A solver may be computationally expensive or fail to guarantee a global optimum; no algorithm/size bound is specified. |
| **FT-06 — Generate and persist a draft** | High | FT-02, FT-04, FT-05, BE-07; S-08 resolved to atomic failure (DEC-003). | Implement transaction rollback and return no roster ID on infeasibility. Since FT-02 also owns `POST /drafts`, separate configuration/persistence responsibilities from scheduling orchestration. No request idempotency or duplicate-generation behavior is defined. |
| **FT-07 — Retrieve roster detail and fairness summary** | Medium | FT-06, FE-04; stable roster, validation, and publish response shapes. | Roster detail promises current validation and publish outcome but the spec does not define the combined response envelope or behavior when results are stale/missing. Fairness GET must be read-only per A-02. |
| **FT-08 — Persist current-revision validation runs** | Medium | FT-04, BE-07, D-01; UI surfaced in IT-01. | `validation_runs.roster_revision` is a recommendation, not present in the original model. Revalidation and roster edits must be transactionally ordered to avoid approving stale results. |
| **FT-09 — Edit draft assignment with revision protection** | High | FT-07, FT-08, L-02, A-03, D-01; frontend editing flow. | Invalid-edit behavior (persist-and-show-invalid versus reject) is unresolved. `If-Match` is proposed but no endpoint contract formally adopts it. Revision increment, assignment update, audit event, validation invalidation, and approval invalidation need atomic semantics. |
| **FT-10 — Add review and approval lifecycle** | High | FT-08, FT-09, L-01/L-03; use the local-only prototype identity in DEC-004. | The feature spec has no approval endpoint or explicit approval FR despite referring to an approved roster. Production actor authentication and authorization remain unresolved; local identity must not be represented as production auth. |
| **FT-11 — Implement ServiceNow adapter contract and mock** | Medium | BE-01, FT-10, A-05. | Mock semantics must remain unmistakable and must not accidentally be selected in production or claim real persistence. The adapter contract lacks a versioned payload/result schema until the ServiceNow integration is known. |
| **FT-12 — Publish approved draft through the mock** | High | FT-10, FT-11, BE-07; approved lifecycle and attempt model; mock-only boundary DEC-005. | Prototype SC-007 now explicitly requires a simulated result, not actual ServiceNow creation. Publish-attempt idempotency and uncertain outcomes need testing; live read-back and duplicate prevention remain production gates. |

## Phase 4 — Integration and testing

| Task | Complexity | Dependencies and decision gates | Main risks |
|---|---|---|---|
| **IT-01 — Integrate frontend with backend API** | High | FE-04, FT-02, FT-07–FT-12. | This broad integration task may discover incompatible response shapes late. It also treats all feature slices as predecessors, so it does not itself support the plan’s incremental vertical-slice testing unless targeted integration happens earlier. |
| **IT-02 — Run migrations and full local stack from clean state** | Medium | BE-05–BE-09, FE-01; transitively BE-02–BE-04. | “Clean state” can imply destructive data deletion; explicitly require a disposable database/volume. Docker engine/WSL availability is an environmental prerequisite. |
| **IT-03 — Add end-to-end workflow tests** | High | IT-01, IT-02, FT-12. | E2E assertions use a “feasible 42-day fixture,” but the spec does not supply a member fixture, zone, holiday calendar, or expected schedule. Mock publish must not satisfy or be reported as SC-007 live integration. |
| **IT-04 — Verify scheduling edge cases and acceptance criteria** | High | FT-03–FT-08, IT-03. | SC-001 and SC-004 depend on unresolved scheduling policies; tests can only be marked blocked or use approved deterministic fixtures. Prototype SC-007 is mock-only, while production ServiceNow acceptance remains separate. The exact fairness optimum and holiday fixture are not frozen. |
| **IT-05 — Verify security and failure handling** | High | BE-04, BE-08, FT-10–FT-12; approved prototype identity policy. | Authorization, CORS/CSRF, session/token handling, logging redaction, and threat boundary are incomplete. Testing only the mock cannot establish production ServiceNow safety. |
| **IT-06 — Complete developer documentation** | Low | IT-02, IT-03, IT-05. | Documentation can become stale if command names, migration tool, environment variables, or mock/live boundary remain undecided. |
| **IT-07 — Production integration readiness gate** | High | BE-01, S-01–S-07, L-01, A-05/A-06, D-01–D-03, IT-04–IT-06. | The task is a readiness checklist, not implementation of a production adapter or deployment. It requires a Sandbox contract and security review, but does not define approvers/evidence location. Requiring an availability decision can over-block production if availability is explicitly excluded. Passing it does not authorize deployment. |

## Cross-document gaps, contradictions, and missing artifacts

### Blockers and contradictions

1. **Constitution/product mismatch (C-01) — resolved for prototype:** The
   roster is a distinct feature under the CPS Automation Prototypes umbrella;
   the constitution now covers both workflows. The separate ServiceNow
   production integration remains gated.
2. **External adapter directory mismatch (C-02):** Constitution says
   `backend/src/integrations/`; the skeleton and analysis use
   `backend/src/servicenow/`. Pick one convention or document the specialization.
3. **Backend task gate conflict:** BE-02 permits a local scaffold, while
   BE-01's product-scope gate is now complete. Keep the boundary explicit:
   local prototype work is authorized; production integration is not.
4. **State/approval mismatch:** Specification and data model define only
   `draft`/`published`, but story/API/publish semantics require “reviewed” and
   “approved.” Approval endpoint, approval revision, actor, and status
   transitions are absent from the application API table and FR list.
5. **Mock versus live acceptance mismatch — resolved for prototype:** SC-007
   now verifies simulated publishing without ServiceNow calls. Actual
   ServiceNow creation remains a separate production criterion and approval
   gate.
6. **Availability policy conflict:** Specification says availability is
   undecided and must not be assumed; constitution review suggests
   availability may be out of scope, while the plan/IT-07 asks that
   availability be approved. Either explicitly exclude it for the prototype
   and remove it as a readiness dependency, or define the policy.
7. **Fairness reference mismatch:** FT-05 says blocked on S-04 and S-05.
   S-05 concerns exactly-one assignment/unfilled drafts, not the fairness
   objective. Fairness also depends on actual-hours semantics (S-02) and
   holiday input/counting (A-04).
8. **API-route ownership overlap:** FT-02 and FT-06 both implement
   `POST /api/v1/rosters/drafts`. Define who owns request validation,
   orchestration, persistence, and transactional generation.
9. **Roster end boundary:** Specification counts inclusive start dates but
   does not explicitly settle the final night extending into the day after
   `endDate`; clarify before test fixtures or API validation are frozen.
10. **Persistence authority (C-03) — resolved for prototype:** PostgreSQL owns
    local workflow state; ServiceNow owns the published roster only after
    separately approved live integration confirms publication.

### API and behavior artifacts to add or approve

- **OpenAPI/API contract artifact:** Freeze request/response schemas,
  error envelope/status mapping, pagination, auth requirements, revision/ETag
  behavior, and idempotency behavior. `clarify.md` proposes some of these,
  but neither `specification.md` nor `tasks.md` makes an approved contract a
  prerequisite artifact.
- **Approval API:** Add a documented approval endpoint/action and acceptance
  criteria tied to current-revision validation and the approved identity.
- **Roster-list API:** Plan/tasks add `GET /api/v1/rosters`, but the
  specification endpoint table omits it. Include its query, ordering,
  ownership filter, and pagination semantics.
- **Team setup source:** Specify how the five members enter the prototype:
  seed/configuration only versus admin UI/API. FT-01 implies seed-only but
  calls them “approved” even though actual identities are unavailable.
- **Draft-generation idempotency contract:** Atomic failure with no roster ID
  on infeasibility is approved (DEC-003); define duplicate successful
  submission behavior and request idempotency.
- **Publish state protocol:** Define when an attempt becomes pending,
  succeeded, failed, or uncertain, and what confirmation is sufficient.
  Separate mock behavior from live ServiceNow acceptance.

### Data-model artifacts and integrity rules

- Add a versioned logical/physical schema or ER diagram before migrations;
  `specification.md` only provides entity tables at a proposal level.
- Ensure a roster assignment can reference only a member in that roster's
  eligible membership snapshot, not merely any `team_members` row.
- Define `revision`, `approved_revision`, `validation_runs.roster_revision`,
  `publish_attempts.roster_revision`, and transaction boundaries together.
- Persist configuration snapshots needed for deterministic generation:
  zone identifier and relevant timezone data/version policy, holiday dates,
  weekend days, fairness rule version, eligible-member snapshot, and seed.
- Define constraints/indexes for null/unfilled assignments, state transitions,
  and external roster references. Unique shift keys alone do not enforce
  continuous coverage, overlap, or minimum rest.
- Define audit event shape and retention policy before production; prototype
  retention/SLA guarantees can be marked out of scope.

### Planning and delivery artifacts

- The BE-01 decision log now exists. Record later owner decisions and ADRs
  there; clarification recommendations remain unapproved unless individually
  confirmed.
- Add an `.env.example` and secret-handling instructions; BE-08 currently has
  no canonical variable list or artifact.
- Add a CI workflow/artifact that runs frontend/backend lint, tests, builds,
  migrations, and appropriate security checks. Constitution demands checks,
  but no task owns CI.
- Add explicit API contract tests or a mocked server contract fixture so FE
  and BE can proceed in parallel without incompatible assumptions.
- Define a supported browser/accessibility target and measurable accessibility
  acceptance criterion; current wording only says “accessible.”
- Name a prototype data/reset policy and prove destructive reset commands
  target only disposable local data.
- Define migration selection and local runbook artifact (BE-06/IT-06), but
  avoid choosing a tool without agreement if the project has an existing
  convention.
- Add owner/priority/estimate fields to tasks if this file will be used as a
  delivery backlog; complexity analysis here is not a schedule estimate.

## Recommended dependency corrections

1. Correct FT-05 dependencies to include S-02, S-04, and A-04; retain S-05
   only where assignment completeness or incomplete-draft semantics affect
   calculations.
2. Make FT-02 own roster/list/configuration API and request validation; make
   FT-06 own only the generation orchestration and transactional draft result,
   or otherwise document the single task boundary.
3. Add an explicit approval endpoint/API artifact before FT-10 and make
   FT-12 depend on it.
4. Add acceptance for the roster-list route from FE-02/FT-02 to
   `specification.md`.
5. Tie all edit/approve/publish operations to one approved revision contract
   and add explicit atomicity tests.
6. Make Phase 4 integration/testing incremental per vertical slice, then keep
   a final E2E/regression milestone, rather than postponing all integration
   until every slice is complete.
7. Keep IT-07 conditional and separate from prototype completion; explicitly
   state which unresolved decisions are waived because a capability is
   out-of-scope versus which block production.

## Readiness recommendation

The plan and tasks are suitable as a **prototype planning baseline**. BE-01's
product and safety boundaries are now recorded; add owner decisions and
API/state/data artifacts before corresponding implementation slices begin.
Do not begin time-zone-sensitive generation or production
approval/publishing with unresolved assumptions. Resolve the remaining
scheduling semantics, then lifecycle/API/data contracts. Use the mock adapter
for local demonstrations; live integration still requires a separately
approved contract and authorization review.
