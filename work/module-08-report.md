# Module 08 Completion Report

## Tracked Files
project_spec.md
work/jira-dashboard/README.md
work/jira-dashboard/index.html
work/jira-dashboard/requirements.md
work/module-03-report.md
work/module-08-report.md
work/module03-task
work/status-report-template.md

## Spec Commit History
c8047b1 Add CPS on-call roster specification

## project_spec.md Contents
# CPS On-Call Roster — Technical Specification

## 1. Purpose

Create a six-week on-call roster for the five-person CPS team. The roster will
provide continuous day and night primary coverage, distribute assignments
fairly, and be maintained in ServiceNow. The scrum master will generate a
draft, review and edit it, and publish the approved roster.

This document specifies the intended solution. It does not implement the
roster generator or connect to ServiceNow.

## 2. Goals

- Cover every day and night shift for the selected six-week period, including
  weekends and holidays.
- Assign exactly one on-call primary to each shift.
- Generate a draft that balances assignments across the five team members.
- Allow the scrum master to review and edit a draft before publishing it as a
  new CPS roster in ServiceNow.
- Prevent overlapping assignments and enforce the agreed minimum rest period.

## 3. Scope and decisions

| Topic | Requirement / decision |
|---|---|
| Team | Five CPS team members; names or identifiers will be supplied later. |
| Coverage | Every day, including weekends and holidays. |
| Shift coverage | One on-call primary per shift; this is on-call duty, not active staffing for the full shift. |
| Day shift | 9:00 AM–9:00 PM, referred to by the user as CST. |
| Night shift | 9:00 PM–9:00 AM, referred to by the user as CST. |
| Rotation cadence | Assignments change every shift/day; the generator must observe the rest and fairness constraints below. |
| Roster period | Six weeks beginning November 1, 2026; 42 calendar days, ending December 12, 2026, inclusive, subject to time-zone confirmation. |
| Fairness priorities | First balance total assigned hours; then minimize differences in night shifts; then minimize differences in weekend/holiday shifts. |
| Rest | No formal policy was provided. Enforce at least 12 hours between shifts and prevent overlapping shifts. No separate maximum-consecutive-shifts limit has been specified. |
| Availability | Leave and availability handling is an open decision; do not assume a policy. |
| Backup | One primary per shift. Escalation is handled elsewhere; no secondary is assigned in this roster. |
| Notifications | No shift reminders or schedule-change notifications are requested. |
| Destination | Create a new CPS roster in ServiceNow. Specific ServiceNow module, integration point, and environment are not yet identified. |
| Schedule owner | The scrum master (the user) reviews, edits, and publishes the roster. |

At full coverage, the six-week roster contains 84 shift assignments: two shifts
per day for 42 days.

## 4. Functional requirements

### 4.1 Generate a draft roster

- Generate a draft for the configured six-week period.
- Include one primary assignment for every day shift and every night shift.
- Use the five configured CPS team members as the eligible resource pool.
- Apply the fairness priority in order:
  1. Keep assigned hours as evenly distributed as possible.
  2. Keep the number of night shifts as evenly distributed as possible.
  3. Keep weekend and holiday assignments as evenly distributed as possible.
- Enforce at least 12 hours between the end of one assignment and the start of
  the same person's next assignment. Do not assign overlapping shifts.
- Do not silently produce a schedule that violates coverage, rest, or
  eligibility constraints. Report any unfilled shift or unsatisfied hard
  constraint for the scrum master's attention.
- Make the draft reproducible for the same input data and rules, or expose the
  generation seed/configuration if the implementation uses randomized
  tie-breaking.

### 4.2 Review and edit

- Present assignments in date order, with separate day and night shifts.
- Show each person's total assigned hours, total shifts, night shifts, and
  weekend/holiday shifts so the scrum master can review fairness.
- Allow the scrum master to change a shift's primary before publishing.
- Revalidate coverage, minimum rest, overlaps, and fairness after edits.
- Identify validation failures clearly; do not silently discard or override an
  edit that violates a hard rule.
- Keep a distinction between draft and published roster states.

### 4.3 Publish to ServiceNow

- Publish the reviewed roster as a **new CPS roster** in ServiceNow.
- Persist each assignment with the shift start/end, primary resource, and
  applicable time-zone context.
- Confirm that the publish operation succeeded and surface integration errors
  to the scrum master.
- Do not send reminders or change notifications as part of this scope.
- Do not overwrite an existing ServiceNow roster without an explicit,
  separately approved update workflow.

## 5. Scheduling and time rules

- A shift is defined by its local start and end times:
  - Day: 09:00–21:00.
  - Night: 21:00–09:00 on the following calendar day.
- The roster has two consecutive shifts per calendar day and must provide
  continuous coverage without a gap or overlap.
- Rest validation must compare actual shift instants, not just calendar dates.
- The time-zone label “CST” is ambiguous for implementation. Confirm whether
  it means a daylight-saving-aware regional zone (for example,
  `America/Chicago`) or a fixed UTC−6 offset before generating or publishing
  the production schedule. The November 1, 2026 start makes this decision
  especially important.
