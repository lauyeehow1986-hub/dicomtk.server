testthat::test_that("active learning pool prioritizes uncertain samples and records labeled submissions", {
  pool <- active_learning_pool_init(strategy = "uncertainty")
  c1 <- active_learning_add_candidate(pool, project_id = "proj-1", study_uid = "1.2.3.1", uncertainty_score = 0.25)
  c2 <- active_learning_add_candidate(pool, project_id = "proj-1", study_uid = "1.2.3.2", uncertainty_score = 0.92)
  c3 <- active_learning_add_candidate(pool, project_id = "proj-1", study_uid = "1.2.3.3", uncertainty_score = 0.61)

  nxt <- active_learning_next(pool, project_id = "proj-1", n = 2L)
  testthat::expect_equal(nrow(nxt), 2L)
  testthat::expect_equal(nxt$candidate_id[1L], c2$candidate_id)
  testthat::expect_equal(nxt$candidate_id[2L], c3$candidate_id)

  ann_p <- server_principal("ann-1", roles = "annotator", project_ids = "proj-1")
  aud_p <- server_principal("aud-1", roles = "auditor", project_ids = "proj-1")
  testthat::expect_error(
    active_learning_submit(pool, aud_p, c2$candidate_id, label_path = "/tmp/mask.nii.gz"),
    "[Pp]ermission"
  )

  sub <- active_learning_submit(pool, ann_p, c2$candidate_id, label_path = "/tmp/mask.nii.gz", quality_score = 0.95)
  testthat::expect_equal(sub$status, "labeled")

  nxt2 <- active_learning_next(pool, project_id = "proj-1", n = 2L)
  testthat::expect_equal(nxt2$candidate_id[1L], c3$candidate_id)
})

testthat::test_that("event-driven routing_rule and routing_execute dispatch matching rules", {
  coord_p <- server_principal("coord-1", roles = "coordinator", project_ids = "proj-1")
  pi_p <- server_principal("pi-1", roles = "pi", project_ids = "proj-1")

  r1 <- routing_rule(
    rule_id = "ct_qa",
    when_modality = "CT",
    when_event = "study_ingested",
    action = "enqueue_qa",
    target = "ct_qa_queue"
  )
  r2 <- routing_rule(
    rule_id = "mr_only",
    when_modality = "MR",
    when_event = "study_ingested",
    action = "notify",
    target = "mr_team"
  )

  ev <- list(event_type = "study_ingested", project_id = "proj-1", modality = "CT", study_uid = "1.2.3.4")
  testthat::expect_error(routing_execute(list(r1, r2), pi_p, ev), "[Pp]ermission")

  res <- routing_execute(list(r1, r2), coord_p, ev)
  testthat::expect_equal(nrow(res), 1L)
  testthat::expect_equal(res$rule_id[1L], "ct_qa")
  testthat::expect_equal(res$status[1L], "dispatched")
})
