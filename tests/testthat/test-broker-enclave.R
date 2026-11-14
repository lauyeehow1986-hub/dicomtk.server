test_that("broker_enclave_init walls off key material and crosswalk from pi and non-broker roles", {
  synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(8L, 8L, 2L), phi_profile = "basic")
  work_dir <- tempfile("broker_ws_")
  out_dir <- tempfile("proj_deid_")
  audit_path <- tempfile(fileext = ".jsonl")
  on.exit(unlink(c(synth[["out_dir"]], work_dir, out_dir, audit_path), recursive = TRUE), add = TRUE)

  hdr <- dicomtk::read_dicom(synth[["out_dir"]], wide = TRUE)
  orig_pid <- hdr$PatientID[1L]

  logger <- audit_logger(audit_path)
  enclave <- broker_enclave_init(
    work_dir = work_dir,
    backend = "local_vault",
    passphrase = "ultra-secret-broker-passphrase-2026",
    logger = logger
  )
  expect_s3_class(enclave, "dicom_broker_enclave")

  p_hb <- server_principal("hb_1", roles = "honest_broker")
  p_pi <- server_principal("pi_1", roles = "pi", project_ids = "proj_1")

  # Only coordinator/honest_broker/admin can ingest into broker de-id
  expect_error(
    broker_deid_study(enclave, p_pi, project_id = "proj_1", input_dir = synth[["out_dir"]], out_dir = out_dir),
    "denied|permission"
  )

  res <- broker_deid_study(
    enclave,
    principal = p_hb,
    project_id = "proj_1",
    input_dir = synth[["out_dir"]],
    out_dir = out_dir
  )
  expect_true(dir.exists(out_dir))
  expect_gte(res$n_files, 1L)
  expect_true(nzchar(res$pseudonym_id))
  expect_false(identical(res$pseudonym_id, orig_pid))

  # Property test: 100 randomized inspection/extraction attempts by non-broker roles
  # must NEVER leak the passphrase, key material, or unapproved original_patient_id
  non_broker_roles <- c("pi", "coordinator", "annotator", "auditor", "admin", "site_admin")
  set.seed(20261114L)
  for (i in seq_len(100L)) {
    r <- sample(non_broker_roles, 1L)
    prin <- server_principal(paste0("u_", i), roles = r)

    # 1. Printing, formatting, str, names, $, [[ must not expose key or crosswalk
    p_txt <- paste(utils::capture.output(print(enclave)), collapse = "\n")
    s_txt <- paste(utils::capture.output(utils::str(enclave)), collapse = "\n")
    expect_false(grepl("ultra-secret-broker-passphrase-2026", p_txt, fixed = TRUE))
    expect_false(grepl("ultra-secret-broker-passphrase-2026", s_txt, fixed = TRUE))
    expect_false(grepl(orig_pid, p_txt, fixed = TRUE))
    expect_false(grepl(orig_pid, s_txt, fixed = TRUE))
    expect_null(enclave$secret_env)
    expect_null(enclave[["crosswalk"]])

    # 2. Direct crosswalk/key read attempts by non-broker roles must be denied
    expect_error(broker_lookup_crosswalk(enclave, prin, res$pseudonym_id), "denied|broker|unapproved")
  }
})
