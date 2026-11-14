testthat::test_that("two-person re-identification workflow enforces broker + dpo separation and TTL", {
  tmp_root <- tempfile("dicomtk_reid_")
  on.exit(unlink(tmp_root, recursive = TRUE, force = TRUE), add = TRUE)
  dir.create(tmp_root, recursive = TRUE)

  aud_log <- audit_logger(file.path(tmp_root, "broker_audit.jsonl"))
  enc <- broker_enclave_init(file.path(tmp_root, "enclave"), passphrase = "secret-passphrase", logger = aud_log)

  coord_p <- server_principal("coord-1", roles = "coordinator", project_ids = "proj-reid")
  pi_p <- server_principal("pi-1", roles = "pi", project_ids = "proj-reid")
  broker_p <- server_principal("broker-1", roles = "honest_broker", project_ids = "*")
  dpo_p <- server_principal("dpo-1", roles = "dpo", project_ids = "*")
  dual_p <- server_principal("broker-1", roles = c("honest_broker", "dpo"), project_ids = "*")

  synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(8L, 8L, 2L), phi_profile = "basic")
  on.exit(unlink(synth[["out_dir"]], recursive = TRUE, force = TRUE), add = TRUE)
  hdr <- dicomtk::read_dicom(synth[["out_dir"]], wide = TRUE)
  orig_pid <- hdr$PatientID[1L]

  deid_dir <- file.path(tmp_root, "deid")
  deid_res <- broker_deid_study(enc, coord_p, project_id = "proj-reid", input_dir = synth[["out_dir"]], out_dir = deid_dir)

  req <- reid_request(
    enclave = enc,
    principal = pi_p,
    project_id = "proj-reid",
    pseudonym_id = deid_res$pseudonym_id,
    reason = "urgent_incidental_finding",
    ttl_seconds = 120L
  )
  testthat::expect_equal(req$status, "pending")
  testthat::expect_error(reid_disclose(enc, broker_p, req$request_id), "approved")

  req_b <- reid_approve(enc, broker_p, req$request_id)
  testthat::expect_equal(req_b$status, "partial_broker")
  testthat::expect_error(reid_disclose(enc, broker_p, req$request_id), "approved")

  # Same user_id cannot provide both approvals
  testthat::expect_error(reid_approve(enc, dual_p, req$request_id), "distinct")

  req_d <- reid_approve(enc, dpo_p, req$request_id)
  testthat::expect_equal(req_d$status, "approved")

  # PI cannot disclose even when approved
  testthat::expect_error(reid_disclose(enc, pi_p, req$request_id), "[Pp]ermission")

  disc <- reid_disclose(enc, broker_p, req$request_id)
  testthat::expect_equal(disc$original_patient_id, orig_pid)
  testthat::expect_equal(disc$pseudonym_id, deid_res$pseudonym_id)

  # Expired TTL request cannot be disclosed
  req_exp <- reid_request(
    enclave = enc,
    principal = pi_p,
    project_id = "proj-reid",
    pseudonym_id = deid_res$pseudonym_id,
    reason = "expired_test",
    ttl_seconds = 0L
  )
  reid_approve(enc, broker_p, req_exp$request_id)
  reid_approve(enc, dpo_p, req_exp$request_id)
  Sys.sleep(0.05)
  testthat::expect_error(reid_disclose(enc, broker_p, req_exp$request_id), "expired")

  # Audit log recorded the disclosure and passes hash-chain verification
  testthat::expect_true(audit_verify(aud_log)$passed)
  lines <- readLines(aud_log$log_path, warn = FALSE)
  testthat::expect_true(any(grepl("reid_disclose", lines, fixed = TRUE)))

  # Adversarial: PI authorized on proj-other cannot spoof project_id to request re-ID of proj-reid pseudonym
  pi_other <- server_principal("pi-other", roles = "pi", project_ids = "proj-other")
  testthat::expect_error(
    reid_request(
      enclave = enc,
      principal = pi_other,
      project_id = "proj-other",
      pseudonym_id = deid_res$pseudonym_id,
      reason = "cross_project_spoof"
    ),
    "mismatch"
  )
})
