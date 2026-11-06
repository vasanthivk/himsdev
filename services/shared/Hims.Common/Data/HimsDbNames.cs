using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;

namespace Hims.Common.Data;

/// <summary>
/// Physical table names. Config "Database:Schema" selects the layout:
///   empty (default)  - one database per service (database/, database_v2/): core.number_sequence
///   "diagnostics"    - one shared database with one schema per service (database_v3/, himsdev): diagnostics.core_number_sequence
/// Raw SQL (outbox, inbox, sequences) gets its table names from here; EF entities are mapped by <see cref="HimsModelCustomizer"/>.
/// </summary>
public sealed class HimsDbNames
{
    /// <summary>The service's schema in the shared database; null = database per service.</summary>
    public string? ServiceSchema { get; }

    public HimsDbNames(IConfiguration config)
    {
        var schema = config["Database:Schema"]?.Trim();
        ServiceSchema = string.IsNullOrEmpty(schema) ? null : schema;
        if (ServiceSchema is not null && !System.Text.RegularExpressions.Regex.IsMatch(ServiceSchema, "^[a-z_][a-z0-9_]*$"))
            throw new InvalidOperationException($"Database:Schema '{ServiceSchema}' must be a lower-case PostgreSQL identifier");
    }

    /// <summary>"evt", "outbox" -> evt.outbox, or diagnostics.evt_outbox in the shared database.</summary>
    public string Table(string schema, string table) => ServiceSchema is null ? $"{schema}.{table}" : $"{ServiceSchema}.{schema}_{table}";
}

/// <summary>
/// Maps the generated entities (e.g. [Table("organization", Schema = "core")]) onto the shared database's naming when
/// Database:Schema is set: core.organization -> identity_org.core_organization. Without it the model is left unchanged.
/// </summary>
public sealed class HimsModelCustomizer(ModelCustomizerDependencies dependencies) : RelationalModelCustomizer(dependencies)
{
    public override void Customize(ModelBuilder modelBuilder, DbContext context)
    {
        base.Customize(modelBuilder, context);
        var names = context.GetService<HimsDbNames>();   // falls back to the application's service provider
        if (names?.ServiceSchema is not { } serviceSchema) return;
        foreach (var entity in modelBuilder.Model.GetEntityTypes())
        {
            var table = entity.GetTableName();
            if (table is null) continue;
            var schema = entity.GetSchema() ?? "public";
            entity.SetTableName($"{schema}_{table}");
            entity.SetSchema(serviceSchema);
        }
    }
}
