# Submit a Completed Annotation Label to the Active Learning Pool

Requires `"active_learning_submit"` capability (`annotator`).

## Usage

``` r
active_learning_submit(
  pool,
  principal,
  candidate_id,
  label_path = NULL,
  quality_score = NA_real_
)
```

## Arguments

- pool:

  A `"dicom_active_learning_pool"` object.

- principal:

  Authenticated `"dicom_server_principal"`.

- candidate_id:

  Candidate identifier from
  [`active_learning_add_candidate()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/active_learning_add_candidate.md).

- label_path:

  Optional path to saved segmentation/label file.

- quality_score:

  Optional numeric self-reported quality score.

## Value

Updated candidate record list.
