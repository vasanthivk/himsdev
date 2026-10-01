using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.PharmacySupply.Data;

// Pharmacy & Supply Chain: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/05_pharmacy_supply.sql is already mapped in Data/PharmacySupplyDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("pharmacy-supply");   // logs/pharmacy-supply/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<PharmacySupplyDbContext>("pharmacy-supply", "HIMS Pharmacy & Supply Chain",
    "Drug/item master, stores and stock, purchasing, GRN, dispensing, narcotics register, CSSD. (Scaffold: data model mapped, no workflow endpoints yet.)");

var app = builder.Build();
app.UseHims<PharmacySupplyDbContext>();
app.Run();
