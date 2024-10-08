
#
# fg_dbplyr_append_provider_info_to_service_sector_data
#
test_that("fg_dbplyr_append_provider_info_to_service_sector_data works", {

  FGconnectionHandler <- create_fg_connection_handler_FromList(test_handler_config)
  on.exit({
    rm(FGconnectionHandler)
    gc()
  })

  tbl <- FGconnectionHandler$getTblsandboxToolsSchema$finngen_r11_service_sector_detailed_longitudinal_v1()  |>
    dplyr::filter(finngenid == 'FG00000001') |>
    fg_dbplyr_append_visit_type_info_to_service_sector_data(FGconnectionHandler$getTblmedicalCodesSchema$fg_codes_info_v7())


  table <- tbl |> dplyr::collect()

  table |> checkmate::expect_tibble()
  c("fg_code5", "fg_code6", "fg_code8", "fg_code9",
    "visit_type_concept_class_id", "visit_type_name_en", "visit_type_name_fi",
    "visit_type_code", "visit_type_omop_concept_id",
    "is_clinic_visit", "is_follow_up_visit"  ) |>
    checkmate::expect_subset(table |> colnames())


})


#
# fg_bq_append_visit_type_info_to_service_sector_data
#
test_that("fg_bq_append_visit_type_info_to_service_sector_data works", {

  sql <- paste0("
    SELECT * FROM (
      SELECT *,
        ROW_NUMBER() OVER (PARTITION BY `SOURCE`, `CODE5`, `CODE6`, `CODE8`, `CODE9`) AS q04
      FROM ", test_longitudinal_data_table, "
    ) WHERE q04 = 1")

  tb_servicesector_combinations <- bigrquery::bq_project_query(project_id, sql)

  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(project_id, tb_servicesector_combinations, fg_codes_info_table)
  res <- bigrquery::bq_table_download(tb_with_translations, n_max = 100)

  res |> checkmate::expect_tibble()
  c("FG_CODE5", "FG_CODE6", "FG_CODE8","FG_CODE9",
    "visit_type_concept_class_id", "visit_type_name_en", "visit_type_name_fi",
    "visit_type_code", "visit_type_omop_concept_id",
    "is_clinic_visit", "is_follow_up_visit"
  ) |>
    checkmate::expect_subset(res |> colnames())
})

#
# fg_append_visit_type_info_to_service_sector_data
#
test_that("fg_bq_append_visit_type_info_to_service_sector_data maps PRIM_OUT CODE5 CODE6", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:5),
    SOURCE = "PRIM_OUT",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = as.character(NA), CODE2 = as.character(NA), CODE3 = as.character(NA), CODE4 = as.character(NA),
    #
    CODE5 = c(NA, NA, "R20", "R20", "R20"),
    CODE6 = c(NA, "T40", NA, "T40", "T40"),
    CODE7 = c(NA, NA, NA, NA, "T40"),
    CODE8 = c(NA, NA, NA, NA, "R10"),
    CODE9 = c(NA, NA, NA, NA, "E"),
    #
    ICDVER = "10",
    CATEGORY = "0",
    INDEX = "0"
  )

  on.exit({bigrquery::bq_table_delete(bq_test_table)})
  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))

  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    # dplyr::select(SOURCE, FG_CODE5, FG_CODE6, FG_CODE8, FG_CODE9, visit_type_concept_class_id, visit_type_code  ) |>
    dplyr::select(SOURCE, visit_type_concept_class_id, visit_type_code, is_clinic_visit, is_follow_up_visit) |>
    expect_equal(
      tibble::tibble(
        SOURCE = "PRIM_OUT",
        visit_type_concept_class_id = "SRC|Contact|Service",
        visit_type_code = c("PRIM_OUT|0|0", "PRIM_OUT|0|T40", "PRIM_OUT|R20|0", "PRIM_OUT|R20|T40", "PRIM_OUT|R20|T40"),
        is_clinic_visit = c(FALSE, TRUE, NA, FALSE, FALSE),
        is_follow_up_visit = c(FALSE, FALSE, FALSE, FALSE, FALSE)
      )
    )

})