- The six-week end date is December 12, 2026 inclusive if November 1 is the
  confirmed start date and the confirmed time zone does not alter the intended
  calendar-day interpretation.
- Use the holiday calendar selected by the team when calculating holiday
  fairness. The calendar and region are not yet specified.

## 6. Data requirements

### 6.1 Team member

Each resource will need, at minimum:

- Stable ServiceNow or application identifier.
- Display name.
- Eligibility status for CPS on-call assignments.

Names and identifiers are intentionally not included in this specification;
the scrum master will decide them later.

### 6.2 Shift assignment

Each roster entry will need:

- Roster identifier and draft/published state.
- Shift date and shift type (day or night).
- Start and end instants, with the applicable time-zone identifier.
- Assigned primary resource identifier.
- Creation/update metadata sufficient for the scrum master to review changes.

### 6.3 Availability and holiday inputs

- Availability, planned leave, and preferences have not been decided. The
  production generator must not assume that an unavailable person may be
  assigned; agree on hard-block versus warning behavior before using
  availability data.
- Identify the applicable weekend definition and holiday calendar before
  applying holiday fairness.

## 7. Roles and workflow

1. The scrum master configures the team, roster dates, time zone, and other
   agreed scheduling inputs.
2. The scrum master requests a draft.
3. The generator creates assignments and runs validation.
4. The scrum master reviews coverage, fairness summaries, and any validation
   warnings or failures.
5. The scrum master edits assignments if needed and reruns validation.
6. The scrum master publishes the approved roster to ServiceNow.
7. The system confirms success or reports the error; no notification workflow
   is triggered.

Only the scrum master's review/edit/publish responsibility is confirmed.
ServiceNow platform roles and access controls still need to be mapped to that
responsibility.

## 8. Validation and error handling

Before a draft is considered valid or can be published, validate that:

- Every required shift has exactly one primary.
- There are no gaps or overlaps between the day/night coverage intervals.
- No person has overlapping shifts.
- Each person's rest interval between assignments is at least 12 hours.
- All assignments use eligible members of the configured CPS team.
- Fairness totals are calculated and presented; any unavoidable imbalance is
  visible to the scrum master.
- Required time-zone and holiday-calendar settings are present.

If a hard constraint cannot be satisfied, show which shifts or resources caused
the conflict. Do not label an incomplete or invalid schedule as successfully
generated or published. ServiceNow API, authorization, or network failures
must be surfaced to the scrum master, and a failed publish must not be
represented as a successful one.

## 9. Non-functional requirements

- **Correctness:** Use time-zone-aware date/time handling for shift boundaries
  and rest calculations.
- **Auditability:** Preserve enough information to identify the published
  roster and the person who reviewed/published it, subject to ServiceNow
  capabilities and policy.
- **Security:** Use approved ServiceNow authentication and authorization. Do
  not store credentials in source code or expose them in logs.
- **Usability:** Make draft/published state, assignment ownership, coverage
  gaps, rest violations, and fairness totals easy to distinguish.
- **Reliability:** Publishing must report a clear success or failure and must
  not leave the scrum master with a misleading success state.
- **Maintainability:** Keep schedule-generation rules separate from the
  ServiceNow adapter so the scheduling logic can be tested independently.

## 10. Acceptance criteria

1. A six-week draft can be generated for November 1–December 12, 2026 after
   confirming the time-zone interpretation.
2. The draft contains 84 assignments: one day primary and one night primary
   for each of 42 days.
3. The schedule provides continuous, non-overlapping coverage across every
   day, night, weekend, and holiday shift in the period.
4. No resource is assigned shifts with less than 12 hours of rest between
   them.
5. Fairness summaries expose total hours, night shifts, and weekend/holiday
   shifts for each resource, applying the agreed priority order.
6. The scrum master can review and edit a draft, and edits are revalidated.
7. An incomplete or constraint-violating roster cannot be silently published.
8. The approved roster can be published as a new CPS roster in ServiceNow, and
   success or failure is clearly reported.
9. No notifications are sent.
10. The system identifies unresolved configuration requirements rather than
    silently guessing them.

## 11. Open decisions before implementation

1. **Time zone:** Does CST mean a named daylight-saving-aware regional zone
   (such as `America/Chicago`) or fixed UTC−6?
2. **Team identities:** What are the five team member names/identifiers, and
   are all five eligible for both day and night assignments?
3. **Availability:** Should confirmed leave be a hard block, a warning, or
   ignored? Should preferences be supported?
4. **Maximum consecutive shifts:** The minimum 12-hour break is confirmed, but
   no maximum consecutive-shift rule has been specified.
5. **Weekend and holiday definitions:** Which region's holiday calendar and
   weekend definition should drive fairness?
6. **ServiceNow integration:** Which ServiceNow instance, application/module,
   schedule data model, API, and authentication method should be used for the
   new CPS roster?
7. **ServiceNow access:** Which roles allow the scrum master to create, edit,
   review, and publish the roster?
8. **Publishing policy:** Should publishing create a versioned roster, and how
   should later corrections to an already-published roster be handled?
