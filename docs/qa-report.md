# CPS On-Call Roster QA Report

## Summary

- **Session dates:** 2026-10-19 through 2026-10-20 (UTC+05:30).
- **Application:** CPS On-Call Roster local prototype.
- **Environment:** Windows; frontend at `http://127.0.0.1:5173/`,
  backend at `http://127.0.0.1:3001/`, and PostgreSQL 15 through Docker Compose.
- **Latest tested application change:** Favicon fix in `b91578d`; the
  setup-preview implementation is in `98289e1`. Both were pushed earlier in
  the session. Subsequent MCP configuration/documentation changes are in
  `bbbeb05`; `c4569ee` adds the module reports and user-approved scratch/cache
  files, not a new form fix. These last two commits remain local relative to
  the checked `origin/main` tracking reference.
- **Current result:** The approved local-only setup-preview flow passes its
  browser checks and automated regression tests. The complete roster lifecycle
  is not implemented or end-to-end verified.
- **Report update:** Includes the actual Chrome DevTools MCP page inventory,
  setup-flow test, and fresh seven-page console sweep completed on
  2026-10-20. No additional application tests were run solely to update this
  report.

Testing began with an overview dashboard and six placeholder workflow pages.
The requested form-submission test was initially blocked because setup had no
form, fields, or submit action. After the user approved a local-only setup
prototype, a validated setup form and summary were implemented and retested.
No actual roster was generated, saved, validated, or published.

## Test result summary

The results below summarize the checks executed in this session, including
the direct Google Chrome retest and subsequent actual Chrome DevTools MCP
checks. Automated test/build results are from the earlier application-change
validation; they were not rerun for the later browser-only checks.

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
- **Latest MCP flow:** Required-field rejection, valid submission, matching
  summary, edit-value retention, and resubmission passed. Native date entry
  required an MCP JavaScript fallback; see the limitation below.
- **Latest MCP diagnostics:** No console errors, warnings, or assertions;
  all 18 recorded flow requests returned HTTP 200 or 304. A separate fresh
  load of each of the seven routes also produced no matching console messages.
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
| Actual Chrome DevTools MCP inventory | PASS - 7 routes | Accessibility snapshots, visible-element inventory, and full-page screenshots at verified 1440 x 1100 viewport |
| Actual Chrome DevTools MCP submission | PASS with date-entry workaround | Matching summary; retained edit values; successful resubmission; no console errors/warnings/assertions and 18 requests with HTTP 200/304 |
| Latest MCP console-only sweep | PASS - 7 routes | Fresh page loads; no errors, warnings, or assertions; no forms submitted in this sweep |
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

### Latest Chrome DevTools MCP execution

The later checks invoked the configured Chrome DevTools MCP server through
actual MCP JSON-RPC over stdio. They did not substitute integrated-browser
actions or direct Chrome DevTools Protocol commands for MCP tools.

| Check | Observed result |
|---|---|
| Main-page screenshot | Captured through MCP |
| Seven-page navigation and inventory | All routes inspected; full-page screenshots and accessibility/DOM inventories saved; viewport verified as 1440 x 1100 |
| Inventory setup state | Form left empty and unsubmitted; generation showed the no-preview state |
| Overview -> Configure roster | Setup form opened |
| Empty Preview setup submission | Stayed on `/setup`; error summary displayed; all four required fields marked invalid |
| Valid inputs | Start `2026-10-20`, end `2026-10-31`, time zone `Asia/Kolkata`, IDs `demo-alice` and `demo-bob` |
| Submit and verify | `/generation` displayed Setup summary; all values matched; no validation alerts remained |
| Edit and resubmit | All values retained; resubmission displayed Setup summary |
| Flow console diagnostics | No error, warning, or assertion messages, including preserved messages |
| Flow network diagnostics | 18 recorded requests; all HTTP 200 or 304 |
| Separate console sweep | Fresh loads of `/`, `/setup`, `/generation`, `/review`, `/fairness`, `/validation`, `/publish`: no error, warning, or assertion messages |

**Automation limitation:** The first script incorrectly looked for date
inputs as textboxes. After targeting their actual `Date` accessibility role,
`fill_form` reported success but left both date values blank, and the initial
submission did not reach the summary. The completed run verified those empty
values and populated the dates through MCP `evaluate_script`, using native
input setters and bubbling input/change events. Text and member fields used
`fill_form`; buttons and links used `click`. This verifies application
validation/submission after event-driven date entry, not calendar-picker or
keyboard-only date usability. No application code was changed for this
automation issue.

