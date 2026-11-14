testthat::test_that("clinical write-back enforces dual-gate SaMD feature flag, RBAC, and audit trail", {
  tmp_dir <- tempfile("wb_ctx_")
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  ctx <- server_create_context(work_dir = tmp_dir, jwt_secret = "wb-secret")

  adm_p <- server_principal("adm-1", roles = "admin", project_ids = "*")
  pi_p <- server_principal("pi-1", roles = "pi", project_ids = "proj-1")
  ann_p <- server_principal("ann-1", roles = "annotator", project_ids = "proj-1")

  air <- ihe_air_bundle(
    study_uid = "1.2.3.4",
    model_name = "TotalSegmentator",
    model_version = "2.4.0",
    dicom_artifact_type = "SEG",
    dicom_sop_uid = "1.2.3.99"
  )

  withr::local_envvar(c(DICOMTK_ENABLE_CLINICAL_WRITEBACK = ""))
  withr::local_options(list(dicomtk.server.enable_clinical_writeback = FALSE))

  testthat::expect_false(clinical_writeback_enabled())
  testthat::expect_error(
    clinical_writeback_execute(ctx, adm_p, project_id = "proj-1", air_bundle = air, dry_run = TRUE),
    "disabled|SaMD"
  )

  withr::local_options(list(dicomtk.server.enable_clinical_writeback = TRUE))
  testthat::expect_true(clinical_writeback_enabled())

  testthat::expect_error(
    clinical_writeback_execute(ctx, ann_p, project_id = "proj-1", air_bundle = air, dry_run = TRUE),
    "[Pp]ermission"
  )

  res <- clinical_writeback_execute(ctx, pi_p, project_id = "proj-1", air_bundle = air, dry_run = TRUE)
  testthat::expect_equal(res$status, "dry_run_ok")
  testthat::expect_true(audit_verify(ctx$logger)$passed)
  lines <- readLines(ctx$logger$log_path, warn = FALSE)
  testthat::expect_true(any(grepl("clinical_writeback", lines, fixed = TRUE)))
})
