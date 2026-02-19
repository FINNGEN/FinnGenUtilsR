#' fg_append_provider_info_to_service_sector_data_sql
#'
#' @param service_sector_data_table full path to the table in service_sector_data format
#' @param fg_codes_info_table full path to the table with the codes info
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
fg_append_provider_info_to_service_sector_data_sql <- function(
    service_sector_data_table,
    fg_codes_info_table,
    #
    new_colums_sufix = "") {
  # VALIDATE PARAMETERS
  service_sector_data_table |> checkmate::assert_character()
  fg_codes_info_table |> checkmate::assert_character()

  new_colums_sufix |> checkmate::assert_character(len = 1)


  sql <- system.file("sql/append_provider_info_to_service_sector_data.sql", package = "FinnGenUtilsR") |>
    SqlRender::readSql() |>
    SqlRender::render(
      service_sector_data_table = service_sector_data_table,
      fg_codes_info_table = fg_codes_info_table,
      #
      new_colums_sufix = new_colums_sufix
    )


  return(sql)
}




#' fg_bq_append_provider_info_to_service_sector_data
#'
#' Wrap around fg_append_provider_info_to_service_sector_data_sql to work with bigrquery package
#'
#' @param bq_project_id string with the bigquery project id
#' @param bq_table an object of type <bq_table> with a table in longitudinal_data format
#' @param fg_codes_info_table string with the full path (project.schema.table) to the bq table with the fg_codes_info
#' @param ... see `fg_append_provider_info_to_service_sector_data_sql` for the mapping options
#'
#' @return bq_table with added columns
#'
#' @importFrom checkmate assert_subset assert_class
#' @importFrom bigrquery bq_projects bq_project_query
#'
#' @export
#'
fg_bq_append_provider_info_to_service_sector_data <- function(
    bq_project_id,
    bq_table,
    fg_codes_info_table,
    ...) {
  # validate
  bq_project_id |> checkmate::assert_subset(bigrquery::bq_projects())
  bq_table |> checkmate::assert_class("bq_table")

  sql <- fg_append_provider_info_to_service_sector_data_sql(
    service_sector_data_table = paste0(bq_table$project, ".", bq_table$dataset, ".", bq_table$table),
    fg_codes_info_table = fg_codes_info_table,
    ...
  )

  new_tb <- bigrquery::bq_project_query(bq_project_id, sql, ...)

  return(new_tb)
}


#' fg_dbplyr_append_provider_info_to_service_sector_data
#'
#' Wrap around fg_append_provider_info_to_service_sector_data_sql to work with dbplyr package
#'
#' @param dbplyr_table an object of type <tbl> representing a table in longitudinal_data format
#' @param dbplyr_fg_codes_info_table string with the full path (schema.table) to the database table with the fg_codes_info
#' @param ... see [fg_append_code_info_to_longitudinal_data_sql](fg_append_code_info_to_longitudinal_data_sql) for the mapping options
#'
#' @return <tbl> with added columns
#'
#' @importFrom checkmate assert_class
#' @importFrom dbplyr sql_render build_sql
#' @importFrom dplyr tbl compute
#' @importFrom bigrquery as_bq_table
#'
#' @export
#'

fg_dbplyr_append_provider_info_to_service_sector_data <- function(
    dbplyr_table,
    fg_bq_tables,
    ...) {
  # validate
  dbplyr_table |> checkmate::assert_class("tbl")
  fg_bq_tables |> checkmate::assert_class("fg_bq_tables")

  bq_fg_codes_info_table <- fg_bq_tables$tbl$fg_codes_info

  connection <- dbplyr_table$src$con

  dbplyr_table_computed <- dplyr::compute(dbplyr_table)
  dbplyr_table_path <- dbplyr_table_computed$lazy_query$x |> as.character()
  bq_table <- bigrquery::as_bq_table(dbplyr_table_path)

  bq_fg_codes_info_table <- dbplyr_fg_codes_info_table$lazy_query$x |> as.character()

  bq_result <- fg_bq_append_provider_info_to_service_sector_data(
    bq_project_id = connection@project,
    bq_table = bq_table,
    fg_codes_info_table = bq_fg_codes_info_table,
    ...
  )

  new_dbplyr_table <- dplyr::tbl(
    connection,
    I(paste0(bq_result$project, ".", bq_result$dataset, ".", bq_result$table))
  )

  return(new_dbplyr_table)
}
