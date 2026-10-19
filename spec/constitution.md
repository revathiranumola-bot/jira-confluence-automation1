# Project Constitution: CPS Automation Prototypes

## Project identity

- **Project name:** CPS Automation Prototypes (umbrella for distinct CPS
  Sprint Pulse and CPS On-Call Roster workflows).
- **Purpose:** Provide separate prototypes for reviewing sprint health through
  Jira/Confluence and for drafting, validating, and reviewing CPS on-call
  rosters for eventual ServiceNow publishing. The workflows have distinct
  product requirements and integrations; neither is a substitute for the
  other.
- **Target users:** CPS team members reviewing sprint health and the scrum
  master managing on-call rosters. Integration and administrative workflows
  are for authorized users; define their roles and permissions in each feature
  specification before implementation.

## Purpose

These principles govern design and implementation of CPS Automation
Prototypes, including the distinct CPS Sprint Pulse and CPS On-Call Roster
features. They are binding across features and must be reflected in
specifications, plans, implementation tasks, and verification. When
requirements conflict with a principle, document the conflict and obtain
explicit approval before proceeding.

## Principles

### 1. Specify behavior before implementation

- Define user goals, scope, acceptance criteria, failure behavior, and
  relevant external-service permissions before implementing a feature.
- Treat approved feature specifications and this constitution as the source of
  truth; update them when requirements change.
- Identify unresolved product or integration decisions explicitly. Do not
  invent Jira, Confluence, or ServiceNow workflows, permissions, or
  destructive behavior.

### 2. Keep the architecture clear and maintainable

- Use React 18 with Vite for the frontend and Node.js with Express for the
  backend.
- Keep Jira/Confluence and ServiceNow API access, credentials, authorization
  checks, and integration logic on the backend; the browser must not receive
  application secrets. A feature may use only integrations explicitly
  approved for that feature.
- Separate HTTP routes, business logic, persistence, and external-service
  adapters so each can be tested independently.
- Prefer small, focused changes and existing project conventions over
  unnecessary frameworks, abstractions, or duplicated logic.

### 3. Protect credentials, data, and access

- Store secrets outside source control and browser-delivered code; use the
  deployment environment's approved secret-management mechanism.
- Request only the external-service scopes necessary for an approved
  workflow, and enforce authorization on the server for every protected
  operation.
- Validate and constrain untrusted input at API boundaries. Use parameterized
  database queries and safe handling of external API responses.
- Do not log access tokens, credentials, or unnecessary sensitive issue,
  page, or user content.

### 4. Make external changes safe and transparent

- Distinguish read operations from operations that create, update, delete, or
  publish external-service content, including Jira/Confluence and ServiceNow.
- Make write operations explicit, permission-checked, and auditable. Require
  user confirmation for destructive or bulk changes unless an approved
  specification defines a safer, explicit workflow.
- Handle authentication errors, permission denials, rate limits, timeouts, and
  partial failures without presenting an unverified action as successful.
- Retry only when safe, using bounded retry behavior. Avoid duplicate
  side-effects when the external API's result is uncertain.

### 5. Preserve data integrity and schema history

- Use PostgreSQL 15 as the relational database, run through Docker for local
  development.
- Manage schema changes as versioned migrations; do not rely on undocumented
  manual database changes.
- Validate persisted data and use transactions where a multi-step database
  operation must be atomic.
- Keep application and database configuration outside committed secrets and
  provide reproducible local development setup.

### 6. Verify behavior with proportionate tests

- Test business rules and integration boundaries independently, including
  success, validation failure, authorization failure, and external-service
  failure cases.
- Cover API behavior and critical user-visible flows with appropriate
  integration or end-to-end tests.
- Use deterministic tests and fixtures; do not make routine tests depend on
  live Jira, Confluence, or ServiceNow accounts or production data.
- Run relevant tests and checks before considering a change complete, and
  report checks that could not be run.

### 7. Provide usable, observable workflows

