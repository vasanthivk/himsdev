#!/usr/bin/env bash
# Copies frontend/_shared into every zone.
set -euo pipefail
cd "$(dirname "$0")"
for zone in shell patient-access-frontend clinical-care-frontend laboratory-frontend revenue-cycle-frontend; do
  mkdir -p "$zone/lib" "$zone/components" "$zone/app"
  cp _shared/tsconfig.json "$zone/"; cp _shared/lib/api.ts "$zone/lib/"; cp _shared/components/*.tsx "$zone/components/"; cp _shared/app/globals.css "$zone/app/"
  echo "synced $zone"
done
