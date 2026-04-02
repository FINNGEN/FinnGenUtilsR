test_that("fg_tables works with default tablesGroup", {

  connection <- fg_connection(environment = test_environment) 

  connection |> checkmate::assert_class("DBIConnection")

})

test_that("tablesGroup parameter accepts valid values", {

  # Test 'register' (default)
  fg_register <- get_fg_bq_tables(test_environment, tablesGroup = "register")
  expect_s3_class(fg_register, "fg_bq_tables")

  # Test 'cdm'
  fg_cdm <- get_fg_bq_tables(test_environment, tablesGroup = "cdm")
  expect_s3_class(fg_cdm, "fg_bq_tables")

  # Test 'register_and_cdm'
  fg_all <- get_fg_bq_tables(test_environment, tablesGroup = "register_and_cdm")
  expect_s3_class(fg_all, "fg_bq_tables")

})

