testthat::test_that("SMART on FHIR v2 PKCE, discovery, CSRF state check, and enclave pull work end-to-end", {
  cfg <- smart_discover_config(
    "https://fhir.example.org/r4",
    mock_config = list(
      authorization_endpoint = "https://auth.example.org/authorize",
      token_endpoint = "https://auth.example.org/token",
      code_challenge_methods_supported = c("S256")
    )
  )
  testthat::expect_equal(cfg$authorization_endpoint, "https://auth.example.org/authorize")

  pkce1 <- smart_pkce_challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
  pkce2 <- smart_pkce_challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
  testthat::expect_equal(pkce1$code_challenge, pkce2$code_challenge)
  if (requireNamespace("openssl", quietly = TRUE)) {
    testthat::expect_equal(pkce1$code_challenge, "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
  }
  testthat::expect_error(smart_pkce_challenge(paste(rep("a b!", 15), collapse = "")), "RFC 7636")
  testthat::expect_equal(pkce1$code_challenge_method, "S256")
  testthat::expect_true(nchar(pkce1$code_verifier) >= 43L)

  auth <- smart_build_auth_url(
    cfg,
    client_id = "dicomtk-app",
    redirect_uri = "https://app.example.org/callback",
    launch = "ehr-launch-123",
    pkce = pkce1
  )
  testthat::expect_true(grepl("code_challenge_method=S256", auth$url, fixed = TRUE))
  testthat::expect_true(grepl("launch=ehr-launch-123", auth$url, fixed = TRUE))

  # CSRF state mismatch must fail
  testthat::expect_error(
    smart_exchange_token(
      cfg,
      code = "auth-code-1",
      redirect_uri = "https://app.example.org/callback",
      client_id = "dicomtk-app",
      code_verifier = pkce1$code_verifier,
      expected_state = auth$state,
      received_state = "tampered-state",
      mock_response = list(access_token = "tok", patient = "PAT-888")
    ),
    "state"
  )

  sess <- smart_exchange_token(
    cfg,
    code = "auth-code-1",
    redirect_uri = "https://app.example.org/callback",
    client_id = "dicomtk-app",
    code_verifier = pkce1$code_verifier,
    expected_state = auth$state,
    received_state = auth$state,
    mock_response = list(
      access_token = "tok-xyz",
      patient = "PAT-888",
      encounter = "ENC-101",
      fhirUser = "Practitioner/dr-tan",
      scope = "launch openid fhirUser patient/ImagingStudy.rs"
    )
  )
  testthat::expect_s3_class(sess, "dicom_smart_session")
  testthat::expect_equal(sess$patient_id, "PAT-888")

  tmp_dir <- tempfile("smart_enc_")
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  enc <- broker_enclave_init(tmp_dir, passphrase = "smart-secret-passphrase")

  pi_p <- server_principal("pi-1", roles = "pi", project_ids = "proj-smart")
  coord_p <- server_principal("coord-1", roles = "coordinator", project_ids = "proj-smart")

  bundle <- list(
    resourceType = "Bundle",
    entry = list(
      list(resource = list(resourceType = "Patient", id = "PAT-888", name = list(list(text = "Alice Tan")))),
      list(resource = list(resourceType = "ImagingStudy", id = "img-1", identifier = list(list(value = "urn:oid:1.2.3.4")))),
      list(resource = list(resourceType = "DiagnosticReport", id = "dr-1", status = "final"))
    )
  )

  testthat::expect_error(
    smart_pull_patient_context(sess, enc, pi_p, project_id = "proj-smart", fhir_bundle = bundle),
    "[Pp]ermission"
  )

  ctx_out <- smart_pull_patient_context(sess, enc, coord_p, project_id = "proj-smart", fhir_bundle = bundle)
  testthat::expect_true(grepl("^SUBJ-", ctx_out$pseudonym_id))
  testthat::expect_equal(ctx_out$n_imaging_studies, 1L)
  testthat::expect_equal(ctx_out$n_diagnostic_reports, 1L)
  testthat::expect_false(any(grepl("PAT-888|Alice Tan", unlist(ctx_out))))
})