test_that("fg_bq_append_visit_type_info_to_service_sector_data maps hilmo CODE5", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:8),
    SOURCE = c("INPAT", "OUTPAT", "OPER_IN", "OPER_OUT", "INPAT", "OUTPAT", "OPER_IN", "OPER_OUT"),
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = as.character(NA), CODE2 = as.character(NA), CODE3 = as.character(NA), CODE4 = as.character(NA),
    #
    CODE5 = c(NA, NA, NA, NA, "1", "1", "93", "93"),
    CODE6 = as.character(NA),
    CODE7 = as.character(NA),
    CODE8 = as.character(NA),
    CODE9 = as.character(NA),
    #
    ICDVER = "10",
    CATEGORY = "0",
    INDEX = "0"
  )

  on.exit({bigrquery::bq_table_delete(bq_test_table)})
  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    # dplyr::select(SOURCE, FG_CODE5, FG_CODE6, FG_CODE8, FG_CODE9, visit_type_concept_class_id, visit_type_code  ) |>
    dplyr::select(SOURCE, visit_type_concept_class_id, visit_type_code, is_clinic_visit, is_follow_up_visit) |>
    expect_equal(
      tibble::tibble(
        SOURCE = c("INPAT", "OUTPAT", "OPER_IN", "OPER_OUT", "INPAT", "OUTPAT", "OPER_IN", "OPER_OUT"),
        visit_type_concept_class_id = "SRC|ServiceSector",
        visit_type_code = c("INPAT|0", "OUTPAT|0", "OPER_IN|0", "OPER_OUT|0", "INPAT|1", "OUTPAT|1", "OPER_IN|93", "OPER_OUT|93"),
        is_clinic_visit = c(TRUE, TRUE, TRUE, TRUE, TRUE, NA, NA, TRUE),
        is_follow_up_visit = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE)
      )
    )

})



test_that("fg_bq_append_visit_type_info_to_service_sector_data maps hilmo CODE98", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:5),
    SOURCE = "INPAT",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = as.character(NA), CODE2 = as.character(NA), CODE3 = as.character(NA), CODE4 = as.character(NA),
    #
    CODE5 = as.character(NA),
    CODE6 = c(NA, NA, NA, NA, "1"),
    CODE7 = as.character(NA),
    CODE8 = c(NA, NA, "R80", "R80", "R80"),
    CODE9 = c(NA, "3", NA, "3", "3"),
    #
    ICDVER = "10",
    CATEGORY = "0",
    INDEX = "0"
  )

  on.exit({bigrquery::bq_table_delete(bq_test_table)})
  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    #dplyr::select(SOURCE, FG_CODE5, FG_CODE6, FG_CODE8, FG_CODE9, visit_type_concept_class_id, visit_type_code) |>
    dplyr::select(SOURCE, visit_type_concept_class_id, visit_type_code, is_clinic_visit, is_follow_up_visit) |>
    expect_equal(
      tibble::tibble(
        SOURCE = "INPAT",
        visit_type_concept_class_id = c("SRC|ServiceSector", "SRC|Contact|Urgency", "SRC|Contact|Urgency", "SRC|Contact|Urgency", "SRC|Contact|Urgency"),
        visit_type_code = c("INPAT|0", "INPAT|0|3", "INPAT|R80|0", "INPAT|R80|3", "INPAT|R80|3"),
        is_clinic_visit = c(TRUE, NA, TRUE, TRUE, TRUE),
        is_follow_up_visit = c(FALSE, FALSE, FALSE, FALSE, FALSE)
      )
    )

})




test_that("fg_bq_append_visit_type_info_to_service_sector_data overlap hilmo code5 CODE98", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:8),
    SOURCE = "INPAT",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = as.character(NA), CODE2 = as.character(NA), CODE3 = as.character(NA), CODE4 = as.character(NA),
    #
    CODE5 = c(NA, NA, NA, NA, "1", "1", "1", "1"),
    CODE6 = as.character(NA),
    CODE7 = as.character(NA),
    CODE8 = c(NA, NA, "R80", "R80", NA, NA, "R80", "R80"),
    CODE9 = c(NA, "3", NA, "3", NA, "3", NA, "3"),
    #
    ICDVER = "10",
    CATEGORY = "0",
    INDEX = "0"
  )

  on.exit({bigrquery::bq_table_delete(bq_test_table)})
  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(SOURCE, FG_CODE5, FG_CODE6, FG_CODE8, FG_CODE9, visit_type_concept_class_id, visit_type_code) |>
    dplyr::select(SOURCE, visit_type_concept_class_id, visit_type_code) |>
    expect_equal(
      tibble::tibble(
        SOURCE = "INPAT",
        visit_type_concept_class_id = rep(c("SRC|ServiceSector", "SRC|Contact|Urgency", "SRC|Contact|Urgency", "SRC|Contact|Urgency"), 2),
        visit_type_code = c("INPAT|0", "INPAT|0|3", "INPAT|R80|0", "INPAT|R80|3", "INPAT|1", "INPAT|0|3", "INPAT|R80|0", "INPAT|R80|3")
      )
    )

  # prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = FA:SE
  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table,
    prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = FALSE
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(SOURCE, FG_CODE5, FG_CODE6, FG_CODE8, FG_CODE9, visit_type_concept_class_id, visit_type_code) |>
    dplyr::select(SOURCE, visit_type_concept_class_id, visit_type_code) |>
    expect_equal(
      tibble::tibble(
        SOURCE = "INPAT",
        visit_type_concept_class_id = c("SRC|ServiceSector", "SRC|Contact|Urgency", "SRC|Contact|Urgency", "SRC|Contact|Urgency", "SRC|ServiceSector", "SRC|ServiceSector", "SRC|ServiceSector", "SRC|ServiceSector"),
        visit_type_code = c("INPAT|0", "INPAT|0|3", "INPAT|R80|0", "INPAT|R80|3", "INPAT|1", "INPAT|1", "INPAT|1", "INPAT|1")
      )
    )

})




