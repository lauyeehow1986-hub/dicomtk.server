testthat::test_that("job_queue_init and job_submit execute and track jobs", {
  q <- job_queue_init(backend = "sync")
  pi_p <- server_principal("pi-1", roles = "pi", project_ids = "proj-1")
  aud_p <- server_principal("aud-1", roles = "auditor", project_ids = "proj-1")

  testthat::expect_error(
    job_submit(q, aud_p, project_id = "proj-1", fn = function(x) x + 1, args = list(x = 2)),
    "[Pp]ermission"
  )

  job <- job_submit(q, pi_p, project_id = "proj-1", fn = function(x, y) x * y, args = list(x = 6, y = 7), job_type = "qc")
  testthat::expect_true(is.character(job$job_id))
  st <- job_status(q, job$job_id)
  testthat::expect_equal(st$status, "completed")
  res <- job_result(q, job$job_id)
  testthat::expect_equal(res, 42)
})

testthat::test_that("compute_seg_qa computes 3D Dice, HD95, and Surface Dice and qa queue tracks reviews", {
  ref <- array(0L, dim = c(10L, 10L, 10L))
  ref[3:7, 3:7, 3:7] <- 1L

  pred_exact <- ref
  qa_exact <- compute_seg_qa(pred_exact, ref, spacing_mm = c(1, 1, 1), tolerance_mm = 1.0)
  testthat::expect_equal(qa_exact$dice, 1.0)
  testthat::expect_equal(qa_exact$hd95_mm, 0.0)
  testthat::expect_equal(qa_exact$surface_dice, 1.0)

  pred_shift <- array(0L, dim = c(10L, 10L, 10L))
  pred_shift[4:8, 3:7, 3:7] <- 1L
  qa_shift <- compute_seg_qa(pred_shift, ref, spacing_mm = c(2, 2, 2), tolerance_mm = 1.0)
  testthat::expect_true(qa_shift$dice > 0 && qa_shift$dice < 1)
  testthat::expect_true(qa_shift$hd95_mm >= 2.0)
  testthat::expect_true(qa_shift$surface_dice >= 0 && qa_shift$surface_dice <= 1)

  qq <- qa_queue_init()
  item <- qa_enqueue(qq, project_id = "proj-1", study_uid = "1.2.3.4", pred_mask = pred_shift, ref_mask = ref, spacing_mm = c(1, 1, 1))
  testthat::expect_equal(item$status, "pending")
  testthat::expect_equal(nrow(qa_list(qq, status = "pending")), 1L)

  ann_p <- server_principal("ann-1", roles = "annotator", project_ids = "proj-1")
  rev <- qa_submit_review(qq, ann_p, item$item_id, decision = "approve", notes = "Acceptable margin")
  testthat::expect_equal(rev$status, "approved")
  testthat::expect_equal(nrow(qa_list(qq, status = "pending")), 0L)
  testthat::expect_equal(nrow(qa_list(qq, status = "approved")), 1L)
})
