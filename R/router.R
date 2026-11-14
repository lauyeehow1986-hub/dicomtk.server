#' Define an Event-Driven Study Routing Rule
#'
#' @param rule_id Unique rule identifier string.
#' @param when_modality Optional modality filter (e.g. `"CT"`, `"MR"`).
#' @param when_event Event type filter (default `"study_ingested"`).
#' @param action Action to execute: `"enqueue_qa"`, `"deid_forward"`,
#'   `"notify"`, or `"custom"`.
#' @param target Optional target queue/endpoint name.
#' @param handler Optional callback `function(event)` used when `action = "custom"`.
#'
#' @return An S3 `"dicom_routing_rule"` object.
#' @examples
#' r <- routing_rule("ct_qa", when_modality = "CT", action = "enqueue_qa", target = "qa_default")
#' r$rule_id
#' @export
routing_rule <- function(rule_id,
                         when_modality = NULL,
                         when_event = "study_ingested",
                         action = c("enqueue_qa", "deid_forward", "notify", "custom"),
                         target = NULL,
                         handler = NULL) {
  srv_check_scalar_chr(rule_id, "rule_id")
  action <- match.arg(action)
  structure(
    list(
      rule_id = rule_id,
      when_modality = when_modality,
      when_event = when_event,
      action = action,
      target = target %||% "default",
      handler = handler
    ),
    class = "dicom_routing_rule"
  )
}

#' Execute Matching Event-Driven Routing Rules
#'
#' Requires `"routing_run"` capability (`coordinator`, `honest_broker`, or `admin`).
#'
#' @param rules List of `"dicom_routing_rule"` objects.
#' @param principal Authenticated `"dicom_server_principal"`.
#' @param event Named list with `event_type`, `project_id`, `modality`,
#'   and `study_uid`.
#' @param logger Optional `"dicom_audit_logger"`.
#'
#' @return A `tibble::tibble` summarizing matched and dispatched rules.
#' @export
routing_execute <- function(rules, principal, event, logger = NULL) {
  check_permission(principal, "routing_run", project_id = event$project_id, throw = TRUE)
  if (!is.list(rules)) {
    cli::cli_abort("{.arg rules} must be a list of {.cls dicom_routing_rule} objects.")
  }

  matched <- Filter(function(r) {
    ev_ok <- is.null(r$when_event) || identical(r$when_event, event$event_type)
    mod_ok <- is.null(r$when_modality) || identical(r$when_modality, event$modality)
    ev_ok && mod_ok
  }, rules)

  if (length(matched) == 0L) {
    return(tibble::tibble(
      rule_id = character(0), action = character(0),
      target = character(0), status = character(0)
    ))
  }

  rows <- lapply(matched, function(r) {
    if (identical(r$action, "custom") && is.function(r$handler)) {
      r$handler(event)
    }
    if (!is.null(logger)) {
      audit_append(
        logger,
        actor = principal$user_id,
        action = "routing_run",
        project_id = event$project_id,
        details = list(rule_id = r$rule_id, action = r$action, target = r$target, study_uid = event$study_uid)
      )
    }
    tibble::tibble(
      rule_id = r$rule_id,
      action = r$action,
      target = r$target,
      status = "dispatched"
    )
  })
  tibble::as_tibble(do.call(rbind, rows))
}
