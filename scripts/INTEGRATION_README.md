# integration.sh — manage the Python Integration Hub

Starts, stops and restarts the Integration Hub (`services/integration`) on port 5011, running it
in the background and logging to a file — unlike `run-integration-hub.sh`, which runs it in the
foreground for interactive debugging. Use whichever fits what you're doing (see below).

```bash
cd hims
sed -i 's/\r$//' scripts/integration.sh   # only needed once, if the file has Windows line endings
chmod +x scripts/integration.sh           # only needed once
```

Logs: `./logs/integration.log`
PID: `./.pids/integration.pid`

## Commands

```bash
./scripts/integration.sh start              # start (sets up venv/deps on first run)
./scripts/integration.sh start --install    # force a fresh pip install first, then start

./scripts/integration.sh stop               # stop it

./scripts/integration.sh restart            # stop -> wait 5s -> start
./scripts/integration.sh restart --install  # stop -> wait 5s -> pip install -> start

./scripts/integration.sh status             # check /health (prints the JSON body too)
```

### This script vs. `run-integration-hub.sh`

| | `integration.sh` | `run-integration-hub.sh` |
|---|---|---|
| Runs | in the background | in the foreground (Ctrl+C to stop) |
| Output | `logs/integration.log` | your terminal, live |
| Fits with | `backend.sh`, `frontend.sh` (fully backgrounded stack) | active debugging, watching resets/reconnects as they happen |
| Stop | `./scripts/integration.sh stop` | Ctrl+C |

While chasing a live issue (like a RabbitMQ connection reset), `run-integration-hub.sh` is usually
more convenient — you see everything as it happens. Once things are stable and you just want it
running quietly alongside everything else, `integration.sh` is the better fit.

### Which one do I want?

| Situation | Command |
|---|---|
| First time, or `.env`/`requirements.txt` changed | `start` (or `start --install` if you added a package) |
| Code in `services/integration/app/` changed | `restart` (uvicorn doesn't hot-reload without `--reload`, which this script intentionally doesn't use, to match production-like behaviour) |
| Added a package to `requirements.txt` | `restart --install` |
| "Is it up? What does /health say?" | `status` |

## What `start` actually does

1. Checks `services/integration/.env` exists; if not, stops and tells you to copy
   `.env.example` first.
2. Creates `.venv` if it doesn't exist yet (`python -m venv .venv`).
3. Activates it (`.venv/Scripts/activate` on Windows, `.venv/bin/activate` elsewhere).
4. Installs dependencies only if `fastapi` isn't already importable, or if `--install` was passed.
5. Loads `.env` into the environment (`set -a; source .env; set +a`) and prints `RABBITMQ_URL` and
   `DATABASE_URL` so you can visually confirm the right values loaded.
6. Starts `uvicorn app.main:app --port 5011` in the background, logging to `logs/integration.log`,
   and records its PID to `.pids/integration.pid`.

## What `stop` actually does

1. If a PID file exists, sends that process a `kill` signal and deletes the PID file.
2. As a fallback, checks port 5011 directly (`netstat`) and force-kills whatever is listening
   there (`taskkill //F`), in case the PID file is stale or the hub was started some other way
   (e.g. manually with `run-integration-hub.sh`, or an older script).

## What `restart` actually does

Exactly `stop`, then a fixed 5-second pause, then `start` (or the `--install` variant). The pause
gives port 5011 time to fully release, and gives any in-flight RabbitMQ connections time to close
cleanly, before the new process tries to bind and reconnect.

## What `status` actually does

Calls `GET /health` and prints `UP`/`NOT RESPONDING` plus the raw JSON response, which looks like:
```json
{"service":"integration","status":"healthy","database":true,"workers":{"relay":true,"device":true,"fhir":true},"fhir":null}
```
- `database: true` — hub's own PostgreSQL connection is fine.
- `workers.relay/device/fhir: true` — all three RabbitMQ connections (outbox relay, device
  message consumer, FHIR-sync consumer) are currently connected.
- `fhir: null` — only populated by `/health?deep=true`, which actually pings HAPI FHIR:
```bash
  curl -s "localhost:5011/health?deep=true"
```

If `workers.*` shows `false` even though `status` overall says healthy, the hub's HTTP API and
database are fine but its RabbitMQ connections have dropped — check `logs/integration.log` for
`BrokerUnreachableException` or `ConnectionResetError` near the current time.

## Watching logs live

```bash
tail -f logs/integration.log
```

Useful right after `start`/`restart` to confirm the three RabbitMQ connections come up cleanly: