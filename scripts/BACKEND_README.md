# backend.sh — manage the HIMS backend services

One script to start, stop, restart and check the five .NET workflow services and the Python
Integration Hub. Run it from anywhere inside the repo; it `cd`s to the project root itself.

```bash
cd hims
sed -i 's/\r$//' scripts/backend.sh   # only needed once, if the file has Windows line endings
chmod +x scripts/backend.sh           # only needed once
```

## What it manages

| Service | Port | Type |
|---|---|---|
| identity-org | 5010 | .NET |
| patient-access | 5001 | .NET |
| clinical-care | 5002 | .NET |
| revenue-cycle | 5006 | .NET |
| laboratory | 5003 | .NET |
| integration (Integration Hub) | 5011 | Python |

Logs: `./logs/<service>.log`
PIDs: `./.pids/<service>.pid`

## Commands

```bash
./scripts/backend.sh start              # build all .NET projects, then start everything
./scripts/backend.sh start --no-build   # start everything, skipping the .NET build (fast)

./scripts/backend.sh stop               # stop everything

./scripts/backend.sh restart            # stop -> wait 5s -> build -> start
./scripts/backend.sh restart --no-build # stop -> wait 5s -> start (no build)

./scripts/backend.sh status             # check /health on all six services
```

### Which one do I want?

| Situation | Command |
|---|---|
| You edited any `.cs` file in a service or in `shared/Hims.Common` | `restart` (rebuilds, so the change takes effect) |
| You just want a clean restart and nothing changed | `restart --no-build` (fast) |
| Starting fresh for the day, code unchanged since last run | `start --no-build` |
| First run, or after pulling new code | `start` |
| "Is everything up?" | `status` |

## What `start` actually does

1. **Build** (skipped with `--no-build`): runs `dotnet build` for `shared/Hims.Common` and every
   service project under `services/`, one at a time, quiet output. Stops immediately if any project
   fails to build — nothing is started on a broken build.
2. **Start .NET services**: runs `dotnet run --no-build` for identity-org, patient-access,
   clinical-care, revenue-cycle and laboratory, each in the background, logging to
   `logs/<service>.log` and recording its PID to `.pids/<service>.pid`.
3. **Start the Integration Hub**: activates `services/integration/.venv` (created automatically by
   `run-integration-hub.sh` if you've used it before; see below if you haven't), installs
   dependencies only if `fastapi` isn't already importable, loads `services/integration/.env`, then
   starts `uvicorn app.main:app --port 5011` in the background, logging to `logs/integration.log`.

If `services/integration/.env` doesn't exist, the hub is skipped with a message telling you to create
it first (or restore it with `config_files/copy_config_files_to_app.sh`) — the other five .NET services still start normally.

## What `stop` actually does

For each of the six services:
1. If a PID file exists, sends that process a `kill` signal and deletes the PID file.
2. As a fallback, checks the service's port directly (`netstat`) and force-kills whatever is
   listening there (`taskkill //F`), in case the PID file is stale or the process was started some
   other way (e.g. manually, or by an older script).

This means `stop` cleans up stray processes too, not just ones this script itself started.

## What `restart` actually does

Exactly `stop`, then a fixed 5-second pause, then `start` (or the `--no-build` variant of each).
The pause gives ports time to fully release before the new processes try to bind them.

## What `status` actually does

Calls `GET /health` on each of the six services and prints `UP` (HTTP 200) or `NOT RESPONDING`
(anything else, including connection refused). This only confirms the HTTP API and database
connectivity — it does **not** confirm RabbitMQ connectivity for a service. To check that, look at
the service's own log:

```bash
grep -i "consuming\|BrokerUnreachable" logs/laboratory.log | tail -10
```

## Watching logs live

Since services run in the background, tail the log file to watch output as it happens:

```bash
tail -f logs/laboratory.log
tail -f logs/integration.log
```

## Troubleshooting

**"No such file or directory" for a `.pid` file when stopping**
Normal if the service was never started by this script, or was already stopped. `stop` still
sweeps the port as a fallback, so this is informational, not an error.

**A service's port is still occupied after `stop`**
`dotnet run` spawns a child process; killing the parent PID usually kills the child too, but not
always. Check manually:
```bash
netstat -ano | grep ":5003 "
taskkill //PID <pid-shown> //F
```

**Hub fails to start with a `ModuleNotFoundError`**
The virtual environment wasn't set up yet. Run `./scripts/run-integration-hub.sh` once by hand
first (it creates `.venv` and installs dependencies), then `backend.sh` will find it on future runs.

**Hub starts but shows wrong `RABBITMQ_URL`/`DATABASE_URL`**
Check `services/integration/.env` — any value containing a space must be double-quoted
(e.g. `SOME_NAME="two words"`), or bash will misparse the file when it's
sourced.

