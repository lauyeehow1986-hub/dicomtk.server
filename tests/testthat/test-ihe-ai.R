testthat::test_that("IHE AIW-I workitem enforces valid UPS-RS state transitions", {
  wi <- ihe_aiw_workitem("wi-001", study_uid = "1.2.3.4", model_name = "TotalSegmentator")
  testthat::expect_s3_class(wi, "dicom_ihe_workitem")
  testthat::expect_equal(wi$state, "SCHEDULED")

  # Cannot jump directly from SCHEDULED to COMPLETED
  testthat::expect_error(ihe_aiw_transition(wi, to_state = "COMPLETED"), "transition")

  wi2 <- ihe_aiw_transition(wi, to_state = "IN PROGRESS", performer = "worker-gpu-01")
  testthat::expect_equal(wi2$state, "IN PROGRESS")

  wi3 <- ihe_aiw_transition(wi2, to_state = "COMPLETED", output_refs = list(seg_sop_uid = "1.2.3.99"))
  testthat::expect_equal(wi3$state, "COMPLETED")
  testthat::expect_equal(wi3$output_refs$seg_sop_uid, "1.2.3.99")
})

testthat::test_that("IHE AIR bundle validates DICOM AI artifact, FHIR report, and Provenance", {
  air <- ihe_air_bundle(
    study_uid = "1.2.3.4",
    model_name = "TotalSegmentator",
    model_version = "2.4.0",
    dicom_artifact_type = "SEG",
    dicom_sop_uid = "1.2.3.99",
    fhir_report = list(status = "preliminary", conclusion = "Automated lung segmentation"),
    uncertainty_summary = list(mean_entropy = 0.08)
  )
  testthat::expect_s3_class(air, "dicom_ihe_air_bundle")
  testthat::expect_equal(air$dicom_artifact_type, "SEG")
  testthat::expect_equal(air$provenance$resourceType, "Provenance")
  testthat::expect_equal(air$diagnostic_report$resourceType, "DiagnosticReport")
})
