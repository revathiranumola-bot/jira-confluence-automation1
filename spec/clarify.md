# Senior Specification Review: CPS On-Call Roster

**Reviewed documents:** [constitution.md](./constitution.md) and
[specification.md](./specification.md)

**Review purpose:** Identify material gaps, contradictions, and ambiguous
requirements and give each a disposition:

- **Answer — proposed detail to add to the specification:** A concrete
  spec-ready recommendation. It is a proposal, not a stakeholder-approved
  product decision. Confirm it before treating it as binding.
- **Out of scope — prototype:** Explicitly excluded from this prototype; do not
  implement unless a later approved specification brings it back in.

This review does not silently change the source requirements. Items that depend
on CPS, ServiceNow, or product-owner decisions remain blockers until confirmed.

## Executive summary

The feature spec is a useful functional baseline, but it is not implementation
ready. The most significant issues are:

1. The constitution describes **CPS Sprint Pulse / Jira and Confluence
   automation**, while this feature generates on-call rosters and publishes
   them to **ServiceNow**.
2. Production generation and publishing depend on unresolved time-zone, team,
   holiday, availability, ServiceNow API, and authorization decisions.
3. Roster and validation lifecycle rules do not yet define how a reviewed
   draft becomes approved or how validation is tied to the exact edited
   version.
4. The API lacks several operations implied by the UI and leaves HTTP/error
   behavior underspecified.
5. The logical PostgreSQL model does not yet fully enforce roster membership,
   eligible assignment, revision freshness, and publish-attempt integrity.

## 1. Cross-document scope and architecture

### C-01 — Product identity and integration do not match

**Impact:** Blocker. The constitution's purpose, target experience, and
integration principles concern Jira/Confluence and a sprint dashboard. The
feature spec concerns CPS shift scheduling and ServiceNow. It is unclear
whether this is one product, a separate feature in a shared repository, or
which specification is authoritative.

**Answer — proposed detail to add to the specification; owner confirmation
required:**

> This feature is the CPS On-Call Roster, a distinct workflow from the CPS
> Sprint Pulse Jira dashboard. It manages roster drafts and publishes new
> rosters to ServiceNow. Jira/Confluence dashboard functionality is not part
> of this feature. The project constitution must explicitly include or
> reference this ServiceNow feature before the constitution is treated as its
> governing project charter.

**Follow-up:** Confirm the product boundary and update the constitution's
project identity, target user, and permitted integrations, or explicitly
declare the roster feature out of scope for that project. Do not treat the
Jira/Confluence adapter guidance as a substitute for ServiceNow-specific
authorization and API decisions.

### C-02 — Folder convention differs from the existing skeleton

**Impact:** Medium. The constitution names `backend/src/integrations/` for
external adapters; the repository skeleton and feature work use
`backend/src/servicenow/`.

**Answer — proposed detail to add to the specification:**

> For this feature, implement the ServiceNow adapter under
> `backend/src/servicenow/`. This feature-specific directory is an explicit
> specialization of the constitution's external-integration boundary.
> Keep ServiceNow transport and field mapping out of scheduling/domain logic.

**Follow-up:** Align the constitution's folder examples with this convention,
or choose one shared `integrations/servicenow/` path before implementation.

### C-03 — Database ownership is not defined

**Impact:** High. The spec proposes PostgreSQL tables while also saying the
roster is maintained in ServiceNow. It does not establish whether PostgreSQL
is the authoritative roster store, a draft/workflow store, or a cache.

**Answer — proposed detail to add to the specification; owner confirmation
required:**

> PostgreSQL is the system of record for local roster drafts, edits,
> validation history, and publish attempts. ServiceNow is the destination
> system of record for the published roster. A roster is considered published
> locally only after the configured ServiceNow success confirmation has been
> received. The application stores the resulting ServiceNow identifier and
> does not mirror unrelated ServiceNow data.

If ServiceNow must instead be authoritative before publication, revise the
model and offline behavior accordingly.

## 2. Scheduling behavior

### S-01 — “CST” has two incompatible interpretations

**Impact:** Production blocker. A daylight-saving-aware regional zone and a
fixed UTC−6 offset produce different local-time behavior during part of the
year.

**Answer — proposed detail to add after the schedule owner decides:**

> Store the selected IANA time-zone identifier for the roster. Interpret
> shift boundaries as local wall-clock times in that zone, then convert each
> boundary to an actual instant. Do not interpret the abbreviation `CST` as
> sufficient configuration.

