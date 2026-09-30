using System.ComponentModel.DataAnnotations;
using Hims.ClinicalCare.Data;
using Hims.Common.Events;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Hims.ClinicalCare.Controllers;

public class DiagnosisInput
{
    [Required] public string Text { get; set; } = string.Empty;
    /// <summary>PROVISIONAL, DIFFERENTIAL, FINAL, ...</summary>
    public string Type { get; set; } = "PROVISIONAL";
    public bool IsPrimary { get; set; }
}

public class ConsultationRequest
{
    [Required] public long EncounterId { get; set; }
    public long? AuthorPractitionerId { get; set; }
    [Required] public string ChiefComplaint { get; set; } = string.Empty;
    public string? Subjective { get; set; }
    public string? Objective { get; set; }
    public string? Assessment { get; set; }
    public string? Plan { get; set; }
    public List<DiagnosisInput> Diagnoses { get; set; } = new();
}

/// <summary>OP consultation: chief complaint (emr.complaint), SOAP note (emr.clinical_document) and diagnoses (emr.diagnosis).</summary>
[ApiController]
[Route("api/consultations")]
public class ConsultationsController : ControllerBase
{
    private readonly ClinicalCareDbContext _db;
    public ConsultationsController(ClinicalCareDbContext db) => _db = db;

    /// <summary>Records the consultation and publishes ClinicalNoteSigned and DiagnosisRecorded.</summary>
    [HttpPost]
    public async Task<IActionResult> Record([FromBody] ConsultationRequest req, CancellationToken ct)
    {
        var enc = await _db.RefEncounters.FirstOrDefaultAsync(e => e.EncounterId == req.EncounterId, ct);
        if (enc?.PatientId is null || enc.OrganizationId is null || enc.BranchId is null)
            return Conflict(new { error = $"Encounter {req.EncounterId} has not replicated into Clinical Care yet; retry in a moment." });
        if (enc.EncounterStatus == "COMPLETED") return BadRequest(new { error = "The encounter is already closed" });

        var now = DateTime.UtcNow;
        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var complaint = new Complaint { EncounterId = req.EncounterId, PatientId = enc.PatientId.Value, ComplaintText = req.ChiefComplaint, IsChief = true };
        _db.Complaints.Add(complaint);

        var doc = new ClinicalDocument
        {
            OrganizationId = enc.OrganizationId.Value, BranchId = enc.BranchId.Value, DocumentGroupId = Guid.NewGuid(),
            PatientId = enc.PatientId.Value, EncounterId = req.EncounterId, DocumentType = "SOAP", Title = "OP consultation note",
            SubjectiveJson = Json(req.Subjective ?? req.ChiefComplaint), ObjectiveJson = req.Objective is null ? null : Json(req.Objective),
            AssessmentJson = req.Assessment is null ? null : Json(req.Assessment), PlanJson = req.Plan is null ? null : Json(req.Plan),
            InputMode = "TYPED", AuthorPractitionerId = req.AuthorPractitionerId ?? enc.AttendingPractitionerId,
            DocumentStatus = "FINAL", SignedBy = req.AuthorPractitionerId ?? enc.AttendingPractitionerId, SignedAt = now, EffectiveAt = now,
        };
        _db.ClinicalDocuments.Add(doc);

        var diagnoses = req.Diagnoses.Where(d => !string.IsNullOrWhiteSpace(d.Text)).Select(d => new Diagnosis
        {
            PatientId = enc.PatientId.Value, EncounterId = req.EncounterId, DiagnosisText = d.Text.Trim(), DiagnosisType = d.Type,
            IsPrimary = d.IsPrimary, DiagnosedBy = req.AuthorPractitionerId ?? enc.AttendingPractitionerId,
        }).ToList();
        foreach (var d in diagnoses) _db.Diagnoses.Add(d);
        await _db.SaveChangesAsync(ct);

        _db.EnqueueEvent("ClinicalNoteSigned", "emr.clinical_document", doc.ClinicalDocumentId,
            new { doc.ClinicalDocumentId, doc.EncounterId, doc.PatientId, doc.DocumentType, doc.Title, doc.SignedAt },
            doc.OrganizationId, doc.BranchId, doc.PatientId);
        foreach (var d in diagnoses)
            _db.EnqueueEvent("DiagnosisRecorded", "emr.diagnosis", d.DiagnosisId, d, doc.OrganizationId, doc.BranchId, d.PatientId);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        return Created($"/api/consultations?encounterId={req.EncounterId}",
            new { doc.ClinicalDocumentId, complaint.ComplaintId, diagnosisIds = diagnoses.Select(d => d.DiagnosisId) });
    }

    /// <summary>Consultation notes, complaints and diagnoses of an encounter.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] long encounterId, CancellationToken ct)
    {
        var docs = await _db.ClinicalDocuments.Where(d => d.EncounterId == encounterId).OrderByDescending(d => d.ClinicalDocumentId).ToListAsync(ct);
        var complaints = await _db.Complaints.Where(c => c.EncounterId == encounterId).ToListAsync(ct);
        var diagnoses = await _db.Diagnoses.Where(d => d.EncounterId == encounterId).ToListAsync(ct);
        return Ok(new { documents = docs, complaints, diagnoses });
    }

    private static string Json(string text) => EventJson.Serialize(new { text });
}
