using Hims.Common.Http;
using Hims.Common.Logging;
using Hims.Imaging.Data;

// Imaging (RIMS + PACS): data model + API host + event plumbing are in place; no workflow screens or endpoints yet.
// Every table of database/04_imaging.sql is already mapped in Data/ImagingDbContext.g.cs.
var builder = WebApplication.CreateBuilder(args);
builder.AddHimsFileLogging("imaging");   // logs/imaging/dd-MM-yyyy.log (+ dd-MM-yyyy-error.log)
builder.AddHimsService<ImagingDbContext>("imaging", "HIMS Imaging (RIMS + PACS)",
    "Radiology procedures, modalities, scheduling, reporting and the PACS/DICOM index. (Scaffold: data model mapped, no workflow endpoints yet.)");

builder.Services.AddRefReplica<ImagingDbContext, RefEmployee>("EmployeeUpdated");   // hr.employee copies, published by Identity & Org

var app = builder.Build();
app.UseHims<ImagingDbContext>();
app.Run();
