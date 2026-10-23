using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.PatientAccess.Data;
using Hims.PatientAccess.Handlers;

// Patient Access: UHID/MPI, patient registration, encounters (OP visits). Publishes PatientRegistered, PatientUpdated,
// EncounterStarted, EncounterClosed. Keeps ref copies of organization/branch/department/practitioner data.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("patient-access");   // logs/patient-access/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<PatientAccessDbContext>("patient-access", "HIMS Patient Access",
    "Front office: patient registration (UHID) and encounters. Publishes PatientRegistered, PatientUpdated, EncounterStarted, EncounterClosed.");

builder.Services.AddEventHandler<ConsultationCompletedHandler>();   // Clinical Care: doctor finished the visit -> close the encounter
builder.Services.AddRefReplica<PatientAccessDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefDepartment>("DepartmentUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefPractitioner>("PractitionerUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<PatientAccessDbContext>();
app.Run();