The console-only sweep started a fresh application page because no application
tab remained in the MCP-managed browser. It does not recover earlier browser
history or exercise additional interactions. Reload clearing, reversed dates,
and other validation cases retain their earlier browser/automated evidence;
they were not all repeated in the latest MCP run.

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

Earlier tests used VS Code integrated-browser tools and, later, Google
Chrome's debugging protocol directly. Subsequent tests used the configured
Chrome DevTools MCP server over stdio, including snapshots, screenshots,
form interaction, console messages, and network diagnostics.

Chrome DevTools MCP tools invoked across these later checks:
`list_pages`, `new_page`, `emulate`, `navigate_page`, `take_snapshot`,
`evaluate_script`, `click`, `fill_form`, `wait_for`, `take_screenshot`,
`list_console_messages`, and `list_network_requests`. MCP `tools/list` was
also used to discover the advertised tool schemas; it is a protocol method,
not a Chrome browser-action tool.

Earlier integrated-browser tool names used were `openBrowserPage`, `readPage`,
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

| ID | Severity / classification | Finding | Evidence / impact | Current disposition |
|---|---|---|---|---|
| QA-01 | High - blocked requested flow | Main submission flow blocked by missing setup form | `/setup` had 0 forms, 0 input fields, and 0 workflow buttons | Resolved for approved setup-preview scope in `98289e1`; verified again through MCP. An intentional scaffold limitation, not an existing form-validation algorithm defect |
| QA-02 | Medium - unconfirmed navigation observation | Initial Configure roster interaction timed out | Two click attempts timed out; keyboard activation also failed in the original shared tab | Not reproduced in fresh tabs or latest MCP flow; no speculative navigation-code fix |
| QA-03 | Scope limitation, not a confirmed regression | Full roster lifecycle unavailable | Placeholder workflow pages and no generated roster | Still unavailable/unverified beyond setup preview |
| QA-04 | Tooling limitation | Requested screenshot viewport not consistently honored | Integrated-browser viewport constrained; later docked MCP DevTools also constrained ordinary resizing | Direct Chrome captures and later MCP viewport emulation provided desktop evidence; latest MCP viewport verified at 1440 x 1100 |
| QA-05 | Low - confirmed resource defect | Missing browser favicon | `/favicon.ico` HTTP 404 and resource-loading console error in fresh Chrome | Fixed in `b91578d` by declaring `/favicon.svg`; earlier fresh retest confirmed HTTP 200 and SVG MIME type |
| QA-06 | Tooling limitation, not confirmed application defect | MCP date entry reported success without populating values | `fill_form` left native dates empty; initial summary wait timed out | Completed via MCP `evaluate_script` native setters/events; valid submission and retained values verified; date-picker usability not established |

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

## Test cases

These cases document session evidence; adding this section did not execute
new tests. PASS means the stated expectation was observed using the listed
method, not that every browser or interaction method was covered. The rows
are scenario-level cases and do not represent additional Vitest tests:
the earlier automated run remains 14 passed, 0 failed in
[App.test.jsx](../frontend/src/App.test.jsx).

Unless overridden below, valid setup data is: start `2026-10-20`, end
`2026-10-31`, time zone `Asia/Kolkata`, and member IDs `demo-alice` and
`demo-bob`, one per line. Browser cases require the frontend running at
`http://127.0.0.1:5173/`.

### Executed functional and validation cases

