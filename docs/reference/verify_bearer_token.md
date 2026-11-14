# Verify an OIDC / Keycloak Bearer Token and Return a Server Principal

Verify an OIDC / Keycloak Bearer Token and Return a Server Principal

## Usage

``` r
verify_bearer_token(token, secret = NULL, oidc_userinfo_url = NULL)
```

## Arguments

- token:

  Bearer token string (with or without `"Bearer "` prefix).

- secret:

  HMAC secret for verifying local test JWTs.

- oidc_userinfo_url:

  Optional Keycloak OIDC `/userinfo` endpoint URL.

## Value

A `"dicom_server_principal"` object.
