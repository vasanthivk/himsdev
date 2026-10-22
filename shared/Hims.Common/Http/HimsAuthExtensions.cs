using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace Hims.Common.Http;

/// <summary>
/// Config section "Auth". Business calls reach the services through the WSO2 API Manager gateway, which validates the user's
/// WSO2 Identity Server token and the subscription, then forwards a backend JWT it signs itself (header X-JWT-Assertion).
/// The service accepts only that JWT, so calls that bypass the gateway are rejected.
/// </summary>
public sealed class HimsAuthOptions
{
    public bool Enabled { get; set; }
    /// <summary>Header carrying the gateway's backend JWT ([apim.jwt] header in API Manager's deployment.toml).</summary>
    public string Header { get; set; } = "X-JWT-Assertion";
    /// <summary>The gateway's signing keys.</summary>
    public string JwksUri { get; set; } = "https://localhost:8253/jwks";
    /// <summary>The backend JWT's iss ([apim.jwt] issuer; API Manager's default is wso2.org/products/am).</summary>
    public string Issuer { get; set; } = "wso2.org/products/am";
    /// <summary>This service's API context on the gateway, e.g. /himspatientaccess/v1. A token issued for another API is rejected. Empty skips the check.</summary>
    public string? ApiContext { get; set; }
    /// <summary>Claims that carry the user's roles. Empty uses the WSO2 defaults (http://wso2.org/claims/role, roles, groups).</summary>
    public string[] RoleClaims { get; set; } = [];
    /// <summary>Roles allowed to read (GET/HEAD). Empty = any signed-in user.</summary>
    public string[] ReadRoles { get; set; } = [];
    /// <summary>Roles allowed to change data (POST/PUT/PATCH/DELETE). Empty = any signed-in user.</summary>
    public string[] WriteRoles { get; set; } = [];
    /// <summary>Dev only: API Manager ships with a self-signed certificate.</summary>
    public bool AllowUntrustedCertificate { get; set; }
}

public static class HimsAuthExtensions
{
    private const string ApiContextClaim = "http://wso2.org/claims/apicontext";
    private const string EndUserClaim = "http://wso2.org/claims/enduser";
    private static readonly string[] DefaultRoleClaims = ["http://wso2.org/claims/role", "roles", "groups"];

    /// <summary>
    /// When Auth:Enabled, every endpoint needs a valid token (and the read/write roles) unless it is marked AllowAnonymous.
    /// WSO2_AUTHENTICATION=true (default): the WSO2 API Manager gateway's backend JWT (header X-JWT-Assertion).
    /// WSO2_AUTHENTICATION=false: HIMS's own JWT (Authorization: Bearer), issued by Identity &amp; Org - see section "Jwt".
    /// </summary>
    public static WebApplicationBuilder AddHimsAuth(this WebApplicationBuilder builder)
    {
        var options = builder.Configuration.GetSection("Auth").Get<HimsAuthOptions>() ?? new HimsAuthOptions();
        var jwt = builder.Configuration.GetSection("Jwt").Get<HimsJwtOptions>() ?? new HimsJwtOptions();
        var mode = new HimsAuthMode(options.Enabled, builder.Configuration.GetValue("WSO2_AUTHENTICATION", true));
        builder.Services.AddSingleton(options);
        builder.Services.AddSingleton(jwt);
        builder.Services.AddSingleton(mode);
        builder.Services.AddSingleton<HimsTokenIssuer>();
        if (!options.Enabled) { builder.Services.AddAuthorization(); return builder; }

        if (mode.Wso2) AddGatewayJwt(builder, options); else AddHimsJwt(builder, jwt);

        builder.Services.AddSingleton<IAuthorizationHandler, HimsAccessHandler>();
        builder.Services.AddAuthorization(a => a.FallbackPolicy = new AuthorizationPolicyBuilder()
            .RequireAuthenticatedUser().AddRequirements(new HimsAccessRequirement()).Build());
        return builder;
    }

    /// <summary>HIMS's own tokens: HMAC-signed by Identity &amp; Org, sent by the frontend as Authorization: Bearer.</summary>
    private static void AddHimsJwt(WebApplicationBuilder builder, HimsJwtOptions jwt)
    {
        var key = jwt.Key();   // fails at startup when the signing key is missing or too short
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(j =>
        {
            j.MapInboundClaims = false;
            j.TokenValidationParameters = new TokenValidationParameters
            {
                ValidIssuer = jwt.Issuer,
                ValidAudience = jwt.Audience,
                IssuerSigningKey = key,
                ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(1),
                NameClaimType = HimsClaims.Name,
                RoleClaimType = HimsClaims.Role,
            };
            j.Events = new JwtBearerEvents
            {
                OnChallenge = ctx =>
                {
                    var reason = ctx.AuthenticateFailure?.Message
                        ?? (string.IsNullOrEmpty(ctx.Request.Headers.Authorization.ToString()) ? "no Authorization: Bearer token" : "not authenticated");
                    ctx.HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Hims.Auth")
                        .LogWarning("401 {Method} {Path}: {Reason}", ctx.Request.Method, ctx.Request.Path, reason);
                    return Task.CompletedTask;
                },
            };
        });
    }

