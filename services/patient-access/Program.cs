using Hims.Common.Http;
using Hims.PatientAccess.Data;

// Patient Access: UHID/MPI, patient registration, encounters (OP visits). Publishes PatientRegistered, PatientUpdated,
// EncounterStarted, EncounterClosed. Keeps ref copies of organization/branch/department/practitioner data.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsService<PatientAccessDbContext>("patient-access", "HIMS Patient Access",
    "Front office: patient registration (UHID) and encounters. Publishes PatientRegistered, PatientUpdated, EncounterStarted, EncounterClosed.");

builder.Services.AddRefReplica<PatientAccessDbContext, RefOrganization>("OrganizationUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefBranch>("BranchUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefDepartment>("DepartmentUpdated");
builder.Services.AddRefReplica<PatientAccessDbContext, RefPractitioner>("PractitionerUpdated");

var app = builder.Build();
app.UseHims<PatientAccessDbContext>();
app.Run();
