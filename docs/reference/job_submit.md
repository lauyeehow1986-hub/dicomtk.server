# Submit a Job to the Server Job Queue

Requires `"job_submit"` permission on `project_id`.

## Usage

``` r
job_submit(
  queue,
  principal,
  project_id,
  fn,
  args = list(),
  job_type = "generic"
)
```

## Arguments

- queue:

  A `"dicom_job_queue"` from
  [`job_queue_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/job_queue_init.md).

- principal:

  Authenticated `"dicom_server_principal"`.

- project_id:

  Target project identifier.

- fn:

  Function to execute.

- args:

  Named list of arguments passed to `fn`.

- job_type:

  Short job category string (default `"generic"`).

## Value

A list with `job_id`, `project_id`, `job_type`, and `status`.
