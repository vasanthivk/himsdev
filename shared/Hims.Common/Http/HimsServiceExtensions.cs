using System.Text.Json;
using System.Text.Json.Serialization;
using Hims.Common.Data;
using Hims.Common.Events;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Http;

namespace Hims.Common.Http;

/// <summary>One-line bootstrap for every .NET HIMS microservice, so Program.cs stays tiny and all services behave alike.</summary>
public static class HimsServiceExtensions
{
    /// <summary>
    /// Registers: the service's DbContext (PostgreSQL), controllers with the HIMS JSON convention, Swagger, CORS, the shared
    /// SequenceService, the outbox relay and the event consumer.
    /// </summary>
    public static WebApplicationBuilder AddHimsService<TDb>(this WebApplicationBuilder builder, string serviceName, string title, string description)
        where TDb : DbContext
    {
        var connectionString = builder.Configuration.GetConnectionString("Default")
            ?? throw new InvalidOperationException("ConnectionStrings:Default is not configured");

        builder.Services.AddDbContext<TDb>(o => o.UseNpgsql(connectionString));
        builder.Services.AddSingleton(new HimsServiceInfo(serviceName, title, description));
        builder.Services.Configure<EventBusOptions>(builder.Configuration.GetSection("RabbitMq"));
        builder.Services.AddScoped<ISequenceService, SequenceService>();
        builder.Services.AddHttpClient();

        builder.Services.AddControllers().AddJsonOptions(o =>
        {
            o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
            o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        });
        builder.Services.AddHimsSwagger(title, description);

        // Browser front-ends (micro-frontend zones) call each service directly; list their origins in Cors:Origins.
        // Wildcards cover every tenant subdomain, e.g. "https://*.localhost:3000" allows https://apollo.localhost:3000.
        var origins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? new[] { "http://localhost:3000" };
        builder.Services.AddCors(o => o.AddPolicy("frontends", p => p.WithOrigins(origins).SetIsOriginAllowedToAllowWildcardSubdomains().AllowAnyHeader().AllowAnyMethod()));
        builder.AddHimsAuth();

        builder.Services.AddHostedService<OutboxRelay>();
        builder.Services.AddHostedService<EventConsumer<TDb>>();
        return builder;
    }

    /// <summary>Registers a handler for one event type (also tells the consumer to bind the queue to that event).</summary>
    public static IServiceCollection AddEventHandler<THandler>(this IServiceCollection services) where THandler : class, IEventHandler
        => services.AddScoped<IEventHandler, THandler>();

    /// <summary>Registers ref-table replication: each listed event upserts the matching ref.* row.</summary>
    public static IServiceCollection AddRefReplica<TDb, TRef>(this IServiceCollection services, params string[] eventTypes)
        where TDb : DbContext where TRef : class, new()
    {
        foreach (var eventType in eventTypes)
        {
            var type = eventType;
            services.AddScoped<IEventHandler>(sp => new RefUpsertHandler<TDb, TRef>(sp.GetRequiredService<TDb>(), type));
        }
        return services;
    }

    /// <summary>Like <see cref="AddRefReplica{TDb,TRef}"/> but for an array inside the payload: every element is upserted.</summary>
    public static IServiceCollection AddRefReplicaCollection<TDb, TRef>(this IServiceCollection services, string collectionProperty, params string[] eventTypes)
        where TDb : DbContext where TRef : class, new()
    {
        foreach (var eventType in eventTypes)
        {
            var type = eventType;
            services.AddScoped<IEventHandler>(sp => new RefUpsertHandler<TDb, TRef>(sp.GetRequiredService<TDb>(), type, collectionProperty));
        }
        return services;
    }

    /// <summary>Swagger UI at /swagger, CORS, controllers, GET /health, and "/" redirecting to Swagger.</summary>
    public static WebApplication UseHims<TDb>(this WebApplication app) where TDb : DbContext
    {
        var info = app.Services.GetRequiredService<HimsServiceInfo>();
        app.UseHimsSwagger(info.Title);
        app.UseCors("frontends");
        app.UseHimsAuth();
        app.MapControllers();
        app.MapGet("/health", async (TDb db) =>
        {
            var dbUp = false;
            try { dbUp = await db.Database.CanConnectAsync(); } catch { /* reported below */ }
            return Results.Json(new { service = info.Name, status = dbUp ? "healthy" : "degraded", database = dbUp });
        }).AllowAnonymous();
        app.MapGet("/", () => Results.Redirect("/swagger")).AllowAnonymous();
        return app;
    }
}
