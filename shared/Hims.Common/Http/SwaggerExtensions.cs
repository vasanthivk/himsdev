using System.Reflection;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;

namespace Hims.Common.Http;

/// <summary>Swagger/OpenAPI shared by all services. Picks up each service's XML doc comments so /// summaries show in the UI.</summary>
public static class SwaggerExtensions
{
    public static IServiceCollection AddHimsSwagger(this IServiceCollection services, string title, string description)
    {
        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo { Title = title, Version = "v1", Description = description });

            var xml = Path.Combine(AppContext.BaseDirectory, $"{Assembly.GetEntryAssembly()?.GetName().Name}.xml");
            if (File.Exists(xml)) c.IncludeXmlComments(xml, includeControllerXmlComments: true);

            // Several services map tables with the same short name in different schemas; full names avoid schema collisions.
            c.CustomSchemaIds(t => t.FullName ?? t.Name);

            // "Authorize" button: paste a WSO2 Identity Server access token to call the API when Auth:Enabled.
            var bearer = new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT", Description = "WSO2 Identity Server access token",
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" },
            };
            c.AddSecurityDefinition("Bearer", bearer);
            c.AddSecurityRequirement(new OpenApiSecurityRequirement { [bearer] = Array.Empty<string>() });
        });
        return services;
    }

    public static WebApplication UseHimsSwagger(this WebApplication app, string title)
    {
        app.UseSwagger();
        app.UseSwaggerUI(c =>
        {
            c.SwaggerEndpoint("/swagger/v1/swagger.json", $"{title} v1");
            c.DocumentTitle = title;
        });
        return app;
    }
}
