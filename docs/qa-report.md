# CPS On-Call Roster QA Report

## Summary

- **Session date:** 2026-10-19 (UTC+05:30).
- **Application:** CPS On-Call Roster local prototype.
- **Environment:** Windows; frontend at `http://127.0.0.1:5173/`,
  backend at `http://127.0.0.1:3001/`, and PostgreSQL 15 through Docker Compose.
- **Latest tested application change:** Favicon fix, retested in Google Chrome
  at approximately 23:40 (UTC+05:30), then committed locally as `b91578d`
  (`fix: form validation error on submit`). This commit has not been pushed
  during the session. The setup-preview implementation is committed and
  pushed as `98289e1`.
- **Current result:** The approved local-only setup-preview flow passes its
  browser checks and automated regression tests. The complete roster lifecycle
  is not implemented or end-to-end verified.
- **Report update:** Consolidates session evidence through the favicon retest;
  no additional application tests were run solely to rewrite this report.

Testing began with an overview dashboard and six placeholder workflow pages.
The requested form-submission test was initially blocked because setup had no
form, fields, or submit action. After the user approved a local-only setup
prototype, a validated setup form and summary were implemented and retested.
No actual roster was generated, saved, validated, or published.

## Test result summary

The results below summarize the checks executed in this session, including
the Google Chrome retest recorded below.

### Final results at a glance

- **Automated regression:** 14 tests passed, 0 failed in the latest Vitest run.
- **Route coverage:** All 7 main pages visited and retested in Google Chrome.
- **Main flow:** Overview -> Configure roster -> required inputs ->
  Preview setup -> matching Setup summary passed.
- **Negative cases:** Empty inputs and reversed dates were rejected in Chrome;
  invalid time zones and duplicate IDs were also covered by automated tests.
- **State behavior:** Editing retained inputs; reloading cleared the preview.
- **Confirmed resource defect:** Missing favicon fixed and retested; the
  declared SVG icon returned HTTP 200.
- **Final browser diagnostics:** 0 observed console errors, warnings, uncaught
  exceptions, failed requests, or HTTP errors in the monitored Chrome retest.
- **Quality gates:** Frontend lint, production build, and whitespace checks passed.
- **Unresolved observation:** Original-tab navigation timeout was not reproduced
  in fresh tabs; its cause remains unconfirmed.
- **Verdict:** PASS for the local-only setup preview. Full roster generation,
  persistence, review/edit, fairness, scheduling validation, and publishing
  are not verified. No production-readiness claim is made.

| Test area | Result | Evidence / scope |
|---|---|---|
| Frontend automated regression tests | PASS - 14 passed, 0 failed | One Vitest file; application shell, setup validation, submission, editing, and reset behavior |
| Main page loading | PASS - 7 of 7 routes | All main routes returned HTTP 200 in the pre-fix sweep |
| Setup-preview browser flow | PASS after fix | Both setup entry links, empty-form rejection, valid submission, matching summary, editing, and clearing on reload |
| Console monitoring | PASS on final Chrome retest | Initial integrated-browser sweep was clean; later Chrome testing found a favicon 404, which was fixed and retested without observed errors or warnings |
| Post-fix interaction monitoring | PASS within observed scope | No observed warnings, console errors, exceptions, or HTTP errors during the monitored submission/edit flow |
| Local service checks | PASS at time checked | Backend running response, frontend HTTP 200, PostgreSQL healthy and accepting connections |
| Frontend lint | PASS | `npm.cmd run lint` |
| Frontend production build | PASS | `npm.cmd run build` |
| Whitespace validation | PASS | `git diff --check` |
| Original-tab navigation timeout | INCONCLUSIVE | Failed initially; not reproduced in a fresh tab, where both setup links passed |
| Complete roster lifecycle | BLOCKED / NOT VERIFIED | Actual generation, persistence, assignment editing, fairness, scheduling validation, and publishing are outside the implemented preview |

### Google Chrome follow-up: favicon fix and retest

