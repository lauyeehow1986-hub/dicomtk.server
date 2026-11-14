# Create an IHE AIW-I (AI Workflow for Imaging) UPS-RS Workitem

Initializes a workitem in the `"SCHEDULED"` state following the IHE
AIW-I Unified Procedure Step (UPS-RS) state machine.

## Usage

``` r
ihe_aiw_workitem(workitem_id, study_uid, model_name, input_series_uid = NULL)
```

## Arguments

- workitem_id:

  Unique workitem identifier string.

- study_uid:

  StudyInstanceUID string.

- model_name:

  AI model identifier string.

- input_series_uid:

  Optional SeriesInstanceUID string.

## Value

An S3 `"dicom_ihe_workitem"` object.

## Examples

``` r
wi <- ihe_aiw_workitem("wi-001", study_uid = "1.2.3.4", model_name = "TotalSegmentator")
wi$state
#> [1] "SCHEDULED"
```