| ID | Test case / steps and data | Expected result | Recorded result / status | Evidence / method |
|---|---|---|---|---|
| TC-01 | Open `/` with no setup preview | Local-prototype label, empty drafts, and no-ServiceNow-write warning appear | PASS - expected empty state displayed | Earlier Vitest; Chrome/MCP page inventory |
| TC-02 | From `/`, click Configure roster | `/setup` opens with required fields and Preview setup button | PASS - setup opened in fresh tabs; original shared-tab timeout remains QA-02 | Earlier Vitest/browser; latest MCP `click` and snapshot |
| TC-03 | From `/`, click Set up a roster | Setup form opens | PASS | Earlier Vitest and integrated-browser test |
| TC-04 | Open `/setup`; leave all four fields empty; click Preview setup | Remain on setup; summary alert and four invalid fields; no result summary | PASS - four invalid fields and rejection alert observed | Earlier Vitest/browser; latest MCP flow evidence |
| TC-05 | Enter otherwise valid data with end `2026-10-19`; submit | Reject reversed range with end-date error | PASS - end date must be on or after start date | Earlier Vitest and direct Chrome retest; not repeated in latest MCP flow |
| TC-06 | Enter otherwise valid data with time zone `Not/AZone`; submit | Reject unrecognized named time zone; no summary | PASS | Earlier Vitest |
| TC-07 | Enter otherwise valid data with time zone `+05:30`; submit | Reject numeric-offset-only time zone; no summary | PASS | Earlier Vitest |
| TC-08 | Enter otherwise valid data with member list `demo-alice` and ` demo-alice `; submit | Reject duplicate IDs after trimming | PASS - unique-member error displayed | Earlier Vitest |
| TC-09 | Enter otherwise valid data with member list containing only spaces and a newline; submit | Reject empty normalized member list | PASS - at-least-one-member error displayed | Earlier Vitest |
| TC-10 | Submit empty form, then correct all fields using valid data and submit again | Previous validation alert clears and Setup summary appears | PASS - no validation alerts remained on successful summary | Earlier Vitest; latest MCP flow |
| TC-11 | Enter valid setup data; click Preview setup | Navigate to `/generation`; summary matches both dates, zone, and member IDs; show preview-only status | PASS - all values matched; no roster generated or saved | Earlier Vitest/browser; latest MCP flow and result screenshot |
| TC-12 | Submit member IDs with surrounding whitespace and trailing blank line | Summary contains trimmed IDs and no blank member entries | PASS - `demo-alice` and `demo-bob` displayed | Earlier Vitest |
| TC-13 | Submit start and end `2026-10-20` with time zone ` UTC ` | Accept single-day period; trim zone to `UTC` | PASS | Earlier Vitest |
| TC-14 | After valid submission, click Edit setup | Return to form retaining submitted inputs | PASS - all four values retained in latest MCP check | Earlier Vitest/browser; latest MCP `evaluate_script` |
| TC-15 | Edit accepted setup; change end date to `2026-11-01`; resubmit | Summary updates to changed end date | PASS | Earlier Vitest |
| TC-16 | Open Edit setup after valid submission; resubmit unchanged data | Setup summary appears again | PASS | Latest MCP `click` and `wait_for` |
| TC-17 | After successful preview, return to Roster overview | Overview still says No roster drafts yet | PASS - preview does not create a draft | Earlier Vitest |
| TC-18 | Submit valid setup, then reload result page; automated equivalent unmounts/remounts app at `/generation` | No-preview message; Start roster setup link; new setup starts empty | PASS | Earlier direct Chrome reload test and Vitest remount case; not rerun in latest MCP flow |
| TC-19 | Open `/generation` without in-memory setup | Explain no preview exists; offer Start roster setup | PASS | Earlier Vitest and latest MCP page inventory |
| TC-20 | Visit `/`, `/setup`, `/generation`, `/review`, `/fairness`, `/validation`, `/publish`; inspect visible controls/text | Each main route renders its intended preview or placeholder state | PASS - seven routes inventoried and captured; placeholder business actions not implemented | Earlier Chrome; latest MCP snapshots, DOM inventories, and screenshots |
| TC-21 | Render `/not-a-route` | Understandable Page not found heading | PASS | Earlier Vitest only; not a browser/MCP route check |

### Executed diagnostic and tooling cases

| ID | Test case / steps | Expected result | Recorded result / status | Evidence / method |
|---|---|---|---|---|
| TC-22 | Fresh-load each of the seven main routes; wait for document/fonts and inspect console | No JavaScript errors, warnings, or assertions during observed loads | PASS - no matching messages on all seven routes | Latest MCP `navigate_page`, `evaluate_script`, `list_console_messages`; session tool output |
| TC-23 | After submit/edit/resubmit, inspect current and preserved console messages | No errors, warnings, or assertions from observed flow | PASS - no matching messages | `chrome-mcp-flow-evidence.json`; MCP `list_console_messages` |
| TC-24 | Inspect network requests from observed setup flow | No recorded failed or HTTP-error responses | PASS - all 18 recorded requests returned HTTP 200 or 304 | `chrome-mcp-flow-evidence.json`; MCP `list_network_requests` |
| TC-25 | Fresh-load app after favicon fix; inspect requested icon and production output | Declared SVG returns HTTP 200 with SVG MIME type; asset and declaration included in build | PASS - missing-icon defect QA-05 resolved | Earlier direct Chrome retest and production-build checks; not separately reasserted by latest MCP network list |
| TC-26 | Emulate 1440 x 1100 desktop viewport; inspect dimensions and capture every main route | Verified viewport dimensions and seven saved full-page screenshots | PASS | MCP `emulate`, `evaluate_script`, `take_screenshot`; `chrome-mcp-page-inventory.json` |
| TC-27 | Use MCP `fill_form` to populate both native date inputs, then inspect their values | Dates contain the requested ISO values | FAIL - tool reported success but left dates blank; automation limitation QA-06, not confirmed application defect | MCP snapshots/value inspection; completed flow used MCP native setters/events through `evaluate_script` |
| TC-28 | Run frontend regression, lint, and production build after application fixes | Tests, lint, and build succeed | PASS - 14 tests passed; lint and build passed | Earlier commands listed under Automated checks; not rerun for this documentation update |

