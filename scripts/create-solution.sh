#!/usr/bin/env bash
# Creates hims.sln (open it in Visual Studio / Rider) containing Hims.Common and the 6 .NET services.
set -euo pipefail
cd "$(dirname "$0")/.."
dotnet new sln -n hims --force
dotnet sln hims.sln add shared/Hims.Common/Hims.Common.csproj
for p in services/*/Hims.*.csproj; do dotnet sln hims.sln add "$p"; done
