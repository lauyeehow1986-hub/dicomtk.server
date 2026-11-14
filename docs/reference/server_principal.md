# Construct an Authenticated Server Principal

Construct an Authenticated Server Principal

## Usage

``` r
server_principal(user_id, roles, project_ids = "*")
```

## Arguments

- user_id:

  Unique user identifier string.

- roles:

  Character vector of roles from
  [`server_roles()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/server_roles.md).

- project_ids:

  Character vector of authorized project IDs (or `"*"` for all).

## Value

An S3 `"dicom_server_principal"` object.
