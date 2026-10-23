using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.HospitalOps.Data;

// Hospital Operations & Quality: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/09_hospital_ops.sql is already mapped in Data/HospitalOpsDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("hospital-ops");   // logs/hospital-ops/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<HospitalOpsDbContext>("hospital-ops", "HIMS Hospital Operations & Quality",
    "Assets, maintenance, housekeeping, linen, kitchen, complaints, incidents and quality. (Scaffold: data model mapped, no workflow endpoints yet.)");

builder.Services.AddRefReplica<HospitalOpsDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<HospitalOpsDbContext>();
app.Run();
