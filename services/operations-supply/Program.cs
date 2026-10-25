using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.OperationsSupply.Data;

// Operations & Supply Chain (former Pharmacy & Supply Chain + Hospital Operations & Quality + Field Operations): data model + API
// host + event plumbing are in place; no workflow screens or endpoints yet. Every table of database/05_pharmacy_supply.sql,
// 09_hospital_ops.sql and 08_field_ops.sql is mapped in Data/OperationsSupplyDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("operations-supply");   // logs/operations-supply/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<OperationsSupplyDbContext>("operations-supply", "HIMS Operations & Supply Chain",
    "Drug/item master, stores and stock, purchasing, GRN, dispensing, narcotics register, CSSD; assets, maintenance, housekeeping, " +
    "linen, kitchen, complaints, incidents, quality; ambulance, home collection/delivery, fleet, trips, GPS, cold chain. (Scaffold: data model mapped, no workflow endpoints yet.)");

builder.Services.AddRefReplica<OperationsSupplyDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<OperationsSupplyDbContext>();
app.Run();
