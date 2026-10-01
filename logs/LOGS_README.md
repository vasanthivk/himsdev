# logs

Runtime logs of every HIMS application. Each service writes its own logs into a sub folder named after the service, with **one file per day**.

Log files (`*.log`) are git-ignored (`logs/**/*.log` in `.gitignore`); only this README is tracked.

## Layout

```
logs/
├── LOGS_README.md
├── integration/                  # Python Integration Hub (services/integration)
│   ├── 30-09-2026.log            # everything, for that day
│   ├── 30-09-2026-error.log      # only ERROR and CRITICAL entries, for that day
│   └── console.log               # raw stdout/stderr captured by scripts/integration.sh
├── patient-access/               # every .NET service (services/<name>)
│   ├── 30-09-2026.log            # everything, for that day
│   └── 30-09-2026-error.log      # only ERROR and CRITICAL entries, for that day
├── laboratory/
│   └── ...
├── <service>.log                 # raw stdout/stderr of .NET services started by scripts/backend.sh
└── <zone>.log                    # front-ends started by scripts/frontend.sh (e.g. shell.log, laboratory-frontend.log)
```

File names use the **local date** of the machine in `dd-MM-yyyy` format. A new file is started automatically when the date changes; nothing needs restarting.

## What goes where

### .NET services

back-office, clinical-care, comms-docs, digital-engagement, field-ops, hospital-ops, identity-org, imaging, laboratory, patient-access, pharmacy-supply, revenue-cycle.

| File | Contents |
|---|---|
| `logs/<service>/dd-MM-yyyy.log` | All log entries at or above the configured level (default `Information`, `Microsoft.AspNetCore` at `Warning`). |
| `logs/<service>/dd-MM-yyyy-error.log` | Only `Error` and `Critical` entries: failed requests, event handler failures, startup failures, unhandled exceptions. Created on the first error of the day, so a day without errors has no error file. |
| `logs/<service>.log` | Console output of the process when started with `scripts/backend.sh` (same lines as the dated file). |

Errors appear in **both** dated files, so the main file still shows what happened around each error.

Implemented in `shared/Hims.Common/Logging/DailyFileLogger.cs` and switched on in each service's `Program.cs`:

```csharp
builder.AddHimsFileLogging("patient-access");   // logs/patient-access/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
```

To add it to a new service, add `using Hims.Common.Logging;` and that line before `AddHimsService`.

### Integration Hub (Python)

| File | Contents |
|---|---|
| `logs/integration/dd-MM-yyyy.log` | All log entries of the hub, including uvicorn server/access logs and uncaught exceptions in any thread (`CRITICAL hub.crash`). |
| `logs/integration/dd-MM-yyyy-error.log` | Only `ERROR` and `CRITICAL` entries: message processing failures, broker/database errors, failed requests, uncaught exceptions. Created on the first error of the day. |
| `logs/integration/console.log` | Raw stdout/stderr captured by `scripts/integration.sh`. The only place that shows errors raised **before** logging starts (syntax errors, missing packages, bad settings). Check it when the hub will not start at all. |

Errors appear in both dated files, as for the .NET services. Implemented in `services/integration/app/logging_setup.py`.

## Line format

```
2026-09-30 17:22:43.651 INFO     Microsoft.Hosting.Lifetime: Now listening on: http://0.0.0.0:5001     (.NET)
2026-09-30 17:01:06,677 INFO    hub.bus: Published 3 event(s) from outbox                             (Python)
```

Timestamp (local time), level, logger/category name, message. Exceptions follow on the next lines with the full stack trace.

## Watching logs

```bash
tail -F logs/patient-access/$(date +%d-%m-%Y).log         # everything, live
tail -F logs/patient-access/$(date +%d-%m-%Y)-error.log   # errors only, live
./scripts/integration.sh start                            # starts the hub and tails today's file
```

`tail -F` (capital F) keeps following when the file is created later. The files are opened with shared read access, so they can be opened in an editor while the service is running.

## Changing the log folder

| App | Setting | Default |
|---|---|---|
| .NET services | `Logging:File:Directory` in `appsettings.json`, or env var `Logging__File__Directory` | `../../logs/<service>` from the project folder |
| Integration Hub | `LOG_DIR` in `.env` | `../../logs/integration` from `services/integration` |

Relative paths are resolved from the project folder (.NET) or the working directory (Python). The log level of the .NET file logs follows `Logging:LogLevel`; set `Logging:File:LogLevel` to give the files their own levels.

## Docker

Inside a container the default paths do not point at this folder, and the container clock is UTC. To get the same dated files on the host, set the log directory and `TZ`, and mount a volume, e.g. for the `integration` service in `docker-compose.yml`:

```yaml
    environment:
      LOG_DIR: /srv/logs
      TZ: Asia/Kolkata
    volumes:
      - ./logs/integration:/srv/logs
```

For a .NET service use `Logging__File__Directory: /app/logs` and mount `./logs/<service>:/app/logs`. Console output is always available through `docker logs <container>`.

## Housekeeping

Old dated files are not deleted automatically. Remove them by hand when no longer needed, e.g. files older than 30 days:

```bash
find logs -name "*.log" -mtime +30 -delete
```
