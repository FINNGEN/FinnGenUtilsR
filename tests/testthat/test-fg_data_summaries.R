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


test_that("fg_omop_summaries creates a file", {
  skip_on_cran()
  
  # Create fg_bq_tables object with CDM tables
  fg <- get_fg_bq_tables(
    environment = test_environment, 
    dataFreeze = "dev",
    includeCDMTables = TRUE
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
