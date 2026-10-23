using System.Text.Json.Serialization.Metadata;
using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.Laboratory.Data;
using Hims.Laboratory.Handlers;
using Hims.Laboratory.Services;

// Laboratory (LIMS): worklist, samples, analyzers (devices) and results.
// Subscribes OrderPlaced and AnalyzerResultReceived. Publishes SampleCollected, ResultVerified, LabReportReleased, CriticalValueDetected.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("laboratory");   // logs/laboratory/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<LaboratoryDbContext>("laboratory", "HIMS Laboratory (LIMS & Blood Centre)",
    "Lab worklist, sample collection, analyzers and results. Subscribes OrderPlaced, AnalyzerResultReceived; publishes SampleCollected, ResultVerified, LabReportReleased, CriticalValueDetected.");

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
builder.Services.AddRefReplica<LaboratoryDbContext, RefPatient>("PatientRegistered", "PatientUpdated");
builder.Services.AddRefReplica<LaboratoryDbContext, RefEncounter>("EncounterStarted", "EncounterClosed");
builder.Services.AddRefReplica<LaboratoryDbContext, RefService>("ServiceUpdated");
builder.Services.AddRefReplica<LaboratoryDbContext, RefPractitioner>("PractitionerUpdated");
builder.Services.AddRefReplica<LaboratoryDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<LaboratoryDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<LaboratoryDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<LaboratoryDbContext>();
app.Run();
