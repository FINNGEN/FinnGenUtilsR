
#' fg_append_code_info_to_longitudinal_data
#'
#' @param longitudinal_data_table full path to the table in longitudinal_data format
#' @param fg_codes_info_table full path to the table with the codes info
#'
#' @param ICD10fi_map_to In INPAT, OUTPAT, PRIM_OUT, DEATH registers the ICD10fi combination codes are
#' split into CODE1, CODE2 and CODE3. This parameter selects to what code or combination of codes to map to.
#'  Options:
#' - "CODE1_CODE2" : appends info for the combined CODE1 and CODE2. e.g N0839*E112   [default].
#' - "CODE1" : appends info only for CODE1. e.g N0839
#' - "CODE2" : appends info only for CODE2. e.g E112
#' - "ATC" : appends info only for ATC code in CODE3 column.  e.g N02BE01
#' @param PURCH_map_to In PURCH register rows contain the VNR code in CODE2 column and the ATC group in CODE1.
#'  This parameter selects to what of these two codes to append the info.
#'  - "ATC" : appends info for the ATC code in CODE1 column. e.g. N02BE01   [default].
#'  - "REIMB" :  appends info for the REIMB code in CODE2 column. e.g. 205
#'  - "VNR" :  appends info for the VNR code in CODE3 column. e.g. 003121
#' @param CANC_map_to In CANC register the ICDO3  codes are split into CODE1, CODE2 and CODE3.
#' This parameter selects to what code or combination of codes to map to.
#' - "MORPO_BEH_TOPO" : appends info for the combined CODE1, CODE2 and CODE3. e.g. 8140/3-C61.9  [default].
#' - "TOPO" : appends info for the TOPO code in CODE1 column. e.g. C61.9
#' - "MORPO_BEH" : appends info for the MORPHO code in CODE2 column. e.g. 8140/3
#' @param REIMB_map_to in REIMB register rows contain the REIMB code and, after 1995, also the ICD code that leaded to reimbursement. This selects to what of these two codes to map.
#' - "REIMB" : appends info for the REIMB code in CODE1 column  [default].
#' - "ICD" : appends info for the ICD in CODE1 column
#' @param ICD10fi_precision Number or leading codes in ICD10fi to map to. e.g. N0839 with ICD10fi_precision=3 is N08  [default = 5]
#' @param ICD9fi_precision Number or leading codes in ICD9fi to map to. e.g. 8450B with ICD9fi_precision=3 is 845 [default = 5]
#' @param ICD8fi_precision Number or leading codes in ICD8fi to map to. e.g. 36809 with ICD8fi_precision=3 is 368 [default = 5]
#' @param ATC_precision Number or leading codes in ATC to map to. e.g. N02BE01 with ATC_precision=3 is N02 [default = 7]
#' @param NCSPfi_precision Number or leading codes in NOMESCO to map to. e.g. AB1CB  with NCSPfi_precision=2 is AB [default = 5]
#'
#' @param new_colums_sufix string indicating a prefix to add to the appended columns, default="".
#'
#' @return sql script ready to be ran
#' @export
#'
#' @examples
fg_append_code_info_to_longitudinal_data_sql <- function(
  longitudinal_data_table,
  fg_codes_info_table,
  #
  ICD10fi_map_to = "CODE1_CODE2",
  PURCH_map_to = "ATC",
  CANC_map_to = "MORPO_BEH_TOPO",
  REIMB_map_to = "REIMB",
  #
  ICD10fi_precision = 5,
  ICD9fi_precision = 5,
  ICD8fi_precision = 5,
  ATC_precision = 7,
  NCSPfi_precision  = 5,
  #
  new_colums_sufix = ""
  ){


  # VALIDATE PARAMETERS
  longitudinal_data_table |> checkmate::assert_character()
  fg_codes_info_table |> checkmate::assert_character()

  ICD10fi_map_to |> checkmate::assert_character(len = 1)
  ICD10fi_map_to |> checkmate::assert_subset(c("CODE1_CODE2", "CODE1", "CODE2", "ATC"), empty.ok = FALSE)
  PURCH_map_to |> checkmate::assert_character(len = 1)
  PURCH_map_to |> checkmate::assert_subset(c("ATC", "VNR", "REIMB"), empty.ok = FALSE)
  CANC_map_to |> checkmate::assert_character(len = 1)
  CANC_map_to |> checkmate::assert_subset(c("MORPO_BEH_TOPO", "TOPO", "MORPHO_BEH"), empty.ok = FALSE)
  REIMB_map_to |> checkmate::assert_character(len = 1)
  REIMB_map_to |> checkmate::assert_subset(c("REIMB", "ICD"), empty.ok = FALSE)

  ICD10fi_precision |> checkmate::assert_number(lower = 1, upper = 5)
  ICD9fi_precision |> checkmate::assert_number(lower = 1, upper = 5)
  ICD8fi_precision |> checkmate::assert_number(lower = 1, upper = 5)
  ATC_precision |> checkmate::assert_number(lower = 1, upper = 7)
  NCSPfi_precision |> checkmate::assert_number(lower = 1, upper = 5)

  new_colums_sufix |> checkmate::assert_character(len = 1)


  sql <- system.file("sql/append_info_to_longitudinal_data.sql", package = "FinnGenUtilsR") |>
    SqlRender::readSql() |>
    SqlRender::render(
      longitudinal_data_table = longitudinal_data_table,
      fg_codes_info_table = fg_codes_info_table,
      #
      ICD10fi_map_to = ICD10fi_map_to,
      PURCH_map_to = PURCH_map_to,
      CANC_map_to = CANC_map_to,
      REIMB_map_to = REIMB_map_to,
      #
      ICD10fi_precision = ICD10fi_precision,
      ICD9fi_precision = ICD9fi_precision,
      ICD8fi_precision = ICD8fi_precision,
      ATC_precision = ATC_precision,
      NCSPfi_precision  = NCSPfi_precision,
      new_colums_sufix = new_colums_sufix
    )


  return(sql)


}







#' fg_bq_append_code_info_to_longitudinal_data
#'
#' Wrap around fg_append_code_info_to_longitudinal_data_sql to work with bigrquery package
#'
#' @param bq_project_id string with the bigquery project id
#' @param bq_table an object of type <bq_table> with a table in longitudinal_data format
#' @param fg_codes_info_table string with the full path (project.schema.table) to the bq table with the fg_codes_info
#' @param ... see \link{fg_append_code_info_to_longitudinal_data_sql} for the mapping options
#'
#' @return
#' @export
#'
#' @examples
fg_bq_append_code_info_to_longitudinal_data <- function(
  bq_project_id,
  bq_table,
  fg_codes_info_table,
  ...
){

  # validate
  bq_project_id |> checkmate::assert_subset(bigrquery::bq_projects())
  bq_table |> checkmate::assert_class("bq_table")


  sql <- fg_append_code_info_to_longitudinal_data_sql(
    longitudinal_data_table = paste0(bq_table, collapse = "."),
    fg_codes_info_table = fg_codes_info_table,
    ...
  )

  new_tb <- bigrquery::bq_project_query(bq_project_id, sql)

  return(new_tb)

}










