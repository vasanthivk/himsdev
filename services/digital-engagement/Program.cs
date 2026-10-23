using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.DigitalEngagement.Data;

// Digital Engagement: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/07_digital_engagement.sql is already mapped in Data/DigitalEngagementDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("digital-engagement");   // logs/digital-engagement/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<DigitalEngagementDbContext>("digital-engagement", "HIMS Digital Engagement",
    "E-commerce, teleconsultation, remote monitoring, CRM and medical camps. (Scaffold: data model mapped, no workflow endpoints yet.)");

builder.Services.AddRefReplica<DigitalEngagementDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<DigitalEngagementDbContext>();
app.Run();