Later testing in a fresh Google Chrome profile found one additional
low-severity issue: the browser requested `/favicon.ico`, which returned HTTP
404 and produced a resource-loading console error. Earlier integrated-browser
checks had not surfaced it.

Added [favicon.svg](../frontend/public/favicon.svg) and an explicit icon link in
[index.html](../frontend/index.html). A fresh headless Google Chrome retest
used the Chrome DevTools Protocol directly, not Chrome DevTools MCP.

| Retest | Result |
|---|---|
| All seven main route loads | PASS |
| Browser-requested `/favicon.svg` | PASS - HTTP 200, `image/svg+xml`; no fallback favicon error observed |
| Overview -> Configure roster | PASS |
| Empty submission | PASS - all four required fields rejected |
| Valid submission and matching summary | PASS - October 20-31, 2026; Asia/Kolkata; demo-alice and demo-bob |
| Edit setup retains inputs | PASS |
| Reversed dates | PASS - rejected with field error |
| Correct invalid date and resubmit | PASS |
| Reload clears preview | PASS |
| Console warnings/errors, uncaught exceptions, failed requests, HTTP errors during retest | None observed |
| Frontend Vitest regression tests rerun | PASS - 14 passed |
| Frontend lint and production build rerun | PASS |
| Production favicon asset and HTML declaration | PASS |

Post-fix screenshot: `chrome-retest-result.png` in the session artifact
directory documented below. This is a local setup-preview test; it does not
verify roster generation, persistent storage, or publishing.

**Overall outcome:** The approved local-only setup-preview scope passed the
executed post-fix checks. No confirmed failure remains in that tested scope;
the original-tab navigation issue remains unexplained. These results do not
constitute full end-to-end roster validation or production sign-off.

## Scope and methods

- Visited all seven main routes and inventoried their visible content and controls.
- Captured desktop screenshots using headless Google Chrome at 1440 x 1100;
  also captured the updated seven-page inventory at 1440 x 1200 and opened
  the application in regular Chrome.
- Used the VS Code integrated-browser tools for route snapshots, console
  monitoring, navigation, form entry, submission, and result verification.
- Checked console warnings, console errors, and uncaught JavaScript exceptions
  across fresh loads of all seven pages.
- Ran frontend regression tests, lint, a production build, and whitespace checks
  after implementing the setup flow.
- Checked local backend HTTP response and PostgreSQL readiness.
- Subsequently navigated all seven main pages in headless Google Chrome,
  using sidebar links, and extracted their visible text and controls.
- Tested setup submission in headless Google Chrome with mouse events for
  links/buttons and input/change events for form values; monitored runtime,
  console, browser log, and network events through the debugging protocol.

Chrome DevTools MCP configuration was added during the session, but the browser
tests used VS Code integrated-browser tools and, later, Google Chrome's
debugging protocol directly. No Chrome DevTools MCP tools were invoked.
Integrated-browser tool names used were `openBrowserPage`, `readPage`,
`navigatePage`, `clickElement`, `screenshotPage`, and `runPlaywrightCode`.
Direct Chrome automation ran through `powershell` with Node.js and Chrome.

## Local service checks

| Component | Check performed | Observed result |
|---|---|---|
| Google Chrome | Installation path and registered version | Installed at `C:\Program Files\Google\Chrome\Application\chrome.exe`; registered version `155.0.8059.85` |
| Docker Compose | `docker compose up -d --wait db` and `docker compose ps` | PostgreSQL container running and healthy; localhost port 5432 |
| PostgreSQL | `pg_isready` inside the database container | Accepting connections |
| Backend | GET `/` on port 3001 | `{"service":"cps-on-call-roster-backend","status":"running"}` |
| Frontend | GET `/` on port 5173 | HTTP 200; CPS On-Call Roster page returned |

The backend and frontend were already running and were reused without starting
duplicate processes. PostgreSQL readiness does not establish application
database integration: the current setup preview uses only frontend memory.

## Pages visited and elements inspected

Every route returned HTTP 200 during the pre-fix page-load sweep.

### Shared application shell

Inspected on the main pages:

