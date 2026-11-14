# Discover SMART on FHIR v2 Configuration

Queries `<fhir_base_url>/.well-known/smart-configuration` (or validates
a supplied `mock_config` list) and verifies that `"S256"` PKCE is
supported.

## Usage

``` r
smart_discover_config(fhir_base_url, mock_config = NULL)
```

## Arguments

- fhir_base_url:

  Base URL of the FHIR R4/R5 server.

- mock_config:

  Optional named list for offline/unit testing.

## Value

A list with `fhir_base_url`, `authorization_endpoint`, `token_endpoint`,
and `code_challenge_methods_supported`.

## Examples

``` r
cfg <- smart_discover_config(
  "https://fhir.example.org/r4",
  mock_config = list(
    authorization_endpoint = "https://auth.example.org/authorize",
    token_endpoint = "https://auth.example.org/token",
    code_challenge_methods_supported = "S256"
  )
)
cfg$authorization_endpoint
#> [1] "https://auth.example.org/authorize"
```
