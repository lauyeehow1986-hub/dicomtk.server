# Initialize a Multi-Project Server Registry

Initialize a Multi-Project Server Registry

## Usage

``` r
project_registry_init()
```

## Value

An S3 `"dicom_project_registry"` object.

## Examples

``` r
reg <- project_registry_init()
project_create(reg, "nsclc_01", title = "Lung AI")
#> $project_id
#> [1] "nsclc_01"
#> 
#> $title
#> [1] "Lung AI"
#> 
#> $deid_profile
#> [1] "ps3.15"
#> 
#> $custody_mode
#> [1] "broker"
#> 
#> $created_at
#> [1] "2026-11-14T15:21:11Z"
#> 
project_list(reg)
#> # A tibble: 1 × 5
#>   project_id title   deid_profile custody_mode created_at          
#>   <chr>      <chr>   <chr>        <chr>        <chr>               
#> 1 nsclc_01   Lung AI ps3.15       broker       2026-11-14T15:21:11Z
```
