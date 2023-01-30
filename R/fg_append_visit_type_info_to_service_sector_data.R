#' fg_append_visit_type_info_to_service_sector_data_sql
#'
#' @param service_sector_data_table full path to the table in longitudinal_data format
#' @param fg_codes_info_table full path to the table with the codes info
#'
#' @param prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector
#' Some hilmo visits are including both coding systems, SRC|ServiceSector and SRC|Contact|Urgency, if TRUE the second is used
#'
#' @param new_colums_sufix string indicating a prefix to add to the appended columns, default="".
#'
#' @return sql script ready to be ran
#' @export
#'
#' @importFrom checkmate assert_character assert_subset assert_number
#' @importFrom SqlRender readSql render
fg_append_visit_type_info_to_service_sector_data_sql <- function(
    service_sector_data_table,
    fg_codes_info_table,
    #
    prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = TRUE,
    #
    new_colums_sufix = "") {
  # VALIDATE PARAMETERS
  service_sector_data_table |> checkmate::assert_character()
  fg_codes_info_table |> checkmate::assert_character()

  new_colums_sufix |> checkmate::assert_character(len = 1)


  sql <- system.file("sql/append_visit_type_info_to_service_sector_data.sql", package = "FinnGenUtilsR") |>
    SqlRender::readSql() |>
    SqlRender::render(
      service_sector_data_table = service_sector_data_table,
      fg_codes_info_table = fg_codes_info_table,
      #
      prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector,
      #
      new_colums_sufix = new_colums_sufix
    )


  return(sql)
}




#' fg_bq_append_code_info_to_longitudinal_data
#'
#' Wrap around fg_append_visit_type_info_to_service_sector_data_sql to work with bigrquery package
#'
#' @param bq_project_id string with the bigquery project id
#' @param bq_table an object of type <bq_table> with a table in longitudinal_data format
#' @param fg_codes_info_table string with the full path (project.schema.table) to the bq table with the fg_codes_info
#' @param ... see `fg_append_visit_type_info_to_service_sector_data_sql` for the mapping options
#'
#' @return bq_table with added columns
#' @export
#' @importFrom checkmate assert_subset assert_class
#' @importFrom bigrquery bq_projects bq_project_query
fg_bq_append_visit_type_info_to_service_sector_data <- function(
    bq_project_id,
    bq_table,
    fg_codes_info_table,
    ...) {
  # validate
  bq_project_id |> checkmate::assert_subset(bigrquery::bq_projects())
  bq_table |> checkmate::assert_class("bq_table")


  sql <- fg_append_visit_type_info_to_service_sector_data_sql(
    service_sector_data_table = paste0(bq_table, collapse = "."),
    fg_codes_info_table = fg_codes_info_table,
    ...
  )

  new_tb <- bigrquery::bq_project_query(bq_project_id, sql)

  return(new_tb)
}
