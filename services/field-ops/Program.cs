using Hims.Common.Http;
using Hims.FieldOps.Data;

// Field Operations: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/08_field_ops.sql is already mapped in Data/FieldOpsDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsService<FieldOpsDbContext>("field-ops", "HIMS Field Operations",
    "Ambulance, home collection/delivery, fleet, trips, GPS and cold-chain. (Scaffold: data model mapped, no workflow endpoints yet.)");

var app = builder.Build();
app.UseHims<FieldOpsDbContext>();
app.Run();
