# frontend.sh — manage the HIMS frontend zones

One script to start, stop, restart and check all five Next.js zones. Run it from anywhere inside
the repo; it `cd`s to the project root itself.

```bash
cd hims
sed -i 's/\r$//' scripts/frontend.sh   # only needed once, if the file has Windows line endings
chmod +x scripts/frontend.sh           # only needed once
```

## What it manages

| Zone | Port | Role |
|---|---|---|
| shell | 3000 | public entry point; forwards to the other four |
| patient-engagement-frontend | 3001 | Patient Access |
| clinical-care-frontend | 3002 | Doctor / Clinical Care |
| diagnostics-frontend | 3003 | Laboratory |
| revenue-finance-frontend | 3006 | Billing |

Logs: `./logs/<zone>.log`
PIDs: `./.pids/<zone>.pid`

Open **http://localhost:3000** once everything is up — that's the only address you need; it
forwards `/patient-engagement`, `/clinical-care`, `/diagnostics` and `/revenue-finance` to the matching
zone.

## Commands

```bash
./scripts/frontend.sh start              # install deps (only zones missing node_modules) + start
./scripts/frontend.sh start --install    # force a fresh npm install in every zone, then start

./scripts/frontend.sh stop               # stop everything

./scripts/frontend.sh restart            # stop -> wait 5s -> start
./scripts/frontend.sh restart --install  # stop -> wait 5s -> npm install -> start

./scripts/frontend.sh status             # check each zone's home page returns HTTP 200
```

### Which one do I want?

| Situation | Command |
|---|---|
| You edited any `.tsx`/`.ts`/`.css` file | Nothing needed — Next.js hot-reloads automatically while `npm run dev` is running |
| You added or changed a package in `package.json` | `restart --install` |
| You just want a clean restart | `restart` |
| Starting fresh for the day | `start` |
| "Is everything up?" | `status` |

Note that unlike the backend, frontend code changes **don't need a restart** at all in normal
development — `npm run dev` watches files and rebuilds on save. You only need this script to
actually start/stop the five dev servers, or to pick up a new dependency.

## What `start` actually does

For each of the five zones, in order (shell, patient-engagement-frontend, clinical-care-frontend,
diagnostics-frontend, revenue-finance-frontend):
1. Installs dependencies with `npm install` only if `node_modules` is missing, or if `--install`
   was passed (forces it for every zone regardless).
2. Starts `npm run dev` in the background, logging to `logs/<zone>.log` and recording its PID to
   `.pids/<zone>.pid`.

First run installs dependencies in all five zones, which is slow — subsequent runs skip install
and start in a few seconds.

## What `stop` actually does

For each of the five zones:
1. If a PID file exists, sends that process a `kill` signal and deletes the PID file.
2. As a fallback, checks the zone's port directly (`netstat`) and force-kills whatever is
   listening there (`taskkill //F`), in case the PID file is stale or the process was started some
   other way.

## What `restart` actually does

Exactly `stop`, then a fixed 5-second pause, then `start` (or the `--install` variant).
The pause gives ports time to fully release before the new dev servers try to bind them.

## What `status` actually does

Requests each zone's own port directly (not through the shell's rewrites) and reports `UP` (HTTP
200) or `NOT RESPONDING` with whatever status code came back. A zone can be "UP" here while still
showing errors in the browser if a backend API it depends on is down — this only confirms the
Next.js dev server itself is serving pages.

## Watching logs live

```bash
tail -f logs/shell.log
tail -f logs/diagnostics-frontend.log
```

Watch a zone's log right after starting it — first compile typically takes 10-30 seconds per zone,
and errors (missing imports, type errors) show up here first.

## Troubleshooting

**A zone's port is still occupied after `stop`**
`npm run dev` can spawn a child Next.js process; killing the parent PID usually kills the child
too, but not always. Check manually:
```bash
netstat -ano | grep ":3003 "
taskkill //PID <pid-shown> //F
```

**"Cannot reach the service" errors in the browser**
The frontend calls each backend microservice directly from the browser (not through the shell).
Check the backend services are actually running:
```bash
./scripts/backend.sh status
```

**A zone shows blank or a build error right after `start`**
Check its log — first compile can be slow, and TypeScript/lint errors are printed there, not in
the terminal that launched it:
```bash
tail -f logs/<zone>.log
```

**Changes to `frontend/_shared/` aren't showing up in a zone**
Those files are *copied* into each zone (`lib/api.ts`, `components/`, `app/globals.css`,
`tsconfig.json`), not shared by reference. After editing `_shared/`, run:
```bash
./frontend/sync-shared.sh
```
then restart the affected zone(s) if they were already running.