**Unresolved owner decision:** Choose the actual zone or fixed-offset policy.
Until confirmed, production generation and publishing for the target period
are blocked. A hard-coded `America/Chicago` answer would be an unsupported
assumption.

### S-02 — Daylight-saving transitions affect shift duration and fairness

**Impact:** High. “12-hour shift” is stated as a local-clock interval, while
the fairness objective is to balance assigned hours. A night shift across a
clock change can have a different elapsed duration.

**Answer — proposed detail to add:**

> Define shift boundaries from local wall-clock start/end times in the
> confirmed zone. Use actual elapsed duration between the resulting instants
> for assigned-hour fairness and 12-hour rest validation. Report local
> boundaries and elapsed duration when they differ. A daylight-saving
> transition does not by itself change the configured local shift boundary.

**Unresolved owner decision:** Confirm that “assigned hours” means actual
elapsed hours, not nominal 12-hour shift units.

### S-03 — Roster end date versus final night-shift end is implicit

**Impact:** High. A roster whose final shift starts on the inclusive end date
has a night assignment ending the following morning. The interval covered by
the roster is therefore not the same as the last shift's end instant.

**Answer — proposed detail to add:**

> `startDate` and `endDate` are inclusive local shift-start dates. Generate
> exactly two shifts for each date in that range. The final night's end is
> 09:00 local time on the calendar day after `endDate`. Use half-open
> intervals `[startsAt, endsAt)` when checking coverage, overlaps, and rest.

Confirm whether coverage after the last roster date is intended; if not,
specify a different final-night policy.

### S-04 — Fairness objective is qualitative

**Impact:** High. “As evenly as possible” does not specify the metric,
tolerance, solver behavior, or tie-break. “Weekend/holiday shifts” can mean one
combined bucket or two independent buckets.

**Answer — proposed detail to add, subject to product-owner confirmation:**

> Treat fairness as a lexicographic objective after all hard constraints are
> satisfied: (1) minimize the maximum-minus-minimum actual elapsed assigned
> hours across eligible roster members; (2) minimize the
> maximum-minus-minimum night-shift count; (3) minimize the
> maximum-minus-minimum count of shifts whose local start date is a weekend
> day or a configured holiday, counting a shift only once if both apply.
> Report weekend and holiday counts separately as diagnostics. Use a stable
> deterministic tie-break by member ID and shift start instant unless a
> persisted generation seed is supplied.

Clarify whether either of the last two counts must instead be a separate
fairness objective and whether fairness is measured only within one roster.

### S-05 — Exactly-one assignment conflicts with allowed unfilled drafts

**Impact:** High. FR-003 says every required shift MUST have exactly one
primary, but FR-005 and the proposed table allow an unfilled shift with a null
primary.

**Answer — proposed detail to add:**

> Every *valid* roster MUST have exactly one eligible primary per required
> shift. An incomplete draft MAY persist a shift with no primary so the
> coverage gap can be reviewed; that draft is invalid, cannot be approved or
> published, and MUST visibly identify the unfilled shift. Duplicate
> assignments for the same roster/date/type are not permitted.

### S-06 — Five-person team and configurable membership need a rule

**Impact:** Medium. The requirement says five configured members, while the
API accepts an arbitrary list of IDs. Behavior for fewer, more, duplicate, or
ineligible members is unspecified.

**Answer — proposed detail to add, subject to owner confirmation:**

> A production roster uses exactly the five CPS members approved for the
> roster. Reject duplicate member IDs and unknown IDs. Require at least one
> eligible member and report infeasible coverage rather than silently
> relaxing rest or eligibility constraints. Do not invent member identities
> or eligibility.

Confirm whether five is a fixed invariant or merely the expected initial team
size.

### S-07 — Availability and preferences are open but their absence is unclear

**Impact:** High if availability data is expected. The spec both calls out
availability as unresolved and says the generator must not assign an
unavailable person.

**Answer — proposed detail to add for this prototype:**

> Availability, leave, and shift preferences are not collected or evaluated
> in this prototype. The application makes no claim that generated shifts
> respect personal availability. Do not import or infer availability from
> another system. Adding availability constraints requires a separately
> approved policy and specification.

**Out of scope — prototype:** Availability/preferences UI, ingestion, and
optimization.

### S-08 — Generation infeasibility and partial-draft behavior need definition

