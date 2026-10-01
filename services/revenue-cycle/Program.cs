using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.RevenueCycle.Data;
using Hims.RevenueCycle.Handlers;
using Hims.RevenueCycle.Services;

// Revenue Cycle: service catalogue, tariffs, bills, receipts. Publishes ServiceUpdated, ChargePosted, BillFinalised,
// PaymentReceived. Subscribes OrderPlaced (raises the bill) and keeps ref copies of patient/encounter/branch/organization.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("revenue-cycle");   // logs/revenue-cycle/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<RevenueCycleDbContext>("revenue-cycle", "HIMS Revenue Cycle",
    "Service catalogue, tariffs, bills and receipts. Publishes ServiceUpdated, ChargePosted, BillFinalised, PaymentReceived; subscribes OrderPlaced.");

builder.Services.AddScoped<BillingService>();
builder.Services.AddEventHandler<OrderPlacedBillingHandler>();
builder.Services.AddRefReplica<RevenueCycleDbContext, RefPatient>("PatientRegistered", "PatientUpdated");
builder.Services.AddRefReplica<RevenueCycleDbContext, RefEncounter>("EncounterStarted", "EncounterClosed");
builder.Services.AddRefReplica<RevenueCycleDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<RevenueCycleDbContext, RefOrganization>("OrganizationUpdated");

var app = builder.Build();
app.UseHims<RevenueCycleDbContext>();
app.Run();
