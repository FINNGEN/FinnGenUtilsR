


#
# fg_dbplyr_append_code_info_to_longitudinal_data
#
test_that("fg_dbplyr_append_code_info_to_longitudinal_data works", {

  on.exit({
    rm(FGconnectionHandler)
    gc()
  })

  FGconnectionHandler <- create_fg_connection_handler_FromList(test_handler_config)

  tbl <- FGconnectionHandler$getTblsandboxToolsSchema$finngen_r11_service_sector_detailed_longitudinal_v1()  |>
    dplyr::filter(finngenid == 'FG00000001') |>
    fg_dbplyr_append_code_info_to_longitudinal_data(FGconnectionHandler$getTblmedicalCodesSchema$fg_codes_info_v6())

  table <- tbl |> dplyr::collect()

  table |> checkmate::expect_tibble()
  c('finngenid', 'approx_event_day', 'code1', 'code2', 'code3', 'code4', 'icdver', 'category', 'index', 'code', 'name_en', 'name_fi', 'omop_concept_id') |>
    checkmate::expect_subset(names(table))

})


#
# fg_bq_append_code_info_to_longitudinal_data
#
test_that("fg_bq_append_code_info_to_longitudinal_data works", {
  sql <- paste("SELECT * FROM ", test_longitudinal_data_table, " WHERE FINNGENID='FG00000001'")
  tb <- bigrquery::bq_project_query(project_id, sql)
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(project_id, tb, fg_codes_info_table)
  res <- bigrquery::bq_table_download(tb_with_translations)
  res |> checkmate::expect_tibble()
})


test_that("fg_bq_append_code_info_to_longitudinal_data works on real codes", {

  # To make it faster we create a table with the longitudinal data for the unic combinations of SOURCE, ICDVER, CATEGORY
  ## tb_vocabulary_combinations: table with all combinations of SOURCE, ICDVER, CATEGORY
  ### from dplyr::distinct(SOURCE, ICDVER, CATEGORY, .keep_all = T)
  sql <- paste0("
    SELECT * FROM (
      SELECT *,
        ROW_NUMBER() OVER (PARTITION BY `SOURCE`, `ICDVER`, `CATEGORY`) AS q04
      FROM ", test_longitudinal_data_table, "
    ) WHERE q04 = 1")

  tb_test_medical_codes_in_longitudinal_data <- bigrquery::bq_project_query(project_id, sql)

  # fg_append_code_info_to_longitudinal_data finds the correct vocabulary: default

  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, tb_test_medical_codes_in_longitudinal_data, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  # at the moment the HPN and HPO not implemented
  res |>
    dplyr::filter(is.na(vocabulary_id)) |>
    checkmate::expect_tibble(nrows = 0)

  # fg_append_code_info_to_longitudinal_data finds the correct vocabulary: PURCH = VNR"

  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, tb_test_medical_codes_in_longitudinal_data, fg_codes_info_table,
    PURCH_map_to = "VNR"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  # at the moment the HPN and HPO not implemented
  res |>
    dplyr::filter(is.na(vocabulary_id)) |>
    checkmate::expect_tibble(nrows = 0)


  # fg_append_code_info_to_longitudinal_data finds the correct vocabulary: REIMB = ICD"

  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, tb_test_medical_codes_in_longitudinal_data, fg_codes_info_table,
    REIMB_map_to = "ICD"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  # at the moment the HPN and HPO not implemented
  res |>
    dplyr::filter(is.na(vocabulary_id)) |>
    checkmate::expect_tibble(nrows = 0)
})


#
# fg_append_code_info_to_longitudinal_data_sql
#
test_that("fg_append_code_info_to_longitudinal_data maps ICD10fi all options", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:5),
    SOURCE = c("INPAT", "OUTPAT", "PRIM_OUT", "DEATH", "REIMB"),
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = c("N0839", "N0839", "N0839", "N0839", as.character(NA)),
    CODE2 = c("E112", "E112", "E112", as.character(NA), "N0839"),
    CODE3 = c("N02BE01", as.character(NA), as.character(NA), as.character(NA), as.character(NA)),
    CODE4 = as.character(NA),
    ICDVER = "10",
    CATEGORY = c("0", "0", "ICD0", "U", "ICD"),
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    REIMB_map_to = "ICD"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("N0839", "N0839", "N0839", "N0839", "N0839"),
        FG_CODE2 = c("E112", "E112", "E112", as.character(NA), as.character(NA)),
        FG_CODE3 = as.character(NA),
      )
    )

  #  ICD10fi_map_to = "CODE1"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    ICD10fi_map_to = "CODE1",
    REIMB_map_to = "ICD"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("N0839", "N0839", "N0839", "N0839", "N0839"),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
      )
    )

  #  ICD10fi_map_to = "CODE2"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    ICD10fi_map_to = "CODE2",
    REIMB_map_to = "ICD"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("E112", "E112", "E112", "N0839", "N0839"),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
      )
    )

  #  ICD10fi_map_to = "ATC"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    ICD10fi_map_to = "ATC",
    REIMB_map_to = "ICD"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("N02BE01", as.character(NA), as.character(NA), "N0839", "N0839"),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
      )
    )

  # clean
  bigrquery::bq_table_delete(bq_test_table)
})



test_that("fg_append_code_info_to_longitudinal_data maps PURCH all options", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:3),
    SOURCE = "PURCH",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = c("N02BE01", "N02BE01", "N02BE01"),
    CODE2 = c("205", "205", as.character(NA)),
    CODE3 = c("003121", "3121", as.character(NA)),
    CODE4 = as.character(NA),
    ICDVER = as.character(NA),
    CATEGORY = as.character(NA),
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("N02BE01", "N02BE01", "N02BE01"),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
      )
    )

  #  PURCH_map_to = "VNR"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    PURCH_map_to = "VNR"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("003121", "003121", as.character(NA)),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
      )
    )

  #  PURCH_map_to = "REIMB"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    PURCH_map_to = "REIMB"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("205", "205", as.character(NA)),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
      )
    )

  # clean
  bigrquery::bq_table_delete(bq_test_table)
})