- CPS Roster home link and ON-CALL PLANNER branding.
- Navigation links: Roster overview, Roster setup, Generation result,
  Review & edit, Fairness, Validation, and Publish result.
- Active-route highlighting.
- Workspace / On-call roster header and LOCAL PROTOTYPE badge.
- Desktop local-demo identity display and Help (`?`) button.

The desktop screenshots show the full sidebar. The integrated browser also
rendered a narrower responsive layout with horizontally scrolling navigation.
This was not a comprehensive responsive or accessibility audit. The Help button
was inventoried, not functionally tested.

| Page / route | Initially inspected elements and text | Status after fixes |
|---|---|---|
| Roster overview `/` | On-call roster heading; Configure roster and Set up a roster links; prototype warning; four summary cards; Roster drafts empty state; disabled View all button; Before you begin checklist; simulated-publishing footer | Both setup entry links verified in a fresh browser tab. Empty roster state preserved |
| Roster setup `/setup` | Step 01 heading, setup description, placeholder banner, LOCAL ONLY badge, Back to roster overview link; no fields or submit control | Replaced with an explicitly local-only form, validation messages, Preview setup button, and overview link |
| Generation result `/generation` | Step 02 heading, generation-outcome description, placeholder banner, overview link | Shows submitted setup summary and Edit setup link; without in-memory setup, shows a no-preview message and Start roster setup link |
| Review & edit `/review` | Step 03 heading; future assignment-editing description; placeholder banner; overview link | Still a placeholder; no assignment-editing workflow tested |
| Fairness `/fairness` | Step 04, Fairness summary heading; hours/night/weekend/holiday comparison description; placeholder banner; overview link | Still a placeholder; no fairness calculation tested |
| Validation `/validation` | Step 05, Validation details heading; coverage/eligibility/overlap/rest description; placeholder banner; overview link | Still a placeholder; no scheduling validation tested |
| Publish result `/publish` | Step 06 heading; simulated-publishing warning; placeholder banner; overview link | Still a placeholder; no publish action or live ServiceNow write tested or enabled |

### Updated form and result elements

The later seven-page Chrome inventory inspected the implemented UI:

- `/setup`: required Start date and End date inputs with calendar pickers;
  required Time zone text input with placeholder `Asia/Kolkata or UTC`;
  required Local demo member IDs multiline field (one per line); Preview setup
  submit button; Back to roster overview link; local-only and reload warnings.
- `/generation`, without submitted inputs: no-preview explanation and
  Start roster setup link.
- `/generation`, after submission: Setup summary heading; preview-only status;
  submitted start/end dates, time zone, and member-ID list; Edit setup link;
  explicit warnings that no roster was generated/saved and no scheduling
  constraints were checked.
- `/review`, `/fairness`, `/validation`, and `/publish`: placeholder text,
  LOCAL ONLY badge, and Back to roster overview link remained visible.

Navigation, required-field rejection, submission, summary, editing, and reload
behavior were exercised. The Help button and decorative/status elements were
inspected only. Calendar-picker interactions were not separately exercised.

### Overview details

- **Active rosters:** no data connected.
- **Coverage status:** Not checked; validation runs after setup.
- **Next shift:** no schedule available.
- **Publish status:** Simulated; external writes disabled.
- **Roster drafts:** No roster drafts yet; View all disabled.
- **Before you begin:** Confirm schedule settings, Add eligible team members,
  Generate and validate; all initially marked OPEN.

These are prototype display states, not evidence of a generated roster or
completed validation.

## Initial findings and dispositions

