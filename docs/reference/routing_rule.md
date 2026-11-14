# Define an Event-Driven Study Routing Rule

Define an Event-Driven Study Routing Rule

## Usage

``` r
routing_rule(
  rule_id,
  when_modality = NULL,
  when_event = "study_ingested",
  action = c("enqueue_qa", "deid_forward", "notify", "custom"),
  target = NULL,
  handler = NULL
)
```

## Arguments

- rule_id:

  Unique rule identifier string.

- when_modality:

  Optional modality filter (e.g. `"CT"`, `"MR"`).

- when_event:

  Event type filter (default `"study_ingested"`).

- action:

  Action to execute: `"enqueue_qa"`, `"deid_forward"`, `"notify"`, or
  `"custom"`.

- target:

  Optional target queue/endpoint name.

- handler:

  Optional callback `function(event)` used when `action = "custom"`.

## Value

An S3 `"dicom_routing_rule"` object.

## Examples

``` r
r <- routing_rule("ct_qa", when_modality = "CT", action = "enqueue_qa", target = "qa_default")
r$rule_id
#> [1] "ct_qa"
```
