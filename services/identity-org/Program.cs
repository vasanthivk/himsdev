using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.IdentityOrg.Data;

// Identity, Organization & Reference Data (platform service): the source of truth for organization, branches,
// departments, staff and the practitioner registry. Other services keep read-only copies in their ref.* tables,
// filled from the *Updated events this service publishes (see AdminController.Republish for the initial bulk load).
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("identity-org");   // logs/identity-org/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<IdentityOrgDbContext>("identity-org", "HIMS Identity, Organization & Reference Data",
    "Organization, branches, departments, staff and the practitioner registry. Publishes OrganizationUpdated, BranchUpdated, DepartmentUpdated, PractitionerUpdated.");

var app = builder.Build();
app.UseHims<IdentityOrgDbContext>();
app.Run();
