# Check Whether SaMD Clinical Chart Write-Back Is Explicitly Enabled

Clinical write-back (`STOW-RS` `SEG`/`SR` + FHIR `DiagnosticReport` +
`Provenance`) is disabled by default as a Software as a Medical Device
(SaMD) regulatory safeguard. Enable explicitly via
`options(dicomtk.server.enable_clinical_writeback = TRUE)` or
environment variable `DICOMTK_ENABLE_CLINICAL_WRITEBACK=true`.

## Usage

``` r
clinical_writeback_enabled()
```

## Value

Logical scalar (`TRUE` if enabled, `FALSE` otherwise).

## Examples

``` r
clinical_writeback_enabled()
#> [1] FALSE
```
