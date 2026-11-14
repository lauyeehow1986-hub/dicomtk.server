# Dispatch an HTTP-Style Request Against a `dicom_server_context`

Provides a pure-R, test-friendly REST dispatcher enforcing JWT
authentication and RBAC permissions before delegating to server
subsystems.

## Usage

``` r
server_handle_request(
  ctx,
  method = "GET",
  path = "/health",
  headers = list(),
  body = list()
)
```

## Arguments

- ctx:

  A `"dicom_server_context"` from
  [`server_create_context()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_create_context.md).

- method:

  HTTP method (`"GET"` or `"POST"`).

- path:

  Request path (e.g. `"/health"`, `"/projects"`, `"/qa"`,
  `"/audit/verify"`).

- headers:

  Named list of HTTP headers (including `Authorization`).

- body:

  Named list representing parsed JSON request body.

## Value

A list with `status` (integer HTTP code) and `body` (response list).
