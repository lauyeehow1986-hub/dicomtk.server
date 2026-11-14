# Create or Register a Research Imaging Project

Create or Register a Research Imaging Project

## Usage

``` r
project_create(
  registry,
  project_id,
  title = project_id,
  deid_profile = "ps3.15",
  custody_mode = c("broker", "ttp", "local")
)
```

## Arguments

- registry:

  A `"dicom_project_registry"` from
  [`project_registry_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/project_registry_init.md).

- project_id:

  Unique project identifier string.

- title:

  Human-readable project title.

- deid_profile:

  Baseline PS3.15 de-identification profile name (default `"ps3.15"`).

- custody_mode:

  Key custody mode: `"broker"` (default), `"ttp"`, or `"local"`.

## Value

A list describing the created project.