**Impact:** High. The spec says the system identifies unfilled shifts but
does not say whether it saves a partial draft, aborts the operation, or
returns a roster ID.

**Answer — proposed detail to add:**

> Persist a draft and its per-shift assignments even when the generator cannot
> fill every shift, provided persistence succeeds. Return the roster ID with
> `generationStatus: "incomplete"` and structured validation issues. Such a
> roster is not valid, cannot be approved or published, and is not described
> as successfully generated. If the draft itself cannot be persisted, return
> an error and no roster ID.

Confirm whether partial drafts are useful to the scrum master; otherwise mark
partial-draft persistence out of scope and fail generation atomically.

### S-09 — Shift capacity and feasibility have no defined guarantee

**Impact:** Medium. The system requires full coverage and 12 hours of rest but
does not specify behavior if the constraints cannot be jointly satisfied.

**Answer — proposed detail to add:**

> Coverage, eligibility, non-overlap, and 12 hours of rest are hard
> constraints; fairness is optimized only among feasible assignments. The
> generator MUST NOT relax hard constraints to improve fairness. If no
> complete assignment exists, report infeasibility and the implicated
> resources/shifts. Do not assume a maximum-consecutive-shift rule.

This resolves constraint priority but not whether the chosen five-person
configuration is feasible; that must be tested by the generator.

## 3. Lifecycle, API, and UI

### L-01 — Approval is used but not modeled

**Impact:** High. The publish endpoint accepts a “valid, reviewed” draft, but
there is no approval action, approval record, reviewer identity, or way to
distinguish reviewed from unreviewed drafts. The scrum master is the known
reviewer/publisher, but login and authorization are unspecified.

**Answer — proposed detail to add:**

> For the single-user prototype, only the configured scrum-master identity
> may review, edit, approve, or publish. Persist `approved_by`,
> `approved_at`, and the roster revision approved. Approval is allowed only
> when the latest validation for that same revision passes every hard check.
> Any later edit clears approval and requires validation and approval again.

This requires an owner decision on how the prototype identity is configured.
Do not implement broad multi-role administration until roles are defined.

### L-02 — Invalid edits may be persisted or rejected

**Impact:** Medium. “Do not silently discard an edit” conflicts with the
unspecified behavior of the PATCH request when the new assignee creates a hard
violation.

**Answer — proposed detail to add:**

> Persist a syntactically valid assignee change to the draft even if it causes
> a scheduling violation; increment the roster revision, invalidate prior
> approval, run validation, and return the updated assignment plus the
> resulting invalid status and issues. Do not persist malformed requests or
> changes to a published roster. Publishing remains blocked until the current
> revision passes validation and is approved.

If invalid intermediate edits must never be saved, provide an explicit
preview/commit workflow instead; the current API does not define one.

### L-03 — Roster states do not represent validation and publication attempts

**Impact:** High. `draft`/`published` alone cannot describe incomplete/invalid
drafts, stale validation, or failed/uncertain ServiceNow attempts.

**Answer — proposed detail to add:**

> Keep lifecycle state separate from validation and publication outcome.
> `rosters.status` is `draft` or `published`; validation has its own result
> for a specific roster revision; each publish attempt has its own
> `pending`, `succeeded`, `failed`, or `uncertain` outcome. An invalid draft
> remains a draft. A failed or uncertain attempt does not make it published.

The UI/API MUST expose these dimensions together so that `draft` alone is not
mistaken for valid.

### A-01 — API cannot list rosters or configure members

**Impact:** High for the described UI. The UI needs to show existing drafts,
but only a roster-by-ID GET is defined. The setup UI also collects team
members, but no API operation creates or configures them.

**Answer — proposed detail to add for the prototype:**

> Add `GET /api/v1/rosters?status=draft&limit={n}&cursor={cursor}` to list
> the current user's rosters, ordered by most recently updated, with opaque
> pagination. Seed the five team members from local development configuration
> and expose them through `GET /api/v1/team-members`; do not add member CRUD
> in this prototype. Add team administration only after its owner and
> authorization policy are specified.

If the roster is single-user-only, specify that list filtering is by the
configured roster owner.

### A-02 — Fairness GET endpoint can mutate state

**Impact:** Medium. `GET /fairness` says “retrieve or recalculate,” but GET
should be safe and not create validation/audit side effects.

**Answer — proposed detail to add:**

