testthat::test_that("server_create_context and server_handle_request enforce JWT auth and RBAC", {
  tmp_dir <- tempfile("srv_ctx_")
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  ctx <- server_create_context(work_dir = tmp_dir, jwt_secret = "unit-test-secret")
  testthat::expect_s3_class(ctx, "dicom_server_context")

  h <- server_handle_request(ctx, method = "GET", path = "/health")
  testthat::expect_equal(h$status, 200L)
  testthat::expect_equal(h$body$status, "ok")

  unauth <- server_handle_request(ctx, method = "GET", path = "/projects")
  testthat::expect_equal(unauth$status, 401L)

  pi_tok <- mint_test_jwt("pi-1", roles = "pi", project_ids = "proj-1", secret = "unit-test-secret")
  adm_tok <- mint_test_jwt("adm-1", roles = "admin", project_ids = "*", secret = "unit-test-secret")

  forb <- server_handle_request(
    ctx,
    method = "POST",
    path = "/projects",
    headers = list(Authorization = paste("Bearer", pi_tok)),
    body = list(project_id = "proj-new", title = "Forbidden")
  )
  testthat::expect_equal(forb$status, 403L)

  created <- server_handle_request(
    ctx,
    method = "POST",
    path = "/projects",
    headers = list(Authorization = paste("Bearer", adm_tok)),
    body = list(project_id = "proj-new", title = "Created Project")
  )
  testthat::expect_equal(created$status, 201L)

  listed <- server_handle_request(
    ctx,
    method = "GET",
    path = "/projects",
    headers = list(Authorization = paste("Bearer", adm_tok))
  )
  testthat::expect_equal(listed$status, 200L)

  sbom_res <- server_handle_request(
    ctx,
    method = "GET",
    path = "/sbom",
    headers = list(Authorization = paste("Bearer", adm_tok))
  )
  testthat::expect_equal(sbom_res$status, 200L)
  testthat::expect_equal(sbom_res$body$bomFormat, "CycloneDX")
})

testthat::test_that("server_viewer_html, plumber API, and shiny UI/server construct cleanly", {
  tmp_dir <- tempfile("srv_ui_")
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  ctx <- server_create_context(work_dir = tmp_dir, jwt_secret = "unit-test-secret")

  html_cs <- server_viewer_html(study_uid = "1.2.3.4", viewer = "cornerstone3d")
  testthat::expect_true(grepl("cornerstone", html_cs, ignore.case = TRUE))
  testthat::expect_true(grepl("1.2.3.4", html_cs, fixed = TRUE))

  html_nv <- server_viewer_html(study_uid = "1.2.3.4", viewer = "niivue")
  testthat::expect_true(grepl("niivue", html_nv, ignore.case = TRUE))

  if (requireNamespace("plumber", quietly = TRUE)) {
    pr <- server_plumber_api(ctx)
    testthat::expect_true(inherits(pr, "Plumber"))
  }

  if (requireNamespace("shiny", quietly = TRUE)) {
    ui <- server_shiny_ui(ctx)
    srv <- server_shiny_server(ctx)
    testthat::expect_true(inherits(ui, c("shiny.tag", "shiny.tag.list")))
    testthat::expect_true(is.function(srv))
  }
})
