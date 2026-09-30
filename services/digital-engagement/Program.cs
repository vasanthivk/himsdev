using Hims.Common.Http;
using Hims.DigitalEngagement.Data;

// Digital Engagement: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/07_digital_engagement.sql is already mapped in Data/DigitalEngagementDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsService<DigitalEngagementDbContext>("digital-engagement", "HIMS Digital Engagement",
    "E-commerce, teleconsultation, remote monitoring, CRM and medical camps. (Scaffold: data model mapped, no workflow endpoints yet.)");

var app = builder.Build();
app.UseHims<DigitalEngagementDbContext>();
app.Run();
