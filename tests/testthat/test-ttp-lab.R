testthat::test_that("live dicomtk-lab ttp Vault endpoint responds when DICOMTK_RUN_TTP_LAB=1", {
  testthat::skip_if_not(identical(Sys.getenv("DICOMTK_RUN_TTP_LAB"), "1"), "TTP lab tests disabled")
  vault_url <- Sys.getenv("DICOMTK_VAULT_URL", unset = "http://127.0.0.1:8200")
  resp <- httr2::request(paste0(vault_url, "/v1/sys/health")) |>
    httr2::req_error(is_error = function(r) FALSE) |>
    httr2::req_perform()
  testthat::expect_true(httr2::resp_status(resp) %in% c(200L, 429L, 472L, 473L))
})
