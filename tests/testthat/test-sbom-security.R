testthat::test_that("server_generate_sbom emits valid CycloneDX 1.5 JSON with CRAN purls", {
  sbom <- server_generate_sbom(pkg = "dicomtk.server")
  testthat::expect_equal(sbom$bomFormat, "CycloneDX")
  testthat::expect_equal(sbom$specVersion, "1.5")
  testthat::expect_equal(sbom$metadata$component$name, "dicomtk.server")
  testthat::expect_true(length(sbom$components) >= 4L)
  purls <- vapply(sbom$components, `[[`, character(1L), "purl")
  testthat::expect_true(all(grepl("^pkg:cran/", purls)))

  tmp_json <- tempfile(fileext = ".cdx.json")
  on.exit(unlink(tmp_json), add = TRUE)
  server_generate_sbom(pkg = "dicomtk.server", out_path = tmp_json)
  testthat::expect_true(file.exists(tmp_json))
  parsed <- jsonlite::fromJSON(tmp_json, simplifyVector = FALSE)
  testthat::expect_equal(parsed$bomFormat, "CycloneDX")
})

testthat::test_that("server_threat_model covers all 6 STRIDE categories", {
  tm <- server_threat_model()
  testthat::expect_s3_class(tm, "tbl_df")
  expected <- c(
    "Spoofing", "Tampering", "Repudiation",
    "Information Disclosure", "Denial of Service", "Elevation of Privilege"
  )
  testthat::expect_true(all(expected %in% tm$stride_category))
  testthat::expect_true(all(nzchar(tm$mitigation)))
})
