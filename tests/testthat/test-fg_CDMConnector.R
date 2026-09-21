test_that("CDMConnector installed version satisfies the minimum required version", {
  skip_if_not_installed("CDMConnector")

  expect_true(utils::packageVersion("CDMConnector") >= "2.8.0")
})

test_that("fg_CDMConnector returns a cdm reference", {
  skip_on_cran()
  skip_if_not_installed("CDMConnector")

  cdm <- fg_CDMConnector(environment = test_environment)

  expect_s3_class(cdm, "cdm_reference")
})
