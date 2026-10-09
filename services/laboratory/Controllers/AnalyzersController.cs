using System.ComponentModel.DataAnnotations;
using Hims.Laboratory.Data;
using Hims.Laboratory.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.Laboratory.Controllers;

public class CreateAnalyzerRequest
{
    [Required] public int BranchId { get; set; }
    [Required, MaxLength(20)] public string AnalyzerCode { get; set; } = string.Empty;
    [Required, MaxLength(100)] public string AnalyzerName { get; set; } = string.Empty;
    public string? Manufacturer { get; set; }
    public string? Model { get; set; }
    /// <summary>HEMATOLOGY, BIOCHEMISTRY, ...</summary>
    public string? LabSection { get; set; }
    /// <summary>HL7V2, HL7V3, FHIR, ASTM, LIS2-A2 or FILE</summary>
    public string InterfaceProtocol { get; set; } = "HL7V2";
    public bool IsBidirectional { get; set; }
    /// <summary>What the instrument puts in HL7 MSH-3 (or FHIR Device id). Defaults to the analyzer code.</summary>
    public string? SendingApplicationId { get; set; }
    public string? HostAddress { get; set; }
    public int? Port { get; set; }

    // Open Integration Engine connection for this device. Anything left empty falls back to the Integration Hub's own setting.
    /// <summary>Engine REST API base URL, e.g. https://engine-host:8443</summary>
    [MaxLength(200)] public string? EngineUrl { get; set; }
    [MaxLength(100)] public string? EngineUser { get; set; }
    [MaxLength(200)] public string? EnginePassword { get; set; }
    public bool? EngineVerifyTls { get; set; }
    /// <summary>Name of the engine channel that is cloned for this device.</summary>
    [MaxLength(100)] public string? EngineTemplateChannel { get; set; }
    /// <summary>Listen port = this + analyzer id when Port is empty.</summary>
    public int? EngineFirstListenPort { get; set; }
    /// <summary>Where the engine's HTTP Sender posts back to the Integration Hub.</summary>
    [MaxLength(200)] public string? HubPublicUrl { get; set; }
    /// <summary>The deployed channel's own HTTP endpoint (device messages are sent here).</summary>
    [MaxLength(200)] public string? EngineChannelUrl { get; set; }
}

public class ParameterMapRequest
{
    [Required] public int LabParameterId { get; set; }
    /// <summary>The code the instrument sends for this test.</summary>
    [Required] public string MachineTestCode { get; set; } = string.Empty;
    public decimal? ConversionFactor { get; set; }
}

/// <summary>Analyzers / devices (lab.analyzer) and their wiring to the Open Integration Engine through the Integration Hub.</summary>
[ApiController]
[Route("api/analyzers")]
public class AnalyzersController : ControllerBase
{
    private static readonly string[] Protocols = { "HL7V2", "HL7V3", "FHIR", "ASTM", "LIS2-A2", "FILE" };
    private readonly LaboratoryDbContext _db;
    private readonly IIntegrationHubClient _hub;
    private readonly ILogger<AnalyzersController> _log;
    public AnalyzersController(LaboratoryDbContext db, IIntegrationHubClient hub, ILogger<AnalyzersController> log) { _db = db; _hub = hub; _log = log; }

