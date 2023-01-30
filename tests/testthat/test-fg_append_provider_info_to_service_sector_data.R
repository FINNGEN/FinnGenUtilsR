#
# SETUP
#

bigrquery::bq_auth(path = Sys.getenv("GCP_SERVICE_KEY"))
project_id <- "atlas-development-270609"

test_longitudinal_data_table <- "atlas-development-270609.sandbox_tools_r10.finngen_r10_service_sector_detailed_longitudinal_v2"
fg_codes_info_table <- "atlas-development-270609.medical_codes.fg_codes_info_v2"
tmp_schema <- "sandbox"

# redundant long executions
## tb_vocabulary_combinations: table with all combinations of SOURCE, ICDVER, CATEGORY
### from dplyr::distinct(SOURCE, ICDVER, CATEGORY, .keep_all = T)
sql <- paste0("
    SELECT * FROM (
      SELECT *,
        ROW_NUMBER() OVER (PARTITION BY `SOURCE`, `CODE6`, `CODE7`) AS q04
      FROM ", test_longitudinal_data_table, "
    ) WHERE q04 = 1")

tb_servicesector_combinations <- bigrquery::bq_project_query(project_id, sql)


#
# TEST
#
test_that("fg_bq_append_provider_info_to_service_sector_data_sql works", {
  skip_if(!bigrquery::bq_table_exists(tb_servicesector_combinations))

  tb_with_translations <- fg_bq_append_provider_info_to_service_sector_data(project_id, tb_servicesector_combinations, fg_codes_info_table)
  res <- bigrquery::bq_table_download(tb_with_translations, n_max = 100)
  res |> checkmate::expect_tibble()
})




test_that("fg_bq_append_provider_info_to_service_sector_data_sql maps hilmo CODE6 and code7", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:11),
    SOURCE = c("INPAT", "OUTPAT", "OPER_IN", "OPER_OUT", "INPAT", "OUTPAT", "OPER_IN", "OPER_OUT", "PRIM_OUT", "PRIM_OUT", "PRIM_OUT"),
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = as.character(NA), CODE2 = as.character(NA), CODE3 = as.character(NA), CODE4 = as.character(NA),
    #
    CODE5 = as.character(NA),
    CODE6 = c(NA, NA, NA, NA, "77", "77", "77", "77", "77", NA, NA),
    CODE7 = c(NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "32311"),
    CODE8 = as.character(NA),
    CODE9 = as.character(NA),
    #
    ICDVER = "10",
    CATEGORY = "0",
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, "tmp_test_finngenutilsr")
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_provider_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(stringr::str_sub(FINNGENID, -3) |> as.integer()) |>
    dplyr::select(SOURCE, FG_CODE6, FG_CODE7, provider_concept_class_id, provider_code) |>
    dplyr::select(SOURCE, provider_concept_class_id, provider_code) |>
    expect_equal(
      tibble::tibble(
        SOURCE = c("INPAT", "OUTPAT", "OPER_IN", "OPER_OUT", "INPAT", "OUTPAT", "OPER_IN", "OPER_OUT", "PRIM_OUT", "PRIM_OUT", "PRIM_OUT"),
        provider_concept_class_id = c(rep(as.character(NA), 4), rep("MEDSPECfi Level 0", 4), NA, NA, "ProfessionalCode"),
        provider_code = c(NA, NA, NA, NA, "77", "77", "77", "77", NA, NA, "32311")
      )
    )


  # clean
  bigrquery::bq_table_delete(bq_test_table)
})
