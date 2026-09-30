# .pids

Runtime PID files written by the dev launcher scripts in [`scripts/`](../scripts/). Each `<name>.pid`
holds one number: the process ID of a service started in the background. These are not source files.

## Which script owns which file

| Script | PID file | Port |
|---|---|---|
| [`scripts/backend.sh`](../scripts/backend.sh) | `identity-org.pid` | 5010 |
| | `patient-access.pid` | 5001 |
| | `clinical-care.pid` | 5002 |
| | `laboratory.pid` | 5003 |
| | `revenue-cycle.pid` | 5006 |
| [`scripts/frontend.sh`](../scripts/frontend.sh) | `shell.pid` | 3000 |
| | `patient-access-frontend.pid` | 3001 |
| | `clinical-care-frontend.pid` | 3002 |
| | `laboratory-frontend.pid` | 3003 |
| | `revenue-cycle-frontend.pid` | 3006 |
| [`scripts/integration.sh`](../scripts/integration.sh) | `integration.pid` | 5011 |

## Lifecycle

- **start** - the script launches each service in the background and writes its PID (`$!`) to
  `.pids/<name>.pid`. Output goes to `logs/<name>.log`.
- **stop** - the script reads the PID, kills that process, and deletes the file. It then kills
  whatever is still listening on the service's port (`netstat` + `taskkill`), since the recorded PID
  can be stale (e.g. a wrapper process that spawned the real server).
- **restart** - stop, wait 5s, start; new PID files are written.

## Notes

- A leftover `.pid` file just means a service was started and not stopped via its script. The next
  `stop` cleans it up; deleting it by hand is harmless.
- The folder is recreated automatically (`mkdir -p .pids`) by every script, and should not be
  committed.
- More detail: [`BACKEND_README.md`](../scripts/BACKEND_README.md),
  [`FRONTEND_README.md`](../scripts/FRONTEND_README.md),
  [`INTEGRATION_README.md`](../scripts/INTEGRATION_README.md).
