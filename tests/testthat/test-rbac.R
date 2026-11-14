test_that("8-role OIDC RBAC matrix enforces strict capability boundaries and JWT verification", {
  expect_equal(
    sort(server_roles()),
    sort(c("pi", "coordinator", "annotator", "auditor", "admin", "site_admin", "honest_broker", "dpo"))
  )

  p_pi <- server_principal("dr_tan", roles = "pi", project_ids = "nsclc_01")
  p_hb <- server_principal("broker_lee", roles = "honest_broker")
  p_dpo <- server_principal("dpo_wong", roles = "dpo")
  p_site <- server_principal("site_adm", roles = "site_admin")

  expect_true(check_permission(p_pi, "reid_request", project_id = "nsclc_01"))
  expect_false(check_permission(p_pi, "reid_approve_broker", throw = FALSE))
  expect_false(check_permission(p_pi, "reid_approve_dpo", throw = FALSE))
  expect_false(check_permission(p_pi, "federation_approve", throw = FALSE))
  expect_error(check_permission(p_pi, "reid_approve_broker", throw = TRUE), "denied|permission")

  expect_true(check_permission(p_hb, "reid_approve_broker"))
  expect_false(check_permission(p_hb, "reid_approve_dpo", throw = FALSE))
  expect_true(check_permission(p_dpo, "reid_approve_dpo"))
  expect_true(check_permission(p_site, "federation_approve"))

  # JWT minting & verification
  tok <- mint_test_jwt(user_id = "dr_tan", roles = c("pi", "annotator"), secret = "test-hmac-key")
  prin <- verify_bearer_token(tok, secret = "test-hmac-key")
  expect_s3_class(prin, "dicom_server_principal")
  expect_equal(prin$user_id, "dr_tan")
  expect_true(all(c("pi", "annotator") %in% prin$roles))

  # Tampered token must fail
  bad_tok <- paste0(tok, "tamper")
  expect_error(verify_bearer_token(bad_tok, secret = "test-hmac-key"))

  # Expired token must fail
  exp_tok <- mint_test_jwt(user_id = "dr_tan", roles = "pi", secret = "test-hmac-key", expires_in = -10)
  expect_error(verify_bearer_token(exp_tok, secret = "test-hmac-key"), "expired")

  # Empty secret and alg:none header must fail
  expect_error(verify_bearer_token(tok, secret = ""), "non-empty")
  none_hdr <- dicomtk.server:::.b64url_encode('{"alg":"none","typ":"JWT"}')
  parts <- strsplit(tok, ".", fixed = TRUE)[[1L]]
  forged_none <- paste0(none_hdr, ".", parts[2L], ".", dicomtk.server:::srv_hmac_hex("test-hmac-key", paste0(none_hdr, ".", parts[2L])))
  expect_error(verify_bearer_token(forged_none, secret = "test-hmac-key"), "HS256")
})
