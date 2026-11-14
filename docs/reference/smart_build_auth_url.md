# Build a SMART on FHIR v2 EHR-Launch Authorization URL

Build a SMART on FHIR v2 EHR-Launch Authorization URL

## Usage

``` r
smart_build_auth_url(
  config,
  client_id,
  redirect_uri,
  launch = NULL,
  scopes = c("launch", "openid", "fhirUser", "patient/Patient.rs",
    "patient/ImagingStudy.rs", "patient/DiagnosticReport.rs"),
  state = NULL,
  pkce = smart_pkce_challenge()
)
```

## Arguments

- config:

  SMART configuration list from
  [`smart_discover_config()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_discover_config.md).

- client_id:

  Registered OAuth2 client identifier.

- redirect_uri:

  Callback redirect URI.

- launch:

  Optional EHR launch context token.

- scopes:

  Character vector of SMART v2 scopes.

- state:

  Optional CSRF state token (auto-generated if `NULL`).

- pkce:

  PKCE challenge list from
  [`smart_pkce_challenge()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_pkce_challenge.md).

## Value

A list with `url`, `state`, and `pkce`.
