# Exchange a SMART Authorization Code for a Patient-Context Session

Verifies CSRF `state` equality and RFC 7636 `code_verifier` length
before exchanging the authorization code at `config$token_endpoint`.

## Usage

``` r
smart_exchange_token(
  config,
  code,
  redirect_uri,
  client_id,
  code_verifier,
  expected_state = NULL,
  received_state = NULL,
  mock_response = NULL
)
```

## Arguments

- config:

  SMART configuration list from
  [`smart_discover_config()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_discover_config.md).

- code:

  Authorization code received at `redirect_uri`.

- redirect_uri:

  Callback redirect URI.

- client_id:

  Registered OAuth2 client identifier.

- code_verifier:

  PKCE `code_verifier` matching the `code_challenge`.

- expected_state:

  Expected CSRF `state` generated in
  [`smart_build_auth_url()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/smart_build_auth_url.md).

- received_state:

  `state` query parameter returned by the auth server.

- mock_response:

  Optional named list for offline/unit testing.

## Value

An S3 `"dicom_smart_session"` object.
