# Add an Unlabeled Study Candidate to the Active Learning Pool

Add an Unlabeled Study Candidate to the Active Learning Pool

## Usage

``` r
active_learning_add_candidate(
  pool,
  project_id,
  study_uid,
  uncertainty_score = 0.5,
  metadata = list()
)
```

## Arguments

- pool:

  A `"dicom_active_learning_pool"` object.

- project_id:

  Project identifier.

- study_uid:

  StudyInstanceUID string.

- uncertainty_score:

  Model uncertainty score in `[0, 1]`.

- metadata:

  Optional named list of study metadata.

## Value

Candidate record list.
