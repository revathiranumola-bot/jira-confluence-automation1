import { useState } from "react";
import { NavLink } from "react-router-dom";

function validDate(value) {
  const date = new Date(`${value}T00:00:00Z`);
  return /^\d{4}-\d{2}-\d{2}$/.test(value)
    && !Number.isNaN(date.getTime())
    && date.toISOString().slice(0, 10) === value;
}

export function SetupPage({ initialValues, onSubmit }) {
  const [values, setValues] = useState(() => ({
    startDate: initialValues?.startDate ?? "",
    endDate: initialValues?.endDate ?? "",
    timeZone: initialValues?.timeZone ?? "",
    memberIds: initialValues?.memberIds.join("\n") ?? ""
  }));
  const [errors, setErrors] = useState({});

  function change(event) {
    setValues({ ...values, [event.target.name]: event.target.value });
  }

  function submit(event) {
    event.preventDefault();
    const nextErrors = {};
    if (!validDate(values.startDate)) nextErrors.startDate = "Enter a valid start date.";
    if (!validDate(values.endDate)) nextErrors.endDate = "Enter a valid end date.";
    if (!nextErrors.startDate && !nextErrors.endDate && values.endDate < values.startDate) {
      nextErrors.endDate = "End date must be on or after the start date.";
    }
    const timeZone = values.timeZone.trim();
    if (!timeZone || /^[+-]/.test(timeZone)) {
      nextErrors.timeZone = "Enter a named time zone, such as Asia/Kolkata or UTC.";
    } else {
      try {
        new Intl.DateTimeFormat("en", { timeZone }).format();
      } catch (error) {
        if (!(error instanceof RangeError)) throw error;
        nextErrors.timeZone = "Enter a recognized named time zone, such as Asia/Kolkata or UTC.";
      }
    }
    const memberIds = values.memberIds.split(/\r?\n/).map(value => value.trim()).filter(Boolean);
    if (memberIds.length === 0) {
      nextErrors.memberIds = "Enter at least one approved local demo member ID.";
    } else if (new Set(memberIds).size !== memberIds.length) {
      nextErrors.memberIds = "Member IDs must be unique.";
    }
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length === 0) {
      onSubmit({ startDate: values.startDate, endDate: values.endDate, timeZone, memberIds });
    }
  }

  function errorProps(name) {
    return {
      "aria-invalid": Boolean(errors[name]),
      "aria-describedby": errors[name] ? `${name}-error` : undefined
    };
  }

  return (
    <section className="workflow-placeholder">
      <div className="eyebrow">ROSTER WORKFLOW · STEP 01</div>
      <h1>Roster setup</h1>
      <p>Enter local demo inputs to preview a setup summary. No roster is generated or saved.</p>
      <div className="prototype-banner compact">
        <div>
          <strong>Local-only setup preview</strong>
          <p>Use demo IDs only. Membership and eligibility are not verified. Inputs stay in memory and are lost on reload. No ServiceNow changes are made.</p>
        </div>
      </div>
      <form className="setup-form panel" noValidate onSubmit={submit}>
        {Object.keys(errors).length > 0 && (
          <div role="alert">Setup was not submitted. Correct the fields below.</div>
        )}
        <label htmlFor="startDate">Start date (required)</label>
        <input id="startDate" name="startDate" type="date" required value={values.startDate} onChange={change} {...errorProps("startDate")} />
        {errors.startDate && <p className="field-error" id="startDate-error">{errors.startDate}</p>}

        <label htmlFor="endDate">End date (required)</label>
        <input id="endDate" name="endDate" type="date" required value={values.endDate} onChange={change} {...errorProps("endDate")} />
        {errors.endDate && <p className="field-error" id="endDate-error">{errors.endDate}</p>}

        <label htmlFor="timeZone">Time zone (required)</label>
        <input id="timeZone" name="timeZone" type="text" placeholder="Asia/Kolkata or UTC" required value={values.timeZone} onChange={change} {...errorProps("timeZone")} />
        {errors.timeZone && <p className="field-error" id="timeZone-error">{errors.timeZone}</p>}

        <label htmlFor="memberIds">Local demo member IDs (required, one per line)</label>
        <textarea id="memberIds" name="memberIds" rows={4} required value={values.memberIds} onChange={change} {...errorProps("memberIds")} />
        {errors.memberIds && <p className="field-error" id="memberIds-error">{errors.memberIds}</p>}

        <button className="primary-button" type="submit">Preview setup</button>
      </form>
      <NavLink className="secondary-button" to="/">Back to roster overview</NavLink>
    </section>
  );
}

export function SetupResultPage({ setup }) {
  return (
    <section className="workflow-placeholder">
      <div className="eyebrow">ROSTER WORKFLOW · STEP 02</div>
      <h1>Generation result</h1>
      {setup ? (
        <>
          <h2>Setup summary</h2>
          <p role="status">Setup inputs accepted for preview only. No roster has been generated or saved.</p>
          <dl className="setup-summary panel">
            <dt>Start date</dt><dd>{setup.startDate}</dd>
            <dt>End date</dt><dd>{setup.endDate}</dd>
            <dt>Time zone</dt><dd>{setup.timeZone}</dd>
            <dt>Local demo member IDs (unverified)</dt>
            <dd><ul>{setup.memberIds.map(id => <li key={id}>{id}</li>)}</ul></dd>
          </dl>
          <p>Eligibility, availability, coverage, rest, and fairness have not been checked. No ServiceNow changes are made. This preview is lost on reload.</p>
          <NavLink className="secondary-button" to="/setup">Edit setup</NavLink>
        </>
      ) : (
        <>
          <p>No setup preview is available. Enter the setup inputs first. No roster has been generated or saved.</p>
          <NavLink className="primary-button" to="/setup">Start roster setup</NavLink>
        </>
      )}
    </section>
  );
}
