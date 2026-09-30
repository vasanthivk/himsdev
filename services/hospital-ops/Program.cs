using Hims.Common.Http;
using Hims.HospitalOps.Data;

// Hospital Operations & Quality: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/09_hospital_ops.sql is already mapped in Data/HospitalOpsDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsService<HospitalOpsDbContext>("hospital-ops", "HIMS Hospital Operations & Quality",
    "Assets, maintenance, housekeeping, linen, kitchen, complaints, incidents and quality. (Scaffold: data model mapped, no workflow endpoints yet.)");

var app = builder.Build();
app.UseHims<HospitalOpsDbContext>();
app.Run();
