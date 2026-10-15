# CPS Sprint Pulse — Requirements

## Purpose

Provide the CPS team with an at-a-glance view of sprint progress, delivery
pace, and risks. The dashboard is intended to live inside Jira as a dashboard
or gadget once the Jira platform is confirmed.

## Audience and scope

- **Audience:** CPS team.
- **View:** Team-level overview; no assignee filter.
- **Sprint length:** Two weeks.
- **Sprint range:** Current sprint plus the five most recent completed sprints.
- **Initial data source:** Sample/demo data.
- **Target experience:** A Jira dashboard/gadget.

## Dashboard requirements

For the selected sprint, show:

1. **Completion**
   - Completed and total story points.
   - Completed and total issues.
   - Completion percentages for both measures.
2. **Burndown**
   - Remaining story points over the two-week sprint.
   - Actual progress compared with an ideal burndown line.
3. **Blockers**
   - Number of blocked issues.
   - A compact issue table with issue key, summary, owner, and time blocked.
   - A clear empty state when there are no blockers.
4. **Scope changes**
   - Story points added and removed after sprint start.
   - A compact issue table identifying each changed issue, its summary, change
     type, and points.
5. **Sprint health context**
   - Planned and remaining story points, net scope change, and sprint elapsed.
   - A short status message that calls attention to blockers when present.

The sprint selector must switch all displayed metrics, chart data, and issue
tables to the selected sprint. The layout should prioritize summary cards and
charts, with compact tables for actionable issue details.

## Data and integration requirements

- The initial prototype uses clearly labeled fictional sample data.
- No Jira API connection or credentials are part of the demo prototype.
- A live integration must be designed only after confirming whether CPS uses
  Jira Cloud or Jira Server/Data Center; the implementation and packaging
  choices depend on that platform.
- Keep any future credentials out of source code and use an appropriate
  configuration or secret-management mechanism.

## Current prototype

The static prototype is in [index.html](./index.html), with launch instructions
in [README.md](./README.md). It demonstrates the requested metrics and sprint
selection using local sample data. It is not yet connected to Jira and is not
packaged as a Jira gadget.

## Open questions

- Does CPS use Jira Cloud or Jira Server/Data Center?
- Once the platform is known, what Jira app/gadget framework and deployment
  approach are approved?
- What Jira project/board identifier, issue statuses, and estimation field
  should be used for the live data mapping?
- Should “time blocked” in the live view be measured from a blocked status
  transition, or from another team convention?

## Acceptance criteria

- The dashboard presents both issue-count and story-point completion.
- The burndown compares actual remaining work with an ideal line across the
  sprint.
- Blockers and scope additions/removals are visible in compact issue tables,
  including appropriate empty states.
- Selecting any of the six displayed sprints updates the metrics, chart, and
  tables consistently.
- Demo/sample information is clearly distinguished from live Jira data.
- A production Jira integration is not implemented until the Jira platform and
  data conventions are confirmed.
