# Generate an HTML5 Zero-Footprint Medical Imaging Viewer Scaffold

Produces a lightweight HTML5 container configured for Cornerstone3D
(DICOMweb WADO-RS) or NiiVue (NIfTI / 3D overlay QA).

## Usage

``` r
server_viewer_html(
  study_uid = "",
  viewer = c("cornerstone3d", "niivue"),
  dicomweb_url = "/dicomweb"
)
```

## Arguments

- study_uid:

  StudyInstanceUID to display.

- viewer:

  Viewer engine: `"cornerstone3d"` or `"niivue"`.

- dicomweb_url:

  Base DICOMweb endpoint URL.

## Value

Character string containing the HTML5 viewer fragment.

## Examples

``` r
html <- server_viewer_html("1.2.840.113619.2.55", viewer = "cornerstone3d")
grepl("cornerstone3d", html)
#> [1] TRUE
```