| ID | Finding | Evidence / impact | Current disposition |
|---|---|---|---|
| QA-01 | Main submission flow blocked by missing setup form | `/setup` had 0 forms, 0 input fields, and 0 workflow buttons; no submission or result could be exercised | Resolved for the user-approved setup-preview scope. This was an intentional scaffold limitation, not an existing form-validation algorithm defect |
| QA-02 | Initial Configure roster interaction timed out | Two mouse-click attempts timed out while waiting for actionability; keyboard activation also failed to navigate in the original shared tab | Not reproduced in a fresh integrated-browser tab. Both setup links subsequently worked; no speculative navigation-code fix was applied |
| QA-03 | Full roster lifecycle unavailable | Workflow pages were placeholders and no generated roster existed | Still out of scope for this fix; review/edit, fairness, scheduling validation, persistence, and publishing remain unverified |
| QA-04 | Integrated-browser screenshots did not consistently honor requested desktop dimensions | The effective viewport remained constrained despite viewport-size requests | Desktop screenshots were recaptured using headless Google Chrome; not classified as an application defect |
| QA-05 | Missing browser favicon (Low severity) | A fresh Google Chrome profile requested `/favicon.ico`; HTTP 404 produced a resource-loading console error during both flow testing and a console sweep | Fixed in `b91578d` by declaring and serving `/favicon.svg`; fresh Chrome retest observed HTTP 200 with SVG MIME type and no console/network errors |

The initial integrated-browser all-page sweep observed no JavaScript console
errors, warnings, or uncaught exceptions. Later Chrome testing surfaced QA-05,
a resource-loading error rather than a JavaScript exception. The final Chrome
retest was clean within its monitored scope. No uncaught application JavaScript
exception was observed. These checks do not establish full business-workflow
functionality.

## Fixes applied

Implemented in commit `98289e1`:

- Added [SetupPage.jsx](../frontend/src/pages/SetupPage.jsx) with required
  start date, end date, named time zone, and newline-separated local demo
  member IDs.
- Added explicit client-side errors for missing or invalid dates, end date
  before start date, unsupported time zones, blank member lists, and
  duplicate member IDs.
- Added an error summary, field-associated error text, and `aria-invalid`.
- Trimmed time zone and member IDs and ignored blank member-ID lines.
- Connected form submission to an in-memory setup summary on `/generation`.
- Added Edit setup with retained values and a no-preview state after reload.
- Preserved the overview's empty roster state; submitting the preview does not
  create a roster.
- Added form styling, regression tests, and updated the
  [frontend README](../frontend/README.md).

The result explicitly states that no roster has been generated or saved.
Membership, eligibility, availability, coverage, rest, and fairness are not
verified. Reloading clears the preview. No backend, database, or ServiceNow
write is performed.

Implemented in commit `b91578d`:

- Added a branded [SVG favicon](../frontend/public/favicon.svg).
- Declared it in the [HTML header](../frontend/index.html), preventing Chrome's
  implicit missing `/favicon.ico` request during the verified fresh loads.
- Verified that Chrome fetched the icon with HTTP 200 and `image/svg+xml`.
- Verified that the production build includes the favicon and its HTML link.

## Post-fix verification

### Browser checks

| Scenario | Result |
|---|---|
| Overview -> Configure roster -> setup form | Passed in fresh tab |
| Submit empty setup | Passed: submission rejected; all four fields marked invalid |
| Enter dates `2026-10-20` through `2026-10-31`, time zone `Asia/Kolkata`, IDs `demo-alice` and `demo-bob` | Fields accepted |
| Click Preview setup | Passed: navigated to `/generation`; Setup summary rendered |
| Verify summary matches entered inputs | Passed: dates, time zone, and IDs matched |
| Click Edit setup | Passed: returned to form with entered values retained |
| Back to overview -> Set up a roster | Passed |
| Reload result page | Passed: no-preview state shown; no saved roster claimed |
| Start setup after reload | Passed: date field empty |
| Monitor warnings/errors/exceptions and HTTP errors during the post-fix submission/edit flow | None observed |

These successful interactions were performed in a new integrated-browser tab;
the original tab's timeout cause was not established.

### Automated checks

Executed from the frontend directory:

| Check | Result |
|---|---|
| `npm.cmd test -- src\App.test.jsx` | 14 tests passed in one file |
| `npm.cmd run lint` | Passed |
| `npm.cmd run build` | Passed |
| `git diff --check` | Passed |

The VS Code unit-test tool initially reported no discovered tests. The same
test file was then run successfully using the repository's Vitest command.

