using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.IdentityOrg.Data;
using Hims.IdentityOrg.Services;

// Identity, Organization & Reference Data (platform service): the source of truth for organization, branches,
// departments, staff and the practitioner registry. Other services keep read-only copies in their ref.* tables,
// filled from the *Updated events this service publishes (see AdminController.Republish for the initial bulk load).
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("identity-org");   // logs/identity-org/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<IdentityOrgDbContext>("identity-org", "HIMS Identity, Organization & Reference Data",
    "Organization, branches, departments, staff and the practitioner registry. Publishes OrganizationUpdated, BranchUpdated, DepartmentUpdated, PractitionerUpdated.");

// Users created in HIMS are also created in the organization's WSO2 Identity Server tenant (SCIM2) - see UsersController.
var wso2Users = builder.Configuration.GetSection("Wso2UserManagement").Get<Wso2UserManagementOptions>() ?? new Wso2UserManagementOptions();
builder.Services.AddSingleton(wso2Users);
builder.Services.AddSingleton<Wso2UserManagement>();
builder.Services.AddHttpClient(Wso2UserManagement.HttpClientName, c => c.Timeout = TimeSpan.FromSeconds(30))
    .ConfigurePrimaryHttpMessageHandler(() => wso2Users.AllowUntrustedCertificate
        ? new HttpClientHandler { ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator }
        : new HttpClientHandler());

var app = builder.Build();
app.UseHims<IdentityOrgDbContext>();
await app.SeedBootstrapAdminAsync();   // WSO2_AUTHENTICATION=false only: first ADMIN user while sec.user_account is empty
app.Run();
