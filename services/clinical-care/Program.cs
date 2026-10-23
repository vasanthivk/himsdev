using Hims.ClinicalCare.Data;
using Hims.ClinicalCare.Handlers;
using Hims.Common.Http;
using Hims.Common.Logging;

// Clinical Care: consultation notes/diagnoses (EMR), CPOE lab orders and e-prescriptions.
// Publishes OrderPlaced, PrescriptionIssued, ClinicalNoteSigned, DiagnosisRecorded. Subscribes ResultVerified, ChargePosted.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("clinical-care");   // logs/clinical-care/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<ClinicalCareDbContext>("clinical-care", "HIMS Clinical Care",
    "EMR, CPOE orders and e-prescriptions. Publishes OrderPlaced, PrescriptionIssued, ClinicalNoteSigned, DiagnosisRecorded; subscribes ResultVerified.");

builder.Services.AddEventHandler<ResultVerifiedHandler>();
builder.Services.AddEventHandler<ChargePostedHandler>();
builder.Services.AddRefReplica<ClinicalCareDbContext, RefPatient>("PatientRegistered", "PatientUpdated");
builder.Services.AddRefReplica<ClinicalCareDbContext, RefEncounter>("EncounterStarted", "EncounterClosed");
builder.Services.AddRefReplica<ClinicalCareDbContext, RefService>("ServiceUpdated");
builder.Services.AddRefReplica<ClinicalCareDbContext, RefPractitioner>("PractitionerUpdated");
builder.Services.AddRefReplica<ClinicalCareDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<ClinicalCareDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<ClinicalCareDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<ClinicalCareDbContext>();
app.Run();
