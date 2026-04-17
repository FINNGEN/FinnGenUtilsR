test_that("fg_register_data_summaries creates a file", {
  skip_on_cran()

  # Create fg_bq_tables object
  fg <- get_fg_bq_tables(environment = test_environment, dataFreeze = "dev")

  # Create temporary output path
  output_path <- tempfile(fileext = ".md")

  # Run function
  result <- fg_register_data_summaries(
    fg_bq_tables = fg,
    output_path = output_path,
    detailedOutput = FALSE
  )

  # Check that file was created
  expect_true(file.exists(output_path))

  # Check that file has content
  expect_gt(file.size(output_path), 0)

  # Check that it returns the output path
  expect_equal(result, output_path)

  # Clean up
  unlink(output_path)
})


test_that("fg_register_data_summaries filters tables correctly with tables_list", {
  skip_on_cran()

  # Create fg_bq_tables object
  fg <- get_fg_bq_tables(environment = test_environment, dataFreeze = "dev")

  # Get available table names
  available_tables <- names(fg$tbl)

  # Select first 2 tables (or all if less than 2)
  tables_to_test <- head(available_tables, 2)

  # Create temporary output path
  output_path <- tempfile(fileext = ".md")

  # Run function with tables_list
  result <- fg_register_data_summaries(
    fg_bq_tables = fg,
    output_path = output_path,
    detailedOutput = TRUE,
    tables_list = tables_to_test
  )

  # Check that file was created
  expect_true(file.exists(output_path))

  # Read file content
  content <- readLines(output_path)
  content_text <- paste(content, collapse = "\n")

  # Check that specified tables appear in the output
  for (table in tables_to_test) {
    expect_true(
      any(grepl(table, content)),
      info = paste("Table", table, "should appear in output")
    )
  }

  # Check that non-selected tables don't appear (if there are more than 2 tables)
  if (length(available_tables) > 2) {
    non_selected <- setdiff(available_tables, tables_to_test)
    # Check first non-selected table
    expect_false(
      any(grepl(paste0("## ", non_selected[1]), content, fixed = TRUE)),
      info = paste("Non-selected table", non_selected[1], "should not appear")
    )
  }

  # Clean up
  unlink(output_path)
})


test_that("fg_register_data_summaries errors with invalid tables_list", {
  skip_on_cran()

  # Create fg_bq_tables object
  fg <- get_fg_bq_tables(environment = test_environment, dataFreeze = "dev")

  # Create temporary output path
  output_path <- tempfile(fileext = ".md")

  # Test with non-existent table names
  expect_error(
    fg_register_data_summaries(
      fg_bq_tables = fg,
      output_path = output_path,
      tables_list = c("nonexistent_table1", "nonexistent_table2")
    ),
    "not available in fg_bq_tables"
  )

  # Test with empty character vector
  expect_error(
    fg_register_data_summaries(
      fg_bq_tables = fg,
      output_path = output_path,
      tables_list = character(0)
    ),
    "Assertion on 'tables_list' failed"
  )
})


test_that("fg_omop_summaries creates a file", {
  skip_on_cran()

  # Create fg_bq_tables object with CDM tables
  fg <- get_fg_bq_tables(
    environment = test_environment,
    dataFreeze = "dev",
    tablesGroup = "cdm"
  )

  # Create temporary output path
  output_path <- tempfile(fileext = ".md")

  # Run function
  result <- fg_omop_summaries(
    fg_bq_tables = fg,
    output_path = output_path
  )

  # Check that file was created
  expect_true(file.exists(output_path))

  # Check that file has content
  expect_gt(file.size(output_path), 0)

  # Check that it returns the output path
  expect_equal(result, output_path)

  # Read file content
  content <- readLines(output_path)

  # Check for expected sections
  expect_true(any(grepl("OMOP CDM Summaries", content)))
  expect_true(any(grepl("Overall OMOP Statistics", content)))

  # Clean up
  unlink(output_path)
})
