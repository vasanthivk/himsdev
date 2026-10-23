using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.FieldOps.Data;

// Field Operations: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/08_field_ops.sql is already mapped in Data/FieldOpsDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("field-ops");   // logs/field-ops/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<FieldOpsDbContext>("field-ops", "HIMS Field Operations",
    "Ambulance, home collection/delivery, fleet, trips, GPS and cold-chain. (Scaffold: data model mapped, no workflow endpoints yet.)");

builder.Services.AddRefReplica<FieldOpsDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<FieldOpsDbContext>();
app.Run();
