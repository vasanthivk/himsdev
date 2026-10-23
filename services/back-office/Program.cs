using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.BackOffice.Data;

// Back Office: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/13_back_office.sql is already mapped in Data/BackOfficeDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("back-office");   // logs/back-office/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<BackOfficeDbContext>("back-office", "HIMS Back Office",
    "Finance, HRMS, campus and IT helpdesk (optional; normally bought and integrated). (Scaffold: data model mapped, no workflow endpoints yet.)");

builder.Services.AddRefReplica<BackOfficeDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<BackOfficeDbContext>();
app.Run();
