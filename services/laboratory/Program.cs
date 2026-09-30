using Hims.Common.Http;
using Hims.Laboratory.Data;
using Hims.Laboratory.Handlers;
using Hims.Laboratory.Services;

// Laboratory (LIMS): worklist, samples, analyzers (devices) and results.
// Subscribes OrderPlaced and AnalyzerResultReceived. Publishes SampleCollected, ResultVerified, LabReportReleased, CriticalValueDetected.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsService<LaboratoryDbContext>("laboratory", "HIMS Laboratory (LIMS & Blood Centre)",
    "Lab worklist, sample collection, analyzers and results. Subscribes OrderPlaced, AnalyzerResultReceived; publishes SampleCollected, ResultVerified, LabReportReleased, CriticalValueDetected.");

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

var app = builder.Build();
app.UseHims<LaboratoryDbContext>();
app.Run();
