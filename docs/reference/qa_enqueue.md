# Enqueue a Study or Segmentation into the QA Review Queue

Enqueue a Study or Segmentation into the QA Review Queue

## Usage

``` r
qa_enqueue(
  qa_queue,
  project_id,
  study_uid,
  pred_mask = NULL,
  ref_mask = NULL,
  spacing_mm = c(1, 1, 1),
  tolerance_mm = 1,
  metrics = NULL,
  priority = "normal"
)
```

## Arguments

- qa_queue:

  A `"dicom_qa_queue"` object from
  [`qa_queue_init()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/qa_queue_init.md).

- project_id:

  Project identifier.

- study_uid:

  StudyInstanceUID string.

- pred_mask:

  Optional 3D predicted mask array.

- ref_mask:

  Optional 3D reference mask array.

- spacing_mm:

  Voxel spacing in mm (default `c(1, 1, 1)`).

- tolerance_mm:

  Surface Dice tolerance in mm (default `1.0`).

- metrics:

  Optional pre-computed list of QA metrics.

- priority:

  Priority label (`"normal"`, `"high"`, `"urgent"`).

## Value

Enqueued QA item list.