Regression coverage includes:

- Existing prototype/empty-state, setup navigation, and not-found rendering.
- Both setup entry links.
- Missing required values.
- Reversed date range.
- Invalid named time zone and rejection of numeric-offset-only input.
- Duplicate member IDs and whitespace-only member input.
- Successful preview, normalized IDs, correction after validation errors,
  retained values when editing, updated results, and unchanged overview state.
- Single-day date range and trimmed UTC time zone.
- No preview after application remount, with empty setup inputs.

The entire backend or repository test suite was not run as part of this fix.

## Screenshots

Seven desktop screenshots were captured before the form fix:

| Page | Screenshot filename |
|---|---|
| Roster overview | `01-roster-overview.png` |
| Roster setup | `02-roster-setup.png` |
| Generation result | `03-generation-result.png` |
| Review & edit | `04-review-edit.png` |
| Fairness | `05-fairness.png` |
| Validation | `06-validation.png` |
| Publish result | `07-publish-result.png` |

An earlier overview capture, `cps-main-page.png`, was taken at 1440 x 1000.
The seven-page set was taken at 1440 x 1100.

Screenshots are local session artifacts, not committed repository assets:

```text
C:\Users\RevathiAnumola\.copilot\session-state\1799f2ce-5260-43c7-b13a-2ceda40bfbd4\files
```

The filenames above show the original placeholders. Later post-setup-fix Chrome
captures at 1440 x 1200 are:

| Page | Updated screenshot filename |
|---|---|
| Roster overview | `current-01-overview.png` |
| Roster setup form | `current-02-setup.png` |
| Generation result, no-preview state | `current-03-generation.png` |
| Review & edit | `current-04-review.png` |
| Fairness | `current-05-fairness.png` |
| Validation | `current-06-validation.png` |
| Publish result | `current-07-publish.png` |

Additional local evidence:

- `current-page-inventory.json`: visible text and controls from all seven
  current pages, captured before the favicon fix.
- `main-page-latest.png`: overview capture at 1440 x 1100.
- `chrome-flow-result.png`: successful submitted summary before the favicon
  fix, captured at 1440 x 1100.
- `chrome-retest-result.png`: successful summary after the favicon fix,
  captured at 1440 x 1100.

All files are in the session artifact directory above. They are local evidence
and may not be accessible to other repository users.

## Related tooling changes

- Commit `4b95977` added the Chrome DevTools MCP configuration and PowerShell
  launcher.
- The launcher starts Chrome with a dedicated profile and local debugging
  endpoint on port 9222, then connects the MCP server.
- JSON and PowerShell syntax checks passed. Actual MCP startup/handshake and
  Chrome DevTools tool invocation were not verified in the session.
- A headless Chrome screenshot command initially surfaced Chrome's
  screenshot-success message on stderr as a PowerShell error. The PNG was
  verified, and subsequent captures used `Start-Process` with exit-code checks.
  This was a capture-tool issue, not a reported application JavaScript error.

## Current status and remaining scope

**Verified working:** Local service availability at the time checked, all
main route loads, local setup input validation, preview submission, summary
content, editing, and intentional clearing on reload.
The favicon now loads successfully, and no console errors/warnings, uncaught
exceptions, failed requests, or HTTP errors were observed during the final
Google Chrome route-and-flow retest. Four workflow routes still present
placeholders; the generation-result route presents a setup preview only.

**Still unavailable or unverified:**

- Actual scheduling generation and production scheduling rules.
- Persistent draft storage or backend form submission.
- Membership/eligibility checks against approved team data.
- Assignment editing and revision/approval lifecycle.
- Coverage, overlap, rest, and fairness computations through the UI.
- Mock publishing execution or any live ServiceNow integration.
- Broad accessibility, responsive, cross-browser, security, load, or performance
  testing; historical console logs and errors requiring other interactions.

The approved [prototype decisions](../spec/decisions.md) and unresolved
[clarifications](../spec/clarify.md) still apply. The setup-preview fix is not
a claim of full roster-workflow completion or production readiness.