> `GET /api/v1/rosters/{rosterId}/fairness` is read-only and returns fairness
> for the current roster revision, calculating a deterministic response
> without mutating persisted state. Persisted validation is performed only by
> the POST validation operation. A stale or unavailable result is identified
> explicitly.

### A-03 — API response, HTTP status, and concurrency behavior are incomplete

**Impact:** Medium. The API lists fields but not a stable envelope, validation
semantics, or behavior when two edits race.

**Answer — proposed detail to add:**

> Return JSON with a documented success or error shape and stable error
> codes. Use `400` for malformed syntax, `401` for unauthenticated,
> `403` for unauthorized, `404` for unknown IDs, `409` for lifecycle or
> revision conflicts, and `422` for well-formed input that fails domain
> validation. Include a `rosterRevision` on roster responses. Require
> `If-Match` with the revision on PATCH, approve, and publish; reject stale
> writes with `409` and make no changes.

Confirm whether a shared response envelope and the standard status mapping
match the existing backend conventions before freezing the API.

### A-04 — Configuration inputs and holiday data lack a source/validation rule

**Impact:** High. `holidayCalendarId` and `weekendDefinition` are accepted by
the draft endpoint, but no calendar source, allowed values, date format for
holidays, or persistence behavior is described.

**Answer — proposed detail to add for this prototype:**

> Supply weekend days and holiday local dates explicitly in the roster
> generation request or a versioned local configuration. Validate the date
> format and persist an immutable snapshot with the roster so its fairness
> results are reproducible. Do not fetch or infer a government/company
> holiday calendar.

**Out of scope — prototype:** External holiday calendar discovery, automatic
calendar synchronization, and management UI. The schedule owner must provide
the region and holiday dates before production fairness results are claimed.

### A-05 — Publish success and uncertain external outcomes lack a protocol

**Impact:** Blocker for live integration. The spec requires a confirmed result
and no duplicate roster, but has no read-back, idempotency, timeout, partial
failure, or reconciliation policy. A timeout can occur after ServiceNow
created the roster.

**Answer — proposed detail to add:**

> A publish attempt is recorded before the external call. Do not retry a
> non-idempotent create after an ambiguous timeout until the ServiceNow
> outcome is reconciled. Mark the attempt `uncertain`, keep the roster
> unpublished, and require safe reconciliation before another create. Mark
> success only from the integration's explicitly approved confirmation
> mechanism.

**Out of scope — prototype:** Production ServiceNow writes and automatic
retry/reconciliation until the instance, API, auth, uniqueness key, and
confirmation/read-back behavior are specified. Use a clearly labelled
simulator/mock adapter for end-to-end prototype demonstrations; never show a
mock result as a real ServiceNow publish.

### A-06 — API security requirements have no prototype identity contract

**Impact:** High before real writes. The constitution requires authorization,
but the spec does not say how a scrum-master session is authenticated, where
actor IDs originate, or whether local/demo endpoints are protected.

**Answer — proposed detail to add for the prototype:**

> No live ServiceNow credentials or production access are used in the
> prototype. Use a documented local-development identity only for local
> demonstrations and tests. Do not expose the API beyond the development
> environment under a trusted-header or unauthenticated production
> configuration. Before deployment or live integration, specify the identity
> provider, session/token handling, role mapping, and CSRF/CORS policy.

**Out of scope — prototype:** Enterprise SSO, multi-user role administration,
and production identity-provider integration. These remain release blockers
for any deployment with real roster or ServiceNow access.

## 4. Data model and integrity

### D-01 — Validation freshness cannot be enforced with the current tables

**Impact:** High. The specification says validation applies to the current
revision, but neither `rosters` nor `validation_runs` defines a revision
number or a relationship that proves freshness.

**Answer — proposed detail to add:**

> Add monotonically increasing `rosters.revision`, incremented atomically by
> every roster configuration or assignment edit. Store
> `validation_runs.roster_revision`; a roster may be approved or published
> only when the latest successful validation has the current revision. Store
> `approved_revision` with approval. Publish attempts also record the
> revision they attempted to publish.

### D-02 — Foreign keys do not guarantee an assignee is eligible for that roster

**Impact:** High. A `primary_member_id` FK to `team_members` alone can point to
a member who is not in `roster_members` or whose roster eligibility snapshot
is false.

**Answer — proposed detail to add:**

> Enforce that each non-null assignment primary references a member included
> in that roster's membership snapshot and eligible for that roster. Use a
> composite database constraint/foreign key where practical, with the same
> rule also enforced by domain validation. Keep current team eligibility
> distinct from the immutable eligibility snapshot used by a generated
> roster.

