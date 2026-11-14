# Construct and Validate an IHE AIR (AI Results) Conformance Bundle

Packages a generated DICOM AI artifact (`SEG` or `SR_TID1500`) alongside
a FHIR `DiagnosticReport` and W3C/FHIR `Provenance` record with model
version and uncertainty metadata.

## Usage

``` r
ihe_air_bundle(
  study_uid,
  model_name,
  model_version,
  dicom_artifact_type = c("SEG", "SR_TID1500"),
  dicom_sop_uid,
  fhir_report = list(),
  uncertainty_summary = list()
)
```

## Arguments

- study_uid:

  StudyInstanceUID string.

- model_name:

  AI model name.

- model_version:

  AI model semantic version string.

- dicom_artifact_type:

  Either `"SEG"` or `"SR_TID1500"`.

- dicom_sop_uid:

  SOPInstanceUID of the generated DICOM AI object.

- fhir_report:

  Named list of FHIR `DiagnosticReport` fields.

- uncertainty_summary:

  Named list of model uncertainty metrics.

## Value

An S3 `"dicom_ihe_air_bundle"` object.

## Examples

``` r
air <- ihe_air_bundle(
  study_uid = "1.2.3.4",
  model_name = "TotalSegmentator",
  model_version = "2.4.0",
  dicom_artifact_type = "SEG",
  dicom_sop_uid = "1.2.3.99"
)
air$provenance$resourceType
#> [1] "Provenance"
```
