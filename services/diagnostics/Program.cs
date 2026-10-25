using System.Text.Json.Serialization.Metadata;
using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.Diagnostics.Data;
using Hims.Diagnostics.Handlers;
using Hims.Diagnostics.Services;

// Diagnostics (former Laboratory + Imaging).
// Laboratory (LIMS): worklist, samples, analyzers (devices) and results.
// Subscribes OrderPlaced and AnalyzerResultReceived. Publishes SampleCollected, ResultVerified, LabReportReleased, CriticalValueDetected.
// Imaging (RIMS + PACS): data model mapped (rad.*, pacs.*), no endpoints yet.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("diagnostics");   // logs/diagnostics/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<DiagnosticsDbContext>("diagnostics", "HIMS Diagnostics (Lab + Imaging)",
    "Lab worklist, sample collection, analyzers and results. Subscribes OrderPlaced, AnalyzerResultReceived; publishes SampleCollected, ResultVerified, LabReportReleased, CriticalValueDetected. " +
    "Imaging (RIMS + PACS): data model mapped, no workflow endpoints yet.");

// lab.analyzer.engine_password is kept for re-provisioning but is never returned by the API.
builder.Services.Configure<Microsoft.AspNetCore.Mvc.JsonOptions>(o =>
    o.JsonSerializerOptions.TypeInfoResolver = new DefaultJsonTypeInfoResolver
    {
        Modifiers =
        {
            info =>
            {
                if (info.Type != typeof(Analyzer)) return;
                foreach (var p in info.Properties)
                    if (string.Equals(p.Name, nameof(Analyzer.EnginePassword), StringComparison.OrdinalIgnoreCase)) p.ShouldSerialize = (_, _) => false;
            },
        },
    });

builder.Services.AddScoped<ResultService>();
builder.Services.AddHttpClient<IIntegrationHubClient, IntegrationHubClient>(c =>
{
    c.BaseAddress = new Uri(builder.Configuration["IntegrationHub:BaseUrl"] ?? "http://localhost:5011/");
    c.Timeout = TimeSpan.FromSeconds(20);
});

builder.Services.AddEventHandler<OrderPlacedLabHandler>();
builder.Services.AddEventHandler<AnalyzerResultReceivedHandler>();
builder.Services.AddEventHandler<ChargePostedLabHandler>();      // billing status in ref.order_item (Revenue Cycle)
builder.Services.AddEventHandler<PaymentReceivedLabHandler>();
builder.Services.AddRefReplica<DiagnosticsDbContext, RefPatient>("PatientRegistered", "PatientUpdated");
builder.Services.AddRefReplica<DiagnosticsDbContext, RefEncounter>("EncounterStarted", "EncounterClosed");
builder.Services.AddRefReplica<DiagnosticsDbContext, RefService>("ServiceUpdated");
builder.Services.AddRefReplica<DiagnosticsDbContext, RefPractitioner>("PractitionerUpdated");
builder.Services.AddRefReplica<DiagnosticsDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<DiagnosticsDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<DiagnosticsDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<DiagnosticsDbContext>();
app.Run();
