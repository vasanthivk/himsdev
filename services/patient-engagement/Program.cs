using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.PatientEngagement.Data;
using Hims.PatientEngagement.Handlers;

// Patient Access & Engagement (former Patient Access + Digital Engagement).
// Patient Access: UHID/MPI, patient registration, encounters (OP visits). Publishes PatientRegistered, PatientUpdated,
// EncounterStarted, EncounterClosed. Keeps ref copies of organization/branch/department/practitioner data.
// Digital Engagement (e-commerce, teleconsultation, remote monitoring, CRM, camps): data model mapped, no endpoints yet. Its
// ref.patient/encounter/appointment/slot are read-only views of this service's own tables.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("patient-engagement");   // logs/patient-engagement/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<PatientEngagementDbContext>("patient-engagement", "HIMS Patient Access & Engagement",
    "Front office: patient registration (UHID) and encounters. Publishes PatientRegistered, PatientUpdated, EncounterStarted, EncounterClosed. " +
    "Digital engagement (e-commerce, teleconsultation, remote monitoring, CRM, camps): data model mapped, no workflow endpoints yet.");

builder.Services.AddEventHandler<ConsultationCompletedHandler>();   // Clinical Care: doctor finished the visit -> close the encounter
builder.Services.AddRefReplica<PatientEngagementDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<PatientEngagementDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<PatientEngagementDbContext, RefDepartment>("DepartmentUpdated");
builder.Services.AddRefReplica<PatientEngagementDbContext, RefPractitioner>("PractitionerUpdated");
builder.Services.AddRefReplica<PatientEngagementDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<PatientEngagementDbContext>();
app.Run();
