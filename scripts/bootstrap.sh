#!/usr/bin/env bash
# Initial bulk load of every ref.* table (data-model README: "bulk load each ref table from the owning service before event streaming").
# Same as the "Load reference data" button on http://localhost:3000. Safe to repeat.
set -euo pipefail
IDENTITY=${IDENTITY_ORG_URL:-https://localhost:7010}
REVENUE=${REVENUE_CYCLE_URL:-https://localhost:7006}
echo "identity-org  : $(curl -fsSk -X POST "$IDENTITY/api/admin/republish")"
echo "revenue-cycle : $(curl -fsSk -X POST "$REVENUE/api/admin/republish")"
