# List QA Queue Items

List QA Queue Items

## Usage

``` r
qa_list(qa_queue, project_id = NULL, status = NULL)
```

## Arguments

- qa_queue:

  A `"dicom_qa_queue"` object.

- project_id:

  Optional project filter.

- status:

  Optional status filter (`"pending"`, `"approved"`, etc.).

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
of QA items.
