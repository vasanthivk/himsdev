# config_files

A single place holding a copy of the configuration files of every HIMS application, so they can be reviewed, backed up, or shared without digging through each project folder.

The files here are **copies**. The applications still read their config from their own folders; editing a file here does not change how an app runs.

## Layout

`config_files/` mirrors the folder structure of `services/` and `frontend/`. Each application gets a sub folder of the same name, holding its `.env` and/or `appsettings.json` with the original file names.

```
config_files/
├── config_files.sh               # apps -> config_files
├── copy_config_files_to_app.sh  # config_files -> apps
├── CONFIG_FILES_README.md
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
    ├── _shared/                  (empty: no config files)
    ├── clinical-care-frontend/.env
    ├── laboratory-frontend/.env
    ├── patient-access-frontend/.env
    ├── revenue-cycle-frontend/.env
    └── shell/.env
```

The .NET services are configured through `appsettings.json`; the integration service (Python) and the frontend apps use `.env`.

## Refreshing the copies

Run from any directory (Git Bash on Windows):

```bash
bash config_files/config_files.sh
```

The script:

1. Deletes `config_files/services/` and `config_files/frontend/` if they exist.
2. Creates a sub folder in `config_files/services/` and `config_files/frontend/` for every sub folder of `services/` and `frontend/`.
3. Copies `.env` and `appsettings.json` from each application folder into its matching sub folder, when present.

New services or frontend apps are picked up automatically. Only the base `appsettings.json` is copied; environment-specific files such as `appsettings.Development.json` are not.

## Copying config back into the applications

To push the files in `config_files/` back into the application folders (for example on a fresh clone, or after editing a config here):

```bash
bash config_files/copy_config_files_to_app.sh
```

The script copies `.env` and `appsettings.json` from each sub folder of `config_files/services/` and `config_files/frontend/` into the matching folder under `services/` and `frontend/`, **overwriting** the application's existing file. A sub folder with no matching application folder is reported as a warning and skipped; application folders are never created.

## Caution: secrets

These files may contain connection strings, API keys, or passwords. `config_files/services/` and `config_files/frontend/` are listed in the root `.gitignore`, so the copies stay local; only the script and this README are committed. Keep those entries in place.
