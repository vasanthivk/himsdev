# config

A single place holding a copy of the configuration files (`.env`, `appsettings.json`) of every HIMS service and frontend app, so they can be reviewed, backed up, or shared without digging through each project folder.

The files here are **copies**. The applications read their config from their own folders; editing a file here changes nothing until it is copied back with `copy_to_app.sh`.

| Script | Direction | Overwrites |
| --- | --- | --- |
| `copy_to_config.sh` | `services/`, `frontend/` → `config/` | Deletes and rebuilds `config/services/` and `config/frontend/` |
| `copy_to_app.sh` | `config/` → `services/`, `frontend/` | The `.env` / `appsettings.json` in each application folder |

Both scripts are Bash (use Git Bash on Windows) and can be run from any directory: they locate the repository root from their own location.

## Layout

`config/` mirrors the folder structure of `services/` and `frontend/`. Each application gets a sub folder of the same name, holding its `.env` and/or `appsettings.json` under the original file name.

```
config/
├── copy_to_config.sh   # apps -> config
├── copy_to_app.sh      # config -> apps
├── CONFIG_README.md
├── services/
│   ├── back-office/appsettings.json
│   ├── clinical-care/appsettings.json
│   ├── comms-docs/appsettings.json
│   ├── digital-engagement/appsettings.json
│   ├── field-ops/appsettings.json
│   ├── hospital-ops/appsettings.json
│   ├── identity-org/appsettings.json
│   ├── imaging/appsettings.json
│   ├── integration/.env
│   ├── laboratory/appsettings.json
│   ├── patient-access/appsettings.json
│   ├── pharmacy-supply/appsettings.json
│   └── revenue-cycle/appsettings.json
└── frontend/
    ├── _shared/            (empty: no config files)
    ├── clinical-care-frontend/.env
    ├── laboratory-frontend/.env
    ├── patient-access-frontend/.env
    ├── revenue-cycle-frontend/.env
    └── shell/.env
```

The .NET services are configured through `appsettings.json`; the integration service (Python) and the frontend apps use `.env`.

## Collecting config from the applications

From the repository root:

```bash
bash config/copy_to_config.sh
```

From inside `config/`:

```bash
bash copy_to_config.sh
```

The script:

1. Deletes `config/services/` and `config/frontend/` if they exist.
2. Creates a sub folder under `config/services/` and `config/frontend/` for every sub folder of `services/` and `frontend/`, including applications that have no config file (their folder is left empty).
3. Copies `.env` and `appsettings.json` from each application folder into its matching sub folder, when present, and prints each file copied.

New services or frontend apps are picked up automatically.

Because step 1 wipes the previous copies, any edit made directly in `config/` that has not been copied back to the application is lost on the next run.

## Copying config back into the applications

Use this on a fresh clone, or after editing a config file here. From the repository root:

```bash
bash config/copy_to_app.sh
```

From inside `config/`:

```bash
bash copy_to_app.sh
```

For each sub folder of `config/services/` and `config/frontend/`, the script copies `.env` and `appsettings.json`, when present, into the folder of the same name under `services/` or `frontend/`, and prints each file copied.

- The application's existing file is **overwritten** without a backup.
- Nothing is deleted: a config file that exists in the application but not in `config/` is left as it is.
- Application folders are never created. A sub folder with no matching application folder is reported as a warning and skipped.
- If `config/services/` or `config/frontend/` is missing, that area is reported as a warning and skipped.

## What is copied

Both scripts handle exactly two file names, set in the `CONFIG_FILE_NAMES` array at the top of each script:

- `.env`
- `appsettings.json`

Only files directly inside an application's top-level folder are considered. Environment-specific or variant files such as `appsettings.Development.json`, `.env.local`, or `.env.example` are not copied, nor are config files in nested folders. To handle another file name, add it to `CONFIG_FILE_NAMES` in **both** scripts.

## Caution: secrets

These files may contain connection strings, API keys, or passwords, so the copies must stay local: only the two scripts and this README are meant to be committed. The root `.gitignore` must list `config/services/` and `config/frontend/`; keep those entries in place, and share the copies only through a secure channel.
