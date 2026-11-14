# Submit a QA Review Decision

Requires `"qa_review"` capability (`pi`, `annotator`, or `admin`).

## Usage

``` r
qa_submit_review(
  qa_queue,
  principal,
  item_id,
  decision = c("approve", "reject", "revise"),
  notes = NULL
)
```

## Arguments

- qa_queue:

  A `"dicom_qa_queue"` object.

- principal:

  Authenticated `"dicom_server_principal"`.

- item_id:

  QA item identifier returned by
  [`qa_enqueue()`](https://lauyeehow1986-hub.github.io/dicomtk.server/reference/qa_enqueue.md).

- decision:

  Review decision: `"approve"`, `"reject"`, or `"revise"`.

- notes:

  Optional reviewer notes.

## Value

Updated QA item list.