    /// <summary>
    /// Adds a device: inserts lab.analyzer, then asks the Integration Hub to create the matching channel in the Open Integration
    /// Engine. If the hub is unreachable the analyzer is still saved with channel_status PENDING; call POST {id}/provision later.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateAnalyzerRequest req, CancellationToken ct)
    {
        var protocol = req.InterfaceProtocol.ToUpperInvariant();
        if (!Protocols.Contains(protocol)) return BadRequest(new { error = $"InterfaceProtocol must be one of {string.Join(", ", Protocols)}" });
        var branch = await _db.RefBranches.FirstOrDefaultAsync(b => b.BranchId == req.BranchId, ct);
        if (branch?.OrganizationId is null) return BadRequest(new { error = $"Branch {req.BranchId} is unknown (load reference data first)" });
        var org = branch.OrganizationId.Value;
        if (await _db.Analyzers.AnyAsync(a => a.OrganizationId == org && a.AnalyzerCode == req.AnalyzerCode, ct))
            return Conflict(new { error = $"Analyzer code {req.AnalyzerCode} already exists" });

        var analyzer = new Analyzer
        {
            OrganizationId = org, BranchId = req.BranchId, AnalyzerCode = req.AnalyzerCode, AnalyzerName = req.AnalyzerName,
            Manufacturer = req.Manufacturer, Model = req.Model, LabSection = req.LabSection, InterfaceProtocol = protocol,
            IsBidirectional = req.IsBidirectional, AnalyzerStatus = "ONLINE",
            SendingApplicationId = string.IsNullOrWhiteSpace(req.SendingApplicationId) ? req.AnalyzerCode : req.SendingApplicationId,
            HostAddress = req.HostAddress, Port = req.Port, ChannelStatus = "PENDING",
            ConnectionDetails = $"{protocol} {req.HostAddress}:{req.Port}".Trim(),
            EngineUrl = Blank(req.EngineUrl), EngineUser = Blank(req.EngineUser), EnginePassword = Blank(req.EnginePassword),
            EngineVerifyTls = req.EngineVerifyTls, EngineTemplateChannel = Blank(req.EngineTemplateChannel),
            EngineFirstListenPort = req.EngineFirstListenPort, HubPublicUrl = Blank(req.HubPublicUrl), EngineChannelUrl = Blank(req.EngineChannelUrl),
        };
        _db.Analyzers.Add(analyzer);
        await _db.SaveChangesAsync(ct);

        var message = await ProvisionAsync(analyzer, ct);
        await _db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(Get), new { id = analyzer.AnalyzerId }, new { analyzer, provisioningMessage = message });
    }

    /// <summary>(Re)creates the Open Integration Engine channel for this analyzer.</summary>
    [HttpPost("{id:int}/provision")]
    public async Task<IActionResult> Provision(int id, CancellationToken ct)
    {
        var a = await _db.Analyzers.FirstOrDefaultAsync(x => x.AnalyzerId == id, ct);
        if (a is null) return NotFound();
        var message = await ProvisionAsync(a, ct);
        await _db.SaveChangesAsync(ct);
        return Ok(new { analyzer = a, provisioningMessage = message });
    }

    /// <summary>Maps a machine test code to a lab parameter for this analyzer.</summary>
    [HttpPost("{id:int}/parameter-map")]
    public async Task<IActionResult> AddMap(int id, [FromBody] ParameterMapRequest req, CancellationToken ct)
    {
        if (!await _db.Analyzers.AnyAsync(a => a.AnalyzerId == id, ct)) return NotFound();
        if (!await _db.LabParameters.AnyAsync(p => p.LabParameterId == req.LabParameterId, ct)) return BadRequest(new { error = "Unknown lab parameter" });
        var map = await _db.AnalyzerParameterMaps.FirstOrDefaultAsync(m => m.AnalyzerId == id && m.MachineTestCode == req.MachineTestCode, ct);
        if (map is null) { map = new AnalyzerParameterMap { AnalyzerId = id, MachineTestCode = req.MachineTestCode }; _db.AnalyzerParameterMaps.Add(map); }
        map.LabParameterId = req.LabParameterId;
        map.ConversionFactor = req.ConversionFactor;
        await _db.SaveChangesAsync(ct);
        return Ok(map);
    }

    /// <summary>Parameter mappings of an analyzer.</summary>
    [HttpGet("{id:int}/parameter-map")]
    public async Task<IActionResult> GetMaps(int id, CancellationToken ct) =>
        Ok(await _db.AnalyzerParameterMaps.Where(m => m.AnalyzerId == id).ToListAsync(ct));

    /// <summary>All analyzers.</summary>
    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct) => Ok(await _db.Analyzers.OrderBy(a => a.AnalyzerId).ToListAsync(ct));

    /// <summary>One analyzer.</summary>
    [HttpGet("{id:int}")]
    public async Task<IActionResult> Get(int id, CancellationToken ct)
    {
        var a = await _db.Analyzers.FirstOrDefaultAsync(x => x.AnalyzerId == id, ct);
        return a is null ? NotFound() : Ok(a);
    }

    private static string? Blank(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private async Task<string> ProvisionAsync(Analyzer a, CancellationToken ct)
    {
        try
        {
            var r = await _hub.ProvisionAsync(new ProvisionInterfaceRequest(a.AnalyzerId, a.AnalyzerCode, a.AnalyzerName, a.InterfaceProtocol ?? "HL7V2",
                a.SendingApplicationId, a.HostAddress, a.Port, a.IsBidirectional,
                a.EngineUrl, a.EngineUser, a.EnginePassword, a.EngineVerifyTls, a.EngineTemplateChannel, a.EngineFirstListenPort,
                a.HubPublicUrl, a.EngineChannelUrl), ct);
            a.IntegrationChannelId = r.ChannelId;
            a.RoutingKey = r.RoutingKey;
            a.ChannelStatus = r.Status;
            return r.Message ?? r.Status;
        }
        catch (Exception ex)
        {
            _log.LogWarning(ex, "Integration Hub unavailable while provisioning analyzer {Code}", a.AnalyzerCode);
            a.ChannelStatus = "PENDING";
            return "Integration Hub unreachable - analyzer saved, channel pending. Call POST /api/analyzers/{id}/provision once the hub is up.";
        }
    }
}
