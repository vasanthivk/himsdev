using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.CommsDocs.Data;

// Communication & Documents: data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/12_comms_docs.sql is already mapped in Data/CommsDocsDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("comms-docs");   // logs/comms-docs/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<CommsDocsDbContext>("comms-docs", "HIMS Communication & Documents",
    "Document index, letterheads, notifications and delivery tracking. (Scaffold: data model mapped, no workflow endpoints yet.)");

var app = builder.Build();
app.UseHims<CommsDocsDbContext>();
app.Run();
