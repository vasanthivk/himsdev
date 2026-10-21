using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

namespace Hims.Common.Http;

/// <summary>Config section "Auth": validation of the WSO2 Identity Server access token (JWT) the front-ends send.</summary>
public sealed class HimsAuthOptions
{
    public bool Enabled { get; set; }
    /// <summary>WSO2 IS issuer (tenant-qualified); its discovery document is {Authority}/.well-known/openid-configuration.</summary>
    public string Authority { get; set; } = "https://localhost:9443/t/newmeksolutions.com/oauth2/token";
    /// <summary>The WSO2 application's client id (WSO2 puts it in the token's aud claim). Empty skips the audience check.</summary>
    public string? Audience { get; set; }
    /// <summary>Dev only: WSO2 IS ships with a self-signed certificate.</summary>
    public bool AllowUntrustedCertificate { get; set; }
}

public static class HimsAuthExtensions
{
    /// <summary>When Auth:Enabled, every endpoint needs a valid WSO2 IS bearer token unless it is marked AllowAnonymous.</summary>
    public static WebApplicationBuilder AddHimsAuth(this WebApplicationBuilder builder)
    {
        var options = builder.Configuration.GetSection("Auth").Get<HimsAuthOptions>() ?? new HimsAuthOptions();
        builder.Services.AddSingleton(options);
        if (!options.Enabled) { builder.Services.AddAuthorization(); return builder; }

        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(j =>
        {
            j.Authority = options.Authority;
            j.MapInboundClaims = false;   // keep WSO2 claim names (sub, roles, ...)
            j.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateAudience = !string.IsNullOrEmpty(options.Audience),
                ValidAudience = options.Audience,
                NameClaimType = "sub",
                RoleClaimType = "roles",
            };
            if (options.AllowUntrustedCertificate)
                j.BackchannelHttpHandler = new HttpClientHandler { ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator };
        });
        builder.Services.AddAuthorization(a => a.FallbackPolicy = new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build());
        return builder;
    }

    public static WebApplication UseHimsAuth(this WebApplication app)
    {
        if (app.Services.GetRequiredService<HimsAuthOptions>().Enabled) app.UseAuthentication();
        app.UseAuthorization();
        return app;
    }
}
