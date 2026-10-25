using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.RevenueFinance.Data;
using Hims.RevenueFinance.Handlers;
using Hims.RevenueFinance.Services;

// Revenue & Finance (former Revenue Cycle + Back Office).
// Revenue Cycle: service catalogue, tariffs, bills, receipts. Publishes ServiceUpdated, ChargePosted, BillFinalised,
// PaymentReceived. Subscribes OrderPlaced (raises the bill) and keeps ref copies of patient/encounter/branch/organization.
// Back Office (finance, HRMS, campus, IT helpdesk): data model mapped, no endpoints yet. Its ref.receipt is a read-only view of bil.receipt.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("revenue-finance");   // logs/revenue-finance/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<RevenueFinanceDbContext>("revenue-finance", "HIMS Revenue & Finance",
    "Service catalogue, tariffs, bills and receipts. Publishes ServiceUpdated, ChargePosted, BillFinalised, PaymentReceived; subscribes OrderPlaced. " +
    "Back office (finance, HRMS, campus, IT helpdesk): data model mapped, no workflow endpoints yet.");

builder.Services.AddScoped<BillingService>();
builder.Services.AddEventHandler<OrderPlacedBillingHandler>();
builder.Services.AddRefReplica<RevenueFinanceDbContext, RefPatient>("PatientRegistered", "PatientUpdated");
builder.Services.AddRefReplica<RevenueFinanceDbContext, RefEncounter>("EncounterStarted", "EncounterClosed");
builder.Services.AddRefReplica<RevenueFinanceDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<RevenueFinanceDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<RevenueFinanceDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<RevenueFinanceDbContext>();
app.Run();