### Not executed / unavailable cases

These are explicit coverage gaps, not passing tests or newly approved
implementation requirements.

| ID | Scenario | Intended verification | Current status / reason |
|---|---|---|---|
| TC-29 | Enter dates using calendar popups or keyboard-only navigation | Date entry works through native user interactions without script setters | NOT TESTED - date controls inventoried; latest MCP flow used event-driven fallback |
| TC-30 | Activate Help and audit keyboard/focus/accessibility behavior | Controls respond and meet agreed accessibility requirements | NOT TESTED - Help inventoried only; no comprehensive accessibility audit |
| TC-31 | Generate, persist, edit, validate, and publish a roster | Correct business results across the complete approved lifecycle | BLOCKED / NOT VERIFIED - setup preview only; production rules unresolved; no live ServiceNow writes permitted |
| TC-32 | Cross-browser, comprehensive responsive, performance/load, and security checks | Meet agreed compatibility, performance, and security criteria | NOT TESTED - session scope did not include these audits or acceptance thresholds |

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

Actual Chrome DevTools MCP evidence added later:

| Page / check | Artifact filename |
|---|---|
| Initial MCP main-page capture | `chrome-mcp-main-page.png` |
| Overview | `chrome-mcp-pages-01-overview.png` |
| Setup form | `chrome-mcp-pages-02-setup.png` |
| Generation, no-preview state | `chrome-mcp-pages-03-generation.png` |
| Review & edit | `chrome-mcp-pages-04-review.png` |
| Fairness | `chrome-mcp-pages-05-fairness.png` |
| Validation | `chrome-mcp-pages-06-validation.png` |
| Publish result | `chrome-mcp-pages-07-publish.png` |
| Page snapshots and visible-element inventories | `chrome-mcp-page-inventory.json` |
| Successful submitted setup summary | `chrome-mcp-flow-result.png` |
| MCP flow calls and responses, including console/network diagnostics | `chrome-mcp-flow-evidence.json` |

The seven-page MCP inventory was read-only; the submitted summary screenshot
comes from the separate form-flow test. The subsequent console-only sweep
returned its results in the session tool output, not a separate saved artifact.

All files are in the session artifact directory above. They are local evidence
and may not be accessible to other repository users.

## Related tooling changes

- Commit `4b95977` added the Chrome DevTools MCP configuration and PowerShell
  launcher.
- The original launcher used a dedicated profile and port-9222 debugging
  endpoint. Commit `bbbeb05` switched to MCP-managed Chrome over a debugging
  pipe, with all configured tool categories and optional capabilities.
- Actual initialization and tool discovery succeeded; server version `1.11.0`
  advertised 59 tools. This is availability evidence, not a claim that every
  advertised capability was tested.
- JavaScript evaluation is enabled; usage statistics and CrUX URL sharing are
  disabled. Repository-scoped filesystem configuration and a separate browser
  profile are documented in the [frontend README](../frontend/README.md).
- Actual browser tool invocation is now verified by the page inventory,
  screenshots, submission, console, and network checks above.
- A headless Chrome screenshot command initially surfaced Chrome's
  screenshot-success message on stderr as a PowerShell error. The PNG was
  verified, and subsequent captures used `Start-Process` with exit-code checks.
  This was a capture-tool issue, not a reported application JavaScript error.

## Current status and remaining scope

**Verified working:** Local service availability at the time checked, all
main route loads, local setup input validation, preview submission, summary
content, editing, and intentional clearing on reload.
The earlier fresh Chrome retest confirmed the favicon fix and observed no
console errors/warnings, uncaught exceptions, failed requests, or HTTP errors.
The latest actual MCP flow also passed after the documented date-entry
workaround, with no console errors/warnings/assertions and all 18 recorded
requests returning HTTP 200/304. A separate latest seven-route MCP console
sweep was clean on fresh page loads. Four workflow routes still present
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
