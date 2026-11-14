# Execute Matching Event-Driven Routing Rules

Requires `"routing_run"` capability (`coordinator`, `honest_broker`, or
`admin`).

## Usage

``` r
routing_execute(rules, principal, event, logger = NULL)
```

## Arguments

- rules:

  List of `"dicom_routing_rule"` objects.

- principal:

  Authenticated `"dicom_server_principal"`.

- event:

  Named list with `event_type`, `project_id`, `modality`, and
  `study_uid`.

- logger:

  Optional `"dicom_audit_logger"`.

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
summarizing matched and dispatched rules.