test_that("fg_bq_append_visit_type_info_to_service_sector_data maps SOURCE", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:4),
    SOURCE = c("PURCH", "REIMB", "CANC", "DEATH"),
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = as.character(NA), CODE2 = as.character(NA), CODE3 = as.character(NA), CODE4 = as.character(NA),
    #
    CODE5 = c(NA, "R20", "R20", "R20"),
    CODE6 = c("T40", NA, "T40", "T40"),
    CODE7 = c(NA, NA, NA, "T40"),
    CODE8 = c(NA, NA, NA, "R10"),
    CODE9 = c(NA, NA, NA, "E"),
    #
    ICDVER = "10",
    CATEGORY = "0",
    INDEX = "0"
  )

  on.exit({bigrquery::bq_table_delete(bq_test_table)})
  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    # dplyr::select(SOURCE, FG_CODE5, FG_CODE6, FG_CODE8, FG_CODE9, visit_type_concept_class_id, visit_type_code  ) |>
    dplyr::select(SOURCE, visit_type_concept_class_id, visit_type_code, is_clinic_visit, is_follow_up_visit) |>
    expect_equal(
      tibble::tibble(
        SOURCE = c("PURCH", "REIMB", "CANC", "DEATH"),
        visit_type_concept_class_id = "SRC",
        visit_type_code = c("PURCH", "REIMB", "CANC", "DEATH"),
        is_clinic_visit = c(NA, NA, NA, NA),
        is_follow_up_visit = c(NA, NA, NA, NA)
      )
    )

})



#
# isClinicVisit and isFollowUpVisit
#

test_that("fg_bq_append_visit_type_info_to_service_sector_data throws error when using a fg_code_info with version less than 7", {
  sql <- paste0("
    SELECT * FROM (
      SELECT *,
        ROW_NUMBER() OVER (PARTITION BY `SOURCE`, `CODE5`, `CODE6`, `CODE8`, `CODE9`) AS q04
      FROM ", test_longitudinal_data_table, "
    ) WHERE q04 = 1")

  tb_servicesector_combinations <- bigrquery::bq_project_query(project_id, sql)



  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, tb_servicesector_combinations,
    "atlas-development-270609.medical_codes.fg_codes_info_v6"
  ) |>
    expect_error("fg_codes_info_table must be version 7 or above.")

})

test_that("fg_bq_append_visit_type_info_to_service_sector_data works with no extra columns selected", {

  sql <- paste0("
    SELECT * FROM (
      SELECT *,
        ROW_NUMBER() OVER (PARTITION BY `SOURCE`, `CODE5`, `CODE6`, `CODE8`, `CODE9`) AS q04
      FROM ", test_longitudinal_data_table, "
    ) WHERE q04 = 1")

  tb_servicesector_combinations <- bigrquery::bq_project_query(project_id, sql)

  tb_with_translations <- fg_bq_append_visit_type_info_to_service_sector_data(
    project_id, tb_servicesector_combinations,
    "atlas-development-270609.medical_codes.fg_codes_info_v6",
    add_is_clinic_visist = FALSE,
    add_is_follow_up_visit = FALSE
  )
  res <- bigrquery::bq_table_download(tb_with_translations, n_max = 100)

  res |> checkmate::expect_tibble()

  # res has not the columsn
  c("is_clinic_visit", "is_follow_up_visit") %in% colnames(res) |> expect_equal(c(FALSE, FALSE))
})