- Present clear loading, success, empty, and error states in the frontend.
- Make the target external-service resource and the effect of a write
  operation understandable before it is performed.
- Record operationally useful errors and outcomes without exposing secrets or
  excessive user content.
- Keep configuration and startup instructions sufficient to run the frontend,
  backend, and PostgreSQL 15 development service using Docker.

## Technology constraints

- Frontend: React 18.3.1 and Vite 8.3.4, using `@vitejs/plugin-react` 6.1.2.
- Backend: Node.js 24.22.0 LTS and Express 5.3.0.
- Package manager: npm 11.19.1; commit lockfiles and use reproducible installs.
- Database: PostgreSQL 15, provided through the official `postgres:15` Docker
  image for local development. Keep deployments on PostgreSQL 15; review and
  pin the image digest when reproducible patch-level deployments are required.
- Docker: use Docker Compose for local frontend, backend, and database
  orchestration. Routine development and tests must not require a locally
  running Jira, Confluence, or ServiceNow instance.
- Jira, Confluence, and ServiceNow integrations must use their approved APIs
  and authentication mechanisms; select specific API scopes and workflows in
  feature specifications rather than assuming them globally. The on-call
  roster prototype is mock-only for publishing and must not perform live
  ServiceNow writes.

## Folder structure conventions

- Keep the React/Vite application in `frontend/` and the Express application
  in `backend/`; each owns its package manifest, dependencies, configuration,
  and build scripts.
- Put frontend source in `frontend/src/`. Organize UI components, pages,
  backend API clients, and shared frontend types under `components/`, `pages/`,
  `api/`, and `types/`, respectively.
- Put backend source in `backend/src/`. Keep HTTP routes, application
  services, scheduling or domain logic, external Jira/Confluence adapters,
  and middleware in `routes/`, `services/`, `scheduling/`, `integrations/`,
  and `middleware/`, respectively. Put approved external-service adapters
  behind the integration boundary; feature-specific adapter locations must
  be recorded in the feature specification. Add a `repositories/` directory
  if persistence logic grows beyond a small, clear service boundary.
- Keep automated tests under the root `tests/`, organized by concern, such as
  `tests/api/`, `tests/scheduling/`, and `tests/integrations/`. Do not mix test
  fixtures with production credentials or data.
- Keep project guidance and operational documentation under `docs/`, and
  SpecKit specifications and project principles under `spec/`.
- Keep the root `docker-compose.yml` for local service orchestration. Do not
  commit secrets; provide safe configuration examples separately where needed.

## Coding standards

- Use JavaScript modules and the file extensions `.jsx` for React components
  and `.js` for other frontend and backend modules unless the project
  deliberately adopts TypeScript through an approved plan.
- Use `PascalCase` for React component files and component functions
  (for example, `SprintSummary.jsx`); use `camelCase` for functions, variables,
  hooks, and ordinary module filenames (for example, `useSprintData.js` and
  `sprintService.js`).
- Use descriptive, consistent suffixes for backend responsibilities, such as
  `*.routes.js`, `*.service.js`, and `*.repository.js`. Name tests after the
  behavior or module under test and use the project's configured test suffix
  consistently.
- Use `UPPER_SNAKE_CASE` only for true module-level constants. Prefer clear
  names and small modules with one cohesive responsibility; avoid ambiguous
  abbreviations and unrelated logic in a single file.
- Keep route handlers focused on HTTP concerns. Put business rules in services
  or domain modules, database access behind a clear persistence boundary, and
  Jira/Confluence API calls in integration adapters.
- Format and lint consistently using the repository's configured tools. Do
  not introduce a second formatter, linter, or conflicting style configuration
  without an explicit project decision.

## Governance

- Review each feature specification and implementation plan against these
  principles before implementation.
- If a principle must change, update this constitution deliberately and record
  the rationale and affected constraints in the relevant project decision
  record.
- A feature is not complete until its acceptance criteria are verified and
  applicable tests pass, or any remaining limitations are explicitly reported.
