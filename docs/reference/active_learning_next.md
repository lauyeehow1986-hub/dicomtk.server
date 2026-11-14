# Select Next Candidate(s) for Annotation

Select Next Candidate(s) for Annotation

## Usage

``` r
active_learning_next(pool, project_id = NULL, n = 1L)
```

## Arguments

- pool:

  A `"dicom_active_learning_pool"` object.

- project_id:

  Optional project filter.

- n:

  Maximum number of candidates to return (default `1L`).

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
of prioritized unlabeled candidates.
