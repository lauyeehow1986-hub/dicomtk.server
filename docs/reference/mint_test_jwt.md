# Mint a Signed Local Test OIDC JWT Token

Mint a Signed Local Test OIDC JWT Token

## Usage

``` r
mint_test_jwt(
  user_id,
  roles,
  project_ids = "*",
  secret = "dicomtk-test-secret",
  expires_in = 3600
)
```

## Arguments

- user_id:

  Subject user ID (`sub` claim).

- roles:

  Character vector of Keycloak `realm_access$roles`.

- project_ids:

  Character vector of authorized project IDs.

- secret:

  HMAC signing secret.

- expires_in:

  Expiration offset in seconds (default `3600`).

## Value

A signed compact JWT string (`header.payload.signature`).
