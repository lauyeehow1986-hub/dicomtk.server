# Generate a CycloneDX 1.5 Software Bill of Materials (SBOM)

Inspects the installed or source `DESCRIPTION` of `pkg` and its R
package dependencies to emit a CycloneDX 1.5 JSON Software Bill of
Materials with `pkg:cran/` Package URLs (`purl`).

## Usage

``` r
server_generate_sbom(pkg = "dicomtk.server", out_path = NULL)
```

## Arguments

- pkg:

  Package name (default `"dicomtk.server"`).

- out_path:

  Optional file path to write the CycloneDX JSON document.

## Value

A list representing the CycloneDX 1.5 BOM.

## Examples

``` r
sbom <- server_generate_sbom("dicomtk.server")
sbom$bomFormat
#> [1] "CycloneDX"
```