test_that("fg_append_code_info_to_longitudinal_data maps ICDO3 all options", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1),
    SOURCE = "CANC",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = "C619",
    CODE2 = "8140",
    CODE3 = "3",
    CODE4 = as.character(NA),
    ICDVER = "O3",
    CATEGORY = as.character(NA),
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3, code) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = "C619",
        FG_CODE2 = "8140",
        FG_CODE3 = "3",
        code = "8140/3-C61.9"
      )
    )

  # CANC_map_to = "TOPO"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    CANC_map_to = "TOPO"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3, code) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = "C619",
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
        code = "C61.9"
      )
    )


  # CANC_map_to = "MORPHO"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    CANC_map_to = "MORPHO_BEH"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3, code) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = as.character(NA),
        FG_CODE2 = "8140",
        FG_CODE3 = "3",
        code = "8140/3"
      )
    )

  # clean
  bigrquery::bq_table_delete(bq_test_table)
})



test_that("fg_append_code_info_to_longitudinal_data maps REIMB all options", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:3),
    SOURCE = "REIMB",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = c("205", "205", "205"),
    CODE2 = c("I50", "4019X", as.character(NA)),
    CODE3 = as.character(NA),
    CODE4 = as.character(NA),
    ICDVER = c("10", "9", as.character(NA)),
    CATEGORY = as.character(NA),
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3, code) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("205", "205", "205"),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
        code = c("205", "205", "205")
      )
    )

  # REIMB_map_to = "ICD"
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    REIMB_map_to = "ICD"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3, code) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("I50", "4019X", as.character(NA)),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
        code = c("I50", "4019X", as.character(NA))
      )
    )

  # clean
  bigrquery::bq_table_delete(bq_test_table)
})



test_that("fg_append_code_info_to_longitudinal_data precision ", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:5),
    SOURCE = c("INPAT", "INPAT", "INPAT", "PURCH", "OPER_IN"),
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = c("N0839", "8450B", "36809", "N02BE01", "AB1CB"),
    CODE2 = as.character(NA),
    CODE3 = as.character(NA),
    CODE4 = as.character(NA),
    ICDVER = c("10", "9", "8", as.character(NA), as.character(NA)),
    CATEGORY = c("1", "1", "1", as.character(NA), "NOM1"),
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    ICD10fi_precision = 3,
    ICD9fi_precision = 3,
    ICD8fi_precision = 3,
    ATC_precision = 3,
    NCSPfi_precision = 2
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  res |>
    dplyr::arrange(FINNGENID) |>
    dplyr::select(FG_CODE1, FG_CODE2, FG_CODE3, code) |>
    expect_equal(
      tibble::tibble(
        FG_CODE1 = c("N08", "845", "368", "N02", "AB"),
        FG_CODE2 = as.character(NA),
        FG_CODE3 = as.character(NA),
        code = c("N08", "845", "368", "N02", "AB")
      )
    )

  # clean
  bigrquery::bq_table_delete(bq_test_table)
})

test_that("fg_append_code_info_to_longitudinal_data new_colums_sufix ", {
  # upload
  test_table <- tibble::tibble(
    FINNGENID = paste0("F0000000", 1:5),
    SOURCE = "INPAT",
    EVENT_AGE = 0.0,
    APPROX_EVENT_DAY = lubridate::ymd("2000-01-01"),
    CODE1 = "N0839",
    CODE2 = as.character(NA),
    CODE3 = as.character(NA),
    CODE4 = as.character(NA),
    ICDVER = "10",
    CATEGORY = "1",
    INDEX = "0"
  )

  bq_test_table <- bigrquery::bq_table(project_id, tmp_schema, test_rename("test_finngenutilsr"))
  if (bigrquery::bq_table_exists(bq_test_table)) {
    bigrquery::bq_table_delete(bq_test_table)
  }
  bigrquery::bq_table_create(bq_test_table, test_table)
  bigrquery::bq_table_upload(bq_test_table, test_table)


  # DEFAULT
  tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
    project_id, bq_test_table, fg_codes_info_table,
    new_colums_sufix = "_SUB"
  )
  res <- bigrquery::bq_table_download(tb_with_translations)

  checkmate::expect_subset(
    c("concept_class_id_SUB", "name_en_SUB", "name_fi_SUB", "code_SUB", "omop_concept_id_SUB"),
    res |> names()
  )

  # clean
  bigrquery::bq_table_delete(bq_test_table)
})




#
# test by hand
#

#
# sql <- paste("SELECT * FROM ", test_longitudinal_data_table, "ORDER BY FINNGENID LIMIT 10000 ")
# tb <- bq_project_query(project_id, sql)
# tb_with_translations <- fg_bq_append_code_info_to_longitudinal_data(
#   project_id, tb, fg_codes_info_table,
#   PURCH_map_to = "VNR"
# )
# sql <- paste("SELECT * FROM ", paste0(tb_with_translations, collapse = "."), "WHERE NAME_EN IS NULL ")
# tb_with_translations_filtered <- bq_project_query(project_id, sql)
#
# failed <- bq_table_download(tb_with_translations_filtered)
#
# failed |>  distinct(vocabulary_id, CODE1, CODE2, CODE3, CODE4, .keep_all = T) |>
#   arrange(vocabulary_id) |>
#   view()
