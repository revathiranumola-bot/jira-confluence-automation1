import { NavLink, Route, Routes } from "react-router-dom";

const navigation = [
  { label: "Roster overview", path: "/", icon: "◫" },
  { label: "Roster setup", path: "/setup", icon: "＋" },
  { label: "Generation result", path: "/generation", icon: "✳" },
  { label: "Review & edit", path: "/review", icon: "▤" },
  { label: "Fairness", path: "/fairness", icon: "◒" },
  { label: "Validation", path: "/validation", icon: "✓" },
  { label: "Publish result", path: "/publish", icon: "↗" }
];

function Sidebar() {
  return (
    <aside className="sidebar">
      <a aria-label="CPS Roster home" className="brand" href="/">
        <span aria-hidden="true" className="brand-mark">C</span>
        <span className="brand-copy">
          <strong>CPS Roster</strong>
          <small>ON-CALL PLANNER</small>
        </span>
      </a>

      <div className="nav-label">WORKSPACE</div>
      <nav aria-label="Roster workflow" className="nav-list">
        {navigation.map((item) => (
          <NavLink
            className={({ isActive }) => `nav-link${isActive ? " active" : ""}`}
            end={item.path === "/"}
            key={item.path}
            to={item.path}
          >
            <span aria-hidden="true" className="nav-icon">{item.icon}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <span aria-hidden="true" className="avatar">SM</span>
        <span className="profile-copy">
          <strong>Local demo</strong>
          <small>Prototype identity</small>
        </span>
        <span aria-label="Local only" className="online-dot" />
      </div>
    </aside>
  );
}

function Topbar() {
  return (
    <header className="topbar">
      <div className="breadcrumb"><span>Workspace</span><span>/</span><strong>On-call roster</strong></div>
      <div className="topbar-actions">
        <span className="environment-pill"><span />LOCAL PROTOTYPE</span>
        <button aria-label="Help" className="help-button" type="button">?</button>
      </div>
    </header>
  );
}

function OverviewPage() {
  return (
    <>
      <div className="page-heading">
        <div>
          <div className="eyebrow">CPS OPERATIONS <span>·</span> ROSTER WORKSPACE</div>
          <h1>On-call roster</h1>
          <p className="subtitle">Plan coverage, review the schedule, and keep every shift accountable.</p>
        </div>
        <NavLink className="primary-button" to="/setup">
          <span aria-hidden="true">＋</span> Configure roster
        </NavLink>
      </div>

      <section aria-label="Prototype status" className="prototype-banner">
        <span aria-hidden="true" className="banner-icon">i</span>
        <div>
          <strong>Prototype workspace</strong>
          <p>Roster data is not connected yet. Publishing is simulated; no ServiceNow changes are made.</p>
        </div>
        <span className="mock-tag">MOCK ONLY</span>
      </section>

      <section aria-label="Roster summary" className="stats-grid">
        <article className="stat-card">
          <div className="stat-label">ACTIVE ROSTERS <span className="stat-symbol purple">▤</span></div>
          <div className="stat-number">—</div>
          <div className="stat-note">No roster data connected</div>
        </article>
        <article className="stat-card">
          <div className="stat-label">COVERAGE STATUS <span className="stat-symbol green">✓</span></div>
          <div className="stat-number stat-awaiting">Not checked</div>
          <div className="stat-note">Validation runs after setup</div>
        </article>
        <article className="stat-card">
          <div className="stat-label">NEXT SHIFT <span className="stat-symbol blue">◷</span></div>
          <div className="stat-number">—</div>
          <div className="stat-note">No schedule available</div>
        </article>
        <article className="stat-card">
          <div className="stat-label">PUBLISH STATUS <span className="stat-symbol amber">↗</span></div>
          <div className="stat-number stat-awaiting">Simulated</div>
          <div className="stat-note">External writes are disabled</div>
        </article>
      </section>

      <section className="content-grid">
        <article className="panel roster-panel">
          <div className="panel-heading">
            <div>
              <h2>Roster drafts</h2>
              <p>Your recent schedules will appear here.</p>
            </div>
            <button className="text-button" type="button" disabled>View all <span aria-hidden="true">→</span></button>
          </div>
          <div className="empty-state">
            <div aria-hidden="true" className="empty-illustration">
              <div className="calendar-top" />
              <div className="calendar-grid"><i /><i /><i /><i /><i /><i /><i /><i /><i /></div>
              <span className="calendar-plus">+</span>
            </div>
            <h3>No roster drafts yet</h3>
            <p>Start by choosing a roster period and adding the approved team members.</p>
            <NavLink className="secondary-button" to="/setup">Set up a roster <span aria-hidden="true">→</span></NavLink>
          </div>
        </article>

        <aside className="panel guidance-panel">
          <div className="panel-heading">
            <div><h2>Before you begin</h2><p>Settings needed for a reliable schedule</p></div>
            <span aria-hidden="true" className="sparkle">✳</span>
          </div>
          <ul className="checklist">
            <li><span className="check pending">1</span><span><strong>Confirm schedule settings</strong><small>Time zone, weekends, and holidays</small></span><span className="status-open">OPEN</span></li>
            <li><span className="check pending">2</span><span><strong>Add eligible team members</strong><small>Use approved roster identities</small></span><span className="status-open">OPEN</span></li>
            <li><span className="check pending">3</span><span><strong>Generate and validate</strong><small>Hard constraints come first</small></span><span className="status-open">OPEN</span></li>
          </ul>
          <div className="guidance-note">
            <span aria-hidden="true">⌁</span>
            <p>Missing settings are called out instead of being guessed.</p>
          </div>
        </aside>
      </section>

      <footer className="page-footer">
        <span>CPS ON-CALL ROSTER <span className="footer-dot">·</span> LOCAL DEVELOPMENT</span>
        <span>ServiceNow publishing <strong>simulated only</strong></span>
      </footer>
    </>
  );
}

function WorkflowPage({ title, description, step }) {
  return (
    <section className="workflow-placeholder">
      <div className="eyebrow">ROSTER WORKFLOW <span>·</span> STEP {step}</div>
      <h1>{title}</h1>
      <p>{description}</p>
      <div className="prototype-banner compact">
        <span aria-hidden="true" className="banner-icon">i</span>
        <div><strong>Workflow screen placeholder</strong><p>This route is part of the UI skeleton. No roster data or service connection is configured.</p></div>
        <span className="mock-tag">LOCAL ONLY</span>
      </div>
      <NavLink className="secondary-button" to="/">← Back to roster overview</NavLink>
    </section>
  );
}

function NotFoundPage() {
  return (
    <section className="workflow-placeholder">
      <div className="eyebrow">ROSTER WORKFLOW</div>
      <h1>Page not found</h1>
      <p>This route is not part of the roster workspace.</p>
      <NavLink className="secondary-button" to="/">Return to overview</NavLink>
    </section>
  );
}

function App() {
  return (
    <div className="app-shell">
      <Sidebar />
      <div className="main-column">
        <Topbar />
        <main className="page-content">
          <Routes>
            <Route element={<OverviewPage />} path="/" />
            <Route element={<WorkflowPage description="Set the period and approved scheduling inputs before generation." step="01" title="Roster setup" />} path="/setup" />
            <Route element={<WorkflowPage description="Review the generation outcome and any unresolved constraints." step="02" title="Generation result" />} path="/generation" />
            <Route element={<WorkflowPage description="Review date-ordered shifts and edit assignments in a future slice." step="03" title="Review & edit" />} path="/review" />
            <Route element={<WorkflowPage description="Compare hours, nights, and weekend or holiday assignments." step="04" title="Fairness summary" />} path="/fairness" />
            <Route element={<WorkflowPage description="Inspect coverage, eligibility, overlap, and rest findings." step="05" title="Validation details" />} path="/validation" />
            <Route element={<WorkflowPage description="Publishing outcomes are simulated and never write to ServiceNow." step="06" title="Publish result" />} path="/publish" />
            <Route element={<NotFoundPage />} path="*" />
          </Routes>
        </main>
      </div>
    </div>
  );
}

export default App;
