# CPS On-Call Roster Frontend

React 18.3.1 and Vite 8.3.4 prototype UI. Roster setup accepts explicit start
and end dates, a named time zone, and unique local demo member IDs (one per
line). "Preview setup" validates these inputs and displays a setup summary
on the generation-result route. "Edit setup" retains the inputs.
This is an in-memory preview only: reloading clears the inputs and summary.
It does not generate or persist a roster, verify team eligibility, or check
scheduling constraints. Other workflow screens remain presentation shells;
no roster records or team identities are fabricated.
Publishing is labelled as simulated and does not call ServiceNow.

## Requirements

- Node.js 24.22.0
- npm 11.19.1

## Run locally

From a PowerShell terminal, select the pinned Node version, then start Vite:

```powershell
nvm use 24.22.0
npm.cmd ci
npm.cmd run dev
```

Vite binds to `127.0.0.1` and prints the local URL (by default,
`http://127.0.0.1:5173/`). `VITE_API_BASE_URL` may be set for future API
integration; no credentials belong in frontend environment variables.

## Checks

```powershell
npm.cmd test
npm.cmd run lint
npm.cmd run build
```
