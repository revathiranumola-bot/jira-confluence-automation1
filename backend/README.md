# CPS On-Call Roster Backend

Local prototype API package using Node.js 24.22.0 and Express 5.3.0. The
server binds to `127.0.0.1` only. This scaffold has no database or external
service integration; in particular, it cannot write to ServiceNow.

## Requirements

- Node.js 24.22.0
- npm 11.19.1

## Setup and commands

In a new PowerShell terminal, select the pinned Node.js version and confirm
both tools are available on `PATH`:

```powershell
nvm use 24.22.0
node --version
npm.cmd --version
```

From this directory, install the lockfile dependencies and start the local
development server:

```powershell
npm.cmd ci
npm.cmd run dev
```

For a non-watch startup, run `npm.cmd start`. The server defaults to port
`3001`; set `PORT` in the process environment to use another port from 1
through 65535. For example:

```powershell
$env:PORT = "3100"
npm.cmd start
```

Run the backend checks with:

```powershell
npm.cmd test
npm.cmd run lint
```

`../tests/api/backend-app.test.js` exercises the local app using Node's built-in
test runner. `.env.example` documents local environment values; copy it only
for reference and do not commit `.env` files or credentials.

The server is intentionally localhost-only and the current identity is not
production authentication. Do not expose it beyond local development. Live
ServiceNow publishing is out of scope; future publishing must remain behind a
mock adapter unless a separate production integration decision is approved.

## PostgreSQL development database

From the repository root, copy `.env.example` to `.env`, replace the
placeholder password with a unique local-only value, then start PostgreSQL:

```powershell
Copy-Item .env.example .env
docker compose config
docker compose up -d db
docker compose ps
docker compose exec -T db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

The database port binds only to localhost and its data is kept in the named
`postgres_data` volume. No reset or volume-deletion command is run
automatically.
