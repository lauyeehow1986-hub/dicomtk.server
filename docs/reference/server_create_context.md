# Create a Multi-User `dicomtk.server` Runtime Context

Bundles the project registry, SHA-256 hash-chained audit logger,
walled-off honest-broker custody enclave, job queue, QA review queue,
and active learning pool into a single server context.

## Usage

``` r
server_create_context(
  work_dir = tempfile("dicomtk_srv_"),
  jwt_secret = "change-me-in-production",
  enclave_passphrase = NULL
)
```

## Arguments

- work_dir:

  Base directory for server state and audit logs.

- jwt_secret:

  Secret key for HS256 JWT verification.

- enclave_passphrase:

  Optional passphrase for the honest-broker enclave.

## Value

An S3 `"dicom_server_context"` object.

## Examples

``` r
tmp <- tempfile("srv_ctx_")
ctx <- server_create_context(work_dir = tmp, jwt_secret = "demo-secret")
server_handle_request(ctx, "GET", "/health")
#> $status
#> [1] 200
#> 
#> $body
#> $body$status
#> [1] "ok"
#> 
#> $body$service
#> [1] "dicomtk.server"
#> 
#> $body$version
#> [1] "1.0.0"
#> 
#> 
unlink(tmp, recursive = TRUE)
```
