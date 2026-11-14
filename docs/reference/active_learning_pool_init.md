# Initialize a MONAI Label / Active Learning Candidate Pool

Initialize a MONAI Label / Active Learning Candidate Pool

## Usage

``` r
active_learning_pool_init(
  strategy = c("uncertainty", "fifo", "random"),
  logger = NULL
)
```

## Arguments

- strategy:

  Selection strategy: `"uncertainty"`, `"fifo"`, or `"random"`.

- logger:

  Optional `"dicom_audit_logger"` for label submission auditing.

## Value

An S3 `"dicom_active_learning_pool"` object.

## Examples

``` r
pool <- active_learning_pool_init(strategy = "uncertainty")
pool$strategy
#> [1] "uncertainty"
```
