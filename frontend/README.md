# HIMS frontend - Next.js multi-zones

One Next.js app per microservice, stitched together by a shell (`shell`, port 3000) so users see a single site.

| Folder | Port | URL prefix | Backend it talks to |
|---|---|---|---|
| `shell` | 3000 | `/` | health of all services; reference-data bootstrap |
| `patient-engagement-frontend` | 3001 | `/patient-engagement` | Patient Access (5001) |
| `clinical-care-frontend` | 3002 | `/clinical-care` | Clinical Care (5002), Laboratory (5003, results), Patient Access (5001, close visit) |
| `diagnostics-frontend` | 3003 | `/diagnostics` | Laboratory (5003), Revenue Cycle (5006, paid status), Integration Hub (5011, simulator) |
| `revenue-finance-frontend` | 3006 | `/revenue-finance` | Revenue Cycle (5006) |

Run each with `npm install && npm run dev` (from its folder). Open http://localhost:3000.
Each zone sets `basePath` to its prefix; the shell rewrites that prefix to the zone. Links between zones are plain `<a>` tags.

`_shared/` holds the files every zone repeats (`lib/api.ts`, `components/`, `app/globals.css`, `tsconfig.json`). They are
copied into each zone, so after editing `_shared` run `./sync-shared.sh`. (A monorepo package would remove the copies.)

The browser calls the microservices directly (CORS is configured in each service via `Cors:Origins`). Override the URLs with
`NEXT_PUBLIC_*_API` environment variables at build time.