    /// <summary>WSO2 API Manager gateway: only its signed backend JWT (X-JWT-Assertion) is accepted.</summary>
    private static void AddGatewayJwt(WebApplicationBuilder builder, HimsAuthOptions options)
    {
        var roleClaims = options.RoleClaims.Length > 0 ? options.RoleClaims : DefaultRoleClaims;
        var handler = new HttpClientHandler();
        if (options.AllowUntrustedCertificate) handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;

        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(j =>
        {
            j.MapInboundClaims = false;   // keep WSO2 claim names
            // The gateway publishes only a JWKS (no OpenID discovery document); keys are cached and refreshed by the manager.
            j.ConfigurationManager = new ConfigurationManager<OpenIdConnectConfiguration>(options.JwksUri,
                new JwksRetriever(options.Issuer), new HttpDocumentRetriever(new HttpClient(handler)) { RequireHttps = options.JwksUri.StartsWith("https") });
            j.TokenValidationParameters = new TokenValidationParameters
            {
                ValidIssuer = options.Issuer,
                ValidateAudience = false,   // backend JWTs carry no audience; the API context check below binds the token to this service
                ValidateLifetime = true,
                NameClaimType = EndUserClaim,
                RoleClaimType = ClaimTypes.Role,
            };
            j.Events = new JwtBearerEvents
            {
                // Read the gateway's header only - never fall back to an Authorization header sent straight to the service.
                OnMessageReceived = ctx =>
                {
                    var jwt = ctx.Request.Headers[options.Header].ToString();
                    if (string.IsNullOrEmpty(jwt)) ctx.NoResult(); else ctx.Token = jwt;
                    return Task.CompletedTask;
                },
                OnTokenValidated = ctx =>
                {
                    var principal = ctx.Principal!;
                    if (!string.IsNullOrEmpty(options.ApiContext))
                    {
                        var apiContext = principal.FindFirst(ApiContextClaim)?.Value;
                        if (!string.Equals(apiContext?.TrimEnd('/'), options.ApiContext.TrimEnd('/'), StringComparison.OrdinalIgnoreCase))
                        {
                            ctx.Fail($"The gateway token was issued for API '{apiContext}', not '{options.ApiContext}'.");
                            return Task.CompletedTask;
                        }
                    }
                    // WSO2 sends roles as an array or as one comma-separated string, under different claim names.
                    var identity = (ClaimsIdentity)principal.Identity!;
                    var roles = roleClaims.SelectMany(t => principal.FindAll(t))
                        .SelectMany(c => c.Value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                        .Distinct(StringComparer.OrdinalIgnoreCase).ToList();
                    foreach (var role in roles) identity.AddClaim(new Claim(ClaimTypes.Role, role));
                    return Task.CompletedTask;
                },
                // One warning line per rejected call, with the reason (missing header, bad signature, expired, wrong API, ...).
                OnChallenge = ctx =>
                {
                    var reason = ctx.AuthenticateFailure?.Message
                        ?? (string.IsNullOrEmpty(ctx.Request.Headers[options.Header].ToString()) ? $"no {options.Header} header (call bypassed the gateway, or used a credential the gateway issues no backend JWT for, e.g. the Publisher's Internal-Key)" : "not authenticated");
                    ctx.HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Hims.Auth")
                        .LogWarning("401 {Method} {Path}: {Reason}", ctx.Request.Method, ctx.Request.Path, reason);
                    return Task.CompletedTask;
                },
            };
        });
    }

    public static WebApplication UseHimsAuth(this WebApplication app)
    {
        if (app.Services.GetRequiredService<HimsAuthOptions>().Enabled) app.UseAuthentication();
        app.UseAuthorization();
        return app;
    }

    /// <summary>Builds the signing-key configuration from a bare JWKS document.</summary>
    private sealed class JwksRetriever(string issuer) : IConfigurationRetriever<OpenIdConnectConfiguration>
    {
        public async Task<OpenIdConnectConfiguration> GetConfigurationAsync(string address, IDocumentRetriever retriever, CancellationToken cancel)
        {
            var jwks = new JsonWebKeySet(await retriever.GetDocumentAsync(address, cancel));
            var config = new OpenIdConnectConfiguration { Issuer = issuer, JsonWebKeySet = jwks };
            foreach (var key in jwks.GetSigningKeys()) config.SigningKeys.Add(key);
            return config;
        }
    }
}

/// <summary>Which authentication is active: <see cref="Enabled"/> = Auth:Enabled, <see cref="Wso2"/> = WSO2_AUTHENTICATION.</summary>
public sealed record HimsAuthMode(bool Enabled, bool Wso2)
{
    /// <summary>HIMS's own login and tokens are in use (Identity &amp; Org's /api/auth endpoints are active).</summary>
    public bool HimsJwt => !Wso2;
}

/// <summary>Read/write role check applied to every endpoint (Auth:ReadRoles for GET/HEAD/OPTIONS, Auth:WriteRoles otherwise).</summary>
public sealed class HimsAccessRequirement : IAuthorizationRequirement;

internal sealed class HimsAccessHandler(HimsAuthOptions options) : AuthorizationHandler<HimsAccessRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, HimsAccessRequirement requirement)
    {
        var method = (context.Resource as HttpContext)?.Request.Method ?? HttpMethods.Get;
        var reading = HttpMethods.IsGet(method) || HttpMethods.IsHead(method) || HttpMethods.IsOptions(method);
        var allowed = reading ? options.ReadRoles : options.WriteRoles;
        if (allowed.Length == 0 || allowed.Any(context.User.IsInRole)) context.Succeed(requirement);
        return Task.CompletedTask;
    }
}