**A .NET service fails to build**
`start`/`restart` (without `--no-build`) stops immediately and shows the compiler error. Fix the
code, then re-run — nothing was started on the broken build, so there's no stale process to clean
up first.
## HTTPS

The .NET services serve **HTTPS only** (no HTTP port): patient-access 7001, clinical-care 7002, laboratory 7003,
revenue-cycle 7006, identity-org 7010 (the other services likewise on their old HTTP port + 2000, 7004-7013). Swagger is at
`https://localhost:<port>/swagger`. The Integration Hub still serves both HTTP 5011 and HTTPS 7011: the Open Integration
Engine device channels, the laboratory service and the simulator call it on HTTP.

- .NET services: `Kestrel:Endpoints:Https` in each `appsettings.json` (with `../../certs/hims-local.pfx`).
- Integration Hub: `scripts/integration.sh` runs `python -m app.serve`, which serves HTTP and, when
  `certs/hims-local.crt.pem` + `.key.pem` exist, HTTPS in the same process (background workers start once).

`certs/` is git-ignored (private key). The certificate is self-signed, valid for `localhost`, `*.localhost`, `Admin.mshome.net`, `127.0.0.1`
and `172.17.176.1` (the Windows host as seen from WSL). To recreate it (PowerShell, repo root):

```powershell
New-Item -ItemType Directory -Force certs | Out-Null
$cert = New-SelfSignedCertificate -Subject "CN=hims-local" -CertStoreLocation Cert:\CurrentUser\My `
  -TextExtension @("2.5.29.17={text}DNS=localhost&DNS=*.localhost&DNS=Admin.mshome.net&IPAddress=127.0.0.1&IPAddress=172.17.176.1", "2.5.29.37={text}1.3.6.1.5.5.7.3.1") `
  -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(2)
$pwd = ConvertTo-SecureString "changeit" -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath certs\hims-local.pfx -Password $pwd
Export-Certificate    -Cert $cert -FilePath certs\hims-local.cer
```

then, in Git Bash: `openssl pkcs12 -in certs/hims-local.pfx -passin pass:changeit -nokeys -clcerts -out certs/hims-local.crt.pem`
and `openssl pkcs12 -in certs/hims-local.pfx -passin pass:changeit -nocerts -nodes -out certs/hims-local.key.pem`.

WSO2 API Manager (in WSL) must trust it before its endpoints can use `https://Admin.mshome.net:70xx`. Use that name, not the IP:
the gateway reverse-resolves the IP to `Admin.mshome.net` (the Windows host as WSL sees it; `<COMPUTERNAME>.mshome.net`) and checks
the certificate against it - and the name keeps working when WSL's IP changes. Import (or after recreating: `keytool -delete -alias hims-local ...` first):

```bash
keytool -import -noprompt -alias hims-local -file /mnt/d/Projects/2026/himspoc/himspoc/certs/hims-local.cer \
  -keystore ~/wso2am-4.6.0/repository/resources/security/client-truststore.jks -storepass wso2carbon
```

and restart API Manager.

## Authentication modes (WSO2_AUTHENTICATION)

`Auth:Enabled` switches authentication on or off; `WSO2_AUTHENTICATION` (top level of each service's `appsettings.json`)
picks how callers are authenticated. Set the **same value** in the frontends' `.env` files and restart everything.

| `WSO2_AUTHENTICATION` | Frontend calls | Service accepts |
| --- | --- | --- |
| `true` | the WSO2 API Manager gateway (`NEXT_PUBLIC_*_API`) after WSO2 Identity Server sign-in | only the gateway's backend JWT (`X-JWT-Assertion`, checked against `Auth:*`) |
| `false` | the services directly (`NEXT_PUBLIC_*_SERVICE`) after signing in on HIMS's `/login` page | only a HIMS JWT (`Authorization: Bearer`, checked against `Jwt:*`) |

HIMS's own login (`false`) lives in Identity & Org: `POST /api/auth/login` (username + password from `sec.user_account`,
roles from `sec.user_role`/`sec.role`, session in `sec.user_session`; 5 wrong passwords lock the account),
`POST /api/auth/logout`, and `POST /api/auth/users` (ADMIN only) to create users with role codes such as FRONT_OFFICE,
BILLING, DOCTOR, LAB_TECH. Passwords are stored as PBKDF2-SHA256 hashes. While `sec.user_account` is empty, Identity & Org
creates the ADMIN role and the `Jwt:BootstrapAdmin` user at startup - change that password and remove the entry afterwards.
All services share `Jwt:SigningKey` (HMAC-SHA256); keep it secret and identical everywhere.
