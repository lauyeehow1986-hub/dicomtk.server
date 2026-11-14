# Return the `dicomtk.server` STRIDE Threat Model Matrix

Documents security threats, architectural mitigations, and automated
verification controls across all six STRIDE categories (`Spoofing`,
`Tampering`, `Repudiation`, `Information Disclosure`,
`Denial of Service`, and `Elevation of Privilege`).

## Usage

``` r
server_threat_model()
```

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
describing the threat model.

## Examples

``` r
tm <- server_threat_model()
tm$stride_category
#> [1] "Spoofing"               "Tampering"              "Repudiation"           
#> [4] "Information Disclosure" "Denial of Service"      "Elevation of Privilege"
```
