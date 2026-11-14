# Check Role-Based Access Permission for a Principal

Check Role-Based Access Permission for a Principal

## Usage

``` r
check_permission(principal, action, project_id = NULL, throw = TRUE)
```

## Arguments

- principal:

  A `"dicom_server_principal"` from
  [`server_principal()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_principal.md).

- action:

  Action capability string (e.g., `"reid_approve_broker"`).

- project_id:

  Optional project ID to check project-level scope.

- throw:

  Logical. Abort with permission error if unauthorized (`TRUE`).

## Value

Logical `TRUE` if authorized, `FALSE` otherwise (when `throw = FALSE`).
