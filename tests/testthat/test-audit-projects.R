test_that("audit_logger writes SHA-256 hash-chained JSONL and detects tampering", {
  log_path <- tempfile(fileext = ".jsonl")
  on.exit(unlink(log_path), add = TRUE)

  logger <- audit_logger(log_path)
  expect_s3_class(logger, "dicom_audit_logger")

  e1 <- audit_append(logger, actor = "coord_1", action = "deid_ingest", project_id = "proj_a")
  e2 <- audit_append(logger, actor = "pi_1", action = "reid_request", project_id = "proj_a",
                     details = list(pseudonym_id = "SUBJ-001"))
  expect_equal(e2$prev_hash, e1$entry_hash)

  ver_ok <- audit_verify(logger)
  expect_true(isTRUE(ver_ok$passed))
  expect_equal(ver_ok$n_entries, 2L)

  # Tamper with line 1 and verify audit_verify detects it
  lines <- readLines(log_path, warn = FALSE)
  lines[1L] <- sub("coord_1", "evil_user", lines[1L], fixed = TRUE)
  writeLines(lines, log_path)

  ver_bad <- audit_verify(logger)
  expect_false(isTRUE(ver_bad$passed))
  expect_gte(ver_bad$corrupted_line, 1L)
})

test_that("project_registry_init, project_create, and project_get manage projects", {
  reg <- project_registry_init()
  p <- project_create(reg, project_id = "nsclc_01", title = "Lung AI Trial",
                      deid_profile = "ps3.15", custody_mode = "broker")
  expect_equal(p$project_id, "nsclc_01")
  expect_equal(p$custody_mode, "broker")

  fetched <- project_get(reg, "nsclc_01")
  expect_equal(fetched$title, "Lung AI Trial")
  expect_true("nsclc_01" %in% project_list(reg)$project_id)
})