### D-03 — Persisted configuration and audit fields need concrete shapes

**Impact:** Medium. The model has calendar IDs, actor IDs, diagnostics, and
before/after metadata without saying whether these are internal IDs or
external values, what is snapshotted, or how sensitive content is limited.

**Answer — proposed detail to add:**

> Persist the exact generation inputs needed to reproduce and review a roster:
> dates, confirmed time-zone ID, member eligibility snapshot, weekend days,
> holiday local dates/source label, fairness rule version, and generation
> seed/configuration. Store actors as application identity IDs, not display
> names alone. Keep audit before/after data to roster/assignment fields
> required to explain changes; exclude tokens and unnecessary external
> content. Define retention and deletion policy before production deployment.

**Out of scope — prototype:** Automated audit-log retention/deletion tooling
and legal/compliance retention guarantees until the organization's policy is
provided.

### D-04 — Duplicate date/type uniqueness and overlap rules need consistent scope

**Impact:** Medium. Unique `(roster_id, shift_date, shift_type)` prevents
duplicate shift keys, but cannot alone enforce coverage interval continuity,
assignment/member eligibility, or overlap/rest across a roster.

**Answer — proposed detail to add:**

> Keep the unique shift key at the database boundary. Enforce interval
> continuity, per-member overlaps, and minimum rest in one authoritative
> domain validation service over all assignments in the current roster
> revision. Perform edit-plus-revision update atomically. Publish only after
> this complete validation succeeds.

### D-05 — Database persistence after prototype restart is implied, not tested

**Impact:** Medium. The database is specified, but persistence expectations,
backup, reset, and migration lifecycle are absent.

**Answer — proposed detail to add for the prototype:**

> Persist drafts and history in PostgreSQL 15 across application restarts.
> Apply schema using versioned migrations. Local demo/reset scripts may delete
> only explicitly identified local data and must require an explicit
> developer action.

**Out of scope — prototype:** Production backup/restore, high availability,
disaster recovery, and retention SLAs; define these before production use.

## 5. Explicit prototype exclusions

These recommendations keep unresolved or unrequested capabilities from being
silently invented. Confirm the prototype boundary before marking the feature
spec approved.

| Capability | Prototype disposition |
|---|---|
| Live ServiceNow create/update calls | **Out of scope** until integration details and authorization are approved. Use a clearly labelled mock only. |
| Updating or overwriting an already-published roster | **Out of scope**; already excluded by the feature spec. |
| Notifications and reminders | **Out of scope**; no reminders or change notifications. |
| Backup/secondary assignments | **Out of scope**; one primary only. |
| Availability, leave, and shift preferences | **Out of scope** until policy is approved. |
| Maximum-consecutive-shift rule | **Out of scope**; do not invent a limit. |
| Team-member administration UI/API | **Out of scope**; use explicitly configured development seed data. |
| External holiday calendar integration | **Out of scope**; require explicit calendar inputs. |
| SSO and multi-role administration | **Out of scope** for local demo; mandatory decisions before deployment or real external writes. |
| Deployment SLA, high availability, disaster recovery, and audit retention guarantees | **Out of scope** for prototype; define before production. |
| Jira/Confluence sprint-dashboard workflows | **Out of scope for this roster feature** unless product ownership confirms a single combined application. |

## 6. Recommended clarification order

Resolve these before implementation, in order:

1. Confirm the product boundary against the constitution (C-01), whether the
   on-call roster is in the Jira/Confluence automation product, and whether
   real ServiceNow writes are in the prototype.
2. Confirm the time-zone interpretation, inclusive end-date/final night
   behavior, and elapsed-hours fairness (S-01–S-03).
3. Confirm team identities/eligibility and weekend/holiday/fairness policy
   (S-04–S-07).
4. Approve lifecycle, reviewer identity, and prototype authentication
   (L-01–L-03, A-06).
5. Confirm ServiceNow API, unique-create strategy, success verification, and
   partial-outcome reconciliation before removing the live-write exclusion
   (A-05).
6. Update API and database requirements with list/configuration operations,
   revision concurrency, eligible membership constraints, and snapshots
   (A-01–A-04, D-01–D-05).

Until the first five product/integration decisions are resolved, any
implementation must remain a local prototype and must not claim to provide a
production-ready on-call publishing workflow.
