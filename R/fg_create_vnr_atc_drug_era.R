#' fg_create_vnr_atc_drug_era_sql
#'
#' @param omop_schema string with the schema where the omop tables are stored
#' @param fg_codes_info_table full path to the table with the codes info
#'
#' @param gap_days integer indicating gap between drug exposures of a drug for a patient, default=30.
#'
#' @return sql script ready to be ran
#'
#' @importFrom checkmate assert_character assert_subset assert_number
#' @importFrom SqlRender readSql render
#'
#' @export
#'
fg_create_vnr_atc_drug_era_sql <- function(
    omop_schema,
    fg_codes_info_table,
    #
    gap_days = 30) {
  # VALIDATE PARAMETERS
  omop_schema |> checkmate::assert_character()
  fg_codes_info_table |> checkmate::assert_character()

  gap_days |> checkmate::assert_int()


  sql <- system.file("sql/create_vnr_atc_drug_era.sql", package = "FinnGenUtilsR") |>
    SqlRender::readSql() |>
    SqlRender::render(
      omop_schema = omop_schema,
      fg_codes_info_table = fg_codes_info_table,
      #
      gap_days = gap_days
    )

  return(sql)
}




#' fg_create_vnr_atc_drug_era
#'
#' Wrap around fg_create_vnr_atc_drug_era_sql to work with bigrquery package
#'
#' @param bq_project_id string with the bigquery project id
#' @param omop_schema string with the schema where the omop tables are stored
#' @param fg_codes_info_table string with the full path (project.schema.table) to the bq table with the fg_codes_info
#' @param ... see `fg_create_vnr_atc_drug_era_sql` for the mapping options
#'
#' @return bq_table with added columns
#'
#' @importFrom checkmate assert_subset assert_class
#' @importFrom bigrquery bq_projects bq_project_query
#'
#' @export
#'
fg_create_vnr_atc_drug_era <- function(
    bq_project_id,
    omop_schema,
    fg_codes_info_table,
    ...) {
  # validate
  bq_project_id |> checkmate::assert_subset(bigrquery::bq_projects())

  sql <- fg_create_vnr_atc_drug_era_sql(
    omop_schema = omop_schema,
    fg_codes_info_table = fg_codes_info_table,
    ...
  )

  new_tb <- bigrquery::bq_project_query(bq_project_id, sql, ...)

  return(new_tb)
}
