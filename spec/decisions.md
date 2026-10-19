# Product and Implementation Decision Log

**Project:** CPS Automation Prototypes
**Decision record date:** 2026-10-19
**Decision owner:** Product owner (confirmed by the user for this prototype)

This log records decisions for implementation task BE-01. The decisions below
approve prototype boundaries only; they do not resolve the remaining
scheduling rules or authorize production deployment or live ServiceNow access.

## BE-01 decisions

### DEC-001 — Product boundary and constitution applicability

- **Status:** Approved
- **Clarification:** C-01
- **Decision:** CPS On-Call Roster is a distinct feature in this repository,
  separate from the CPS Sprint Pulse Jira/Confluence dashboard. The
  constitution applies to both workflows and identifies them separately.
- **Rationale:** This preserves the independent requirements and integration
  boundaries while establishing one governing set of project principles.
- **Recorded change:** The constitution now names CPS Automation Prototypes as
  the umbrella and includes both features.

### DEC-002 — PostgreSQL and ServiceNow data ownership

- **Status:** Approved
- **Clarification:** C-03
- **Decision:** PostgreSQL is the system of record for local roster drafts,
  edits, validation history, and publish attempts. ServiceNow is the
  destination system of record for a roster only after a separately approved
  live integration confirms publication. The prototype does not mirror
  unrelated ServiceNow data.
- **Rationale:** Local workflow state remains available without treating
  unconfirmed external effects as published.

### DEC-003 — Infeasible generation and partial drafts

- **Status:** Approved
- **Clarification:** S-08
- **Decision:** Generation fails atomically when it cannot fill every required
  shift or satisfy a hard constraint. It persists no roster or partial
  assignment set and returns no roster ID. A partial-draft workflow would
  require a later approved change.
- **Rationale:** A failed generation cannot leave a misleading or ambiguous
  draft in persistent storage.

### DEC-004 — Prototype identity boundary

- **Status:** Approved
- **Clarification:** A-06
- **Decision:** Local demonstrations and tests may use a documented
  local-development identity. The backend must bind only to localhost for
  this prototype. This identity is not production authentication or
  authorization, and does not permit deployment or real roster access.
  Production identity-provider, role, session, and related security decisions
  remain required before deployment or live integration.
- **Rationale:** The prototype can exercise local workflow attribution without
  implying enterprise identity or production security readiness.

### DEC-005 — Prototype publishing boundary

- **Status:** Approved
- **Clarification:** A-05
- **Decision:** Publishing is mock-only. The prototype must not include or
  enable live ServiceNow writes or use live ServiceNow credentials. Mock
  outcomes must be clearly identified as simulated. A production adapter,
  reconciliation protocol, and live-write approval require a separate
  decision gate.
- **Rationale:** ServiceNow instance/API/authentication and safe
  duplicate/uncertain-outcome handling are not defined.

## Scope of these decisions

These decisions resolve the BE-01 acceptance criteria. They do not settle
time-zone interpretation, team identities and eligibility, availability,
calendar/fairness rules, shift boundaries, approval roles, or production
ServiceNow integration. Those remain governed by the open items in
[clarify.md](./clarify.md) and the production implementation gate.
