# Transition an IHE AIW-I Workitem State

Enforces valid UPS-RS state transitions: `"SCHEDULED"` -\>
`"IN PROGRESS"` or `"CANCELED"`; `"IN PROGRESS"` -\> `"COMPLETED"` or
`"CANCELED"`.

## Usage

``` r
ihe_aiw_transition(
  workitem,
  to_state = c("IN PROGRESS", "COMPLETED", "CANCELED"),
  performer = NULL,
  output_refs = list()
)
```

## Arguments

- workitem:

  A `"dicom_ihe_workitem"` from
  [`ihe_aiw_workitem()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/ihe_aiw_workitem.md).

- to_state:

  Target state: `"IN PROGRESS"`, `"COMPLETED"`, or `"CANCELED"`.

- performer:

  Optional AI worker/performer identifier.

- output_refs:

  Optional named list of generated DICOM SOP UIDs.

## Value

Updated `"dicom_ihe_workitem"` object.
