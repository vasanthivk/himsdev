#!/usr/bin/env python3
"""Writes the boilerplate every .NET microservice shares: csproj, appsettings.json, Dockerfile and (for services that
have no hand-written workflow code) Program.cs. Hand-written Program.cs files are never overwritten."""
import pathlib, json, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from gen_entities import SERVICES, ROOT

TITLES = {
 "patient-access":     ("Patient Access", "Front office: UHID/MPI, consent, appointments, queue/token, encounters, admission and bed management."),
 "clinical-care":      ("Clinical Care", "EMR, CPOE orders, e-prescriptions, nursing, ICU, emergency, OT, transfusion and diet orders."),
 "laboratory":         ("Laboratory (LIMS & Blood Centre)", "Test catalogue, samples, analyzers and worklists, results, QC, reports; blood centre."),
 "imaging":            ("Imaging (RIMS + PACS)", "Radiology procedures, modalities, scheduling, reporting and the PACS/DICOM index."),
 "pharmacy-supply":    ("Pharmacy & Supply Chain", "Drug/item master, stores and stock, purchasing, GRN, dispensing, narcotics register, CSSD."),
 "revenue-cycle":      ("Revenue Cycle", "Service catalogue, tariffs, bills and charge capture, receipts, insurance pre-auth and claims."),
 "digital-engagement": ("Digital Engagement", "E-commerce, teleconsultation, remote monitoring, CRM and medical camps."),
 "field-ops":          ("Field Operations", "Ambulance, home collection/delivery, fleet, trips, GPS and cold-chain."),
 "hospital-ops":       ("Hospital Operations & Quality", "Assets, maintenance, housekeeping, linen, kitchen, complaints, incidents and quality."),
 "identity-org":       ("Identity, Organization & Reference Data", "Organization, branches, departments, staff and practitioner registry, users and roles, terminology."),
 "comms-docs":         ("Communication & Documents", "Document index, letterheads, notifications and delivery tracking."),
 "back-office":        ("Back Office", "Finance, HRMS, campus and IT helpdesk (optional; normally bought and integrated)."),
}
HANDWRITTEN_PROGRAM = {"patient-access", "clinical-care", "laboratory", "revenue-cycle", "identity-org"}
EXTRA_SETTINGS = {
    "laboratory": {
        "IntegrationHub": {"BaseUrl": "http://localhost:5011/"},
        "Laboratory": {"AutoVerify": True},
    },
}
ALL_ORIGINS = ["http://localhost:%d" % p for p in [3000] + list(range(3001, 3014))]

for num, stem, slug, ns, port in SERVICES:
    if ns is None: continue
    d = ROOT / "services" / slug; d.mkdir(parents=True, exist_ok=True)
    title, desc = TITLES[slug]
    db = "hims_" + stem.split("_", 1)[1]
    (d / f"Hims.{ns}.csproj").write_text(f"""<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <RootNamespace>Hims.{ns}</RootNamespace>
    <AssemblyName>Hims.{ns}</AssemblyName>
    <!-- Feeds the /// comments into Swagger UI -->
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    <NoWarn>$(NoWarn);1591</NoWarn>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\\..\\shared\\Hims.Common\\Hims.Common.csproj" />
  </ItemGroup>

</Project>
""")
    (d / "appsettings.json").write_text(json.dumps({
        "Logging": {"LogLevel": {"Default": "Information", "Microsoft.AspNetCore": "Warning"}},
        "AllowedHosts": "*",
        "Urls": f"http://0.0.0.0:{port}",
        "ConnectionStrings": {"Default": f"Host=103.169.179.22;Port=50085;Database={db};Username=hims;Password=xv7o4aPKUqR6oEf5"},
        "RabbitMq": {"Enabled": True, "Host": "localhost", "Port": 5672, "User": "guest", "Password": "guest", "VirtualHost": "/", "Exchange": "hims.events"},
        "Cors": {"Origins": ALL_ORIGINS},
        **EXTRA_SETTINGS.get(slug, {}),
    }, indent=2) + "\n")
    (d / "Dockerfile").write_text(f"""# Build context = repository root:  docker build -f services/{slug}/Dockerfile .
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY shared/Hims.Common/Hims.Common.csproj shared/Hims.Common/
COPY services/{slug}/Hims.{ns}.csproj services/{slug}/
RUN dotnet restore services/{slug}/Hims.{ns}.csproj
COPY shared/ shared/
COPY services/{slug}/ services/{slug}/
RUN dotnet publish services/{slug}/Hims.{ns}.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "Hims.{ns}.dll"]
""")
    if slug not in HANDWRITTEN_PROGRAM:
        (d / "Program.cs").write_text(f"""using Hims.Common.Http;
using Hims.{ns}.Data;

// {title}: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/{stem}.sql is already mapped in Data/{ns}DbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsService<{ns}DbContext>("{slug}", "HIMS {title}",
    "{desc} (Scaffold: data model mapped, no workflow endpoints yet.)");

var app = builder.Build();
app.UseHims<{ns}DbContext>();
app.Run();
""")
    print("scaffolded", slug)
