#' fg_append_visit_type_info_to_service_sector_data_sql
#'
#' @param service_sector_data_table full path to the table in longitudinal_data format
#' @param fg_codes_info_table full path to the table with the codes info
#'
#' @param prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector
#' Some hilmo visits are including both coding systems, SRC|ServiceSector and SRC|Contact|Urgency, if TRUE the second is used
#' @param add_is_clinic_visist add a column indicating if the visit is a clinic visit
#' @param add_is_follow_up_visit add a column indicating if the visit is a follow up visit
#'
#' @param new_colums_sufix string indicating a prefix to add to the appended columns, default="".
#'
#' @return sql script ready to be ran
#'
#' @importFrom checkmate assert_character assert_subset assert_number
#' @importFrom SqlRender readSql render
#'
#' @export
#'
fg_append_visit_type_info_to_service_sector_data_sql <- function(
    service_sector_data_table,
    fg_codes_info_table,
    #
    prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = TRUE,
    add_is_clinic_visist = TRUE,
    add_is_follow_up_visit = TRUE,
    #
    new_colums_sufix = "") {
  # VALIDATE PARAMETERS
  service_sector_data_table |> checkmate::assert_character()
  fg_codes_info_table |> checkmate::assert_character()

  # error if fg_codes_info_table is under version v7
  if(add_is_clinic_visist | add_is_follow_up_visit) {
    version_number <- fg_codes_info_table |> stringr::str_extract("v[0-9]+") |> stringr::str_remove("v") |> as.numeric()
    if (version_number < 7) {
      stop("fg_codes_info_table must be version 7 or above.")
    }
  }

  new_colums_sufix |> checkmate::assert_character(len = 1)


  sql <- system.file("sql/append_visit_type_info_to_service_sector_data.sql", package = "FinnGenUtilsR") |>
    SqlRender::readSql() |>
    SqlRender::render(
      service_sector_data_table = service_sector_data_table,
      fg_codes_info_table = fg_codes_info_table,
      #
      prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector,
      add_is_clinic_visist = add_is_clinic_visist,
      add_is_follow_up_visit = add_is_follow_up_visit,
      #
      new_colums_sufix = new_colums_sufix
    )


  return(sql)
}




#' fg_bq_append_visit_type_info_to_service_sector_data
#'
#' Wrap around fg_append_visit_type_info_to_service_sector_data_sql to work with bigrquery package
#'
#' @param bq_project_id string with the bigquery project id
#' @param bq_table an object of type <bq_table> with a table in longitudinal_data format
#' @param fg_codes_info_table string with the full path (project.schema.table) to the bq table with the fg_codes_info
#' @param ... see `fg_append_visit_type_info_to_service_sector_data_sql` for the mapping options
#'
#' @return bq_table with added columns
#'
#' @importFrom checkmate assert_subset assert_class
#' @importFrom bigrquery bq_projects bq_project_query
#'
#' @export
#'
fg_bq_append_visit_type_info_to_service_sector_data <- function(
    bq_project_id,
    bq_table,
    fg_codes_info_table,
    ...) {
  # validate
  bq_project_id |> checkmate::assert_subset(bigrquery::bq_projects())
  bq_table |> checkmate::assert_class("bq_table")


  sql <- fg_append_visit_type_info_to_service_sector_data_sql(
    service_sector_data_table = paste0(bq_table$project, ".", bq_table$dataset, ".", bq_table$table),
    fg_codes_info_table = fg_codes_info_table,
    ...
  )

  new_tb <- bigrquery::bq_project_query(bq_project_id, sql, ...)

  return(new_tb)
}


#' fg_dbplyr_append_visit_type_info_to_service_sector_data
#'
#' Wrap around fg_append_provider_info_to_service_sector_data_sql to work with dbplyr package
#'
#' @param dbplyr_table an object of type <tbl> representing a table in longitudinal_data format
#' @param dbplyr_fg_codes_info_table string with the full path (schema.table) to the database table with the fg_codes_info
#' @param ... see [fg_append_visit_type_info_to_service_sector_data_sql](fg_append_visit_type_info_to_service_sector_data_sql) for the mapping options
#'
#' @return <tbl> with added columns
#'
#' @importFrom checkmate assert_class
#' @importFrom dbplyr sql_render build_sql
#' @importFrom dplyr tbl
#'
#' @export
#'

fg_dbplyr_append_visit_type_info_to_service_sector_data <- function(
    dbplyr_table,
    dbplyr_fg_codes_info_table,
    ...) {
  # validate
  dbplyr_table |> checkmate::assert_class("tbl")
  c('code5', 'code6', 'code8', 'code9') |> checkmate::assert_subset(dbplyr_table |> colnames())

  connection = dbplyr_table$src$con

  sql <- fg_append_visit_type_info_to_service_sector_data_sql(
    service_sector_data_table = paste0( "( ", as.character(dbplyr::sql_render(dbplyr_table)), ")"),
    fg_codes_info_table = paste0( "( ", as.character(dbplyr::sql_render(dbplyr_fg_codes_info_table)), ")"),
    ...
  )

  new_dbplyr_table  <-  dplyr::tbl(connection, dbplyr::sql(sql))

  return(new_dbplyr_table)

}
