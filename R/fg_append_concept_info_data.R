#' fg_append_concept_info_data_sql
#'
#' @param data_table string with the full path (project.schema.table) to the bq table with the data
#' @param omop_schema string with the schema where the omop tables are stored
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
fg_append_concept_info_data_sql <- function(
    data_table,
    omop_schema,
    #
    new_colums_sufix = "") {
  # VALIDATE PARAMETERS
  data_table |> checkmate::assert_character(len = 1)
  omop_schema |> checkmate::assert_character(len = 1)

  new_colums_sufix |> checkmate::assert_character(len = 1)


  sql <- system.file("sql/append_concept_info_to_data.sql", package = "FinnGenUtilsR") |>
    SqlRender::readSql() |>
    SqlRender::render(
      data_table = data_table,
      omop_schema = omop_schema,
      #
      new_colums_sufix = new_colums_sufix
    )

  return(sql)
}




#' fg_bq_append_concept_info_data
#'
#' Wrap around fg_bq_append_concept_info_data_sql to work with bigrquery package
#'
#' @param bq_project_id string with the bigquery project id
#' @param bq_table an object of type <bq_table> with a table in longitudinal_data format
#' @param omop_schema string with the schema where the omop tables are stored
#'
#' @return bq_table with added columns
#'
#' @importFrom checkmate assert_subset assert_class
#' @importFrom bigrquery bq_projects bq_project_query
#'
#' @export
#'
fg_bq_append_concept_info_data <- function(
    bq_project_id,
    bq_table,
    omop_schema,
    ...) {
  # validate
  bq_project_id |> checkmate::assert_subset(bigrquery::bq_projects())
  bq_table |> checkmate::assert_class("bq_table")


  sql <- fg_append_concept_info_data_sql(
    data_table = paste0(bq_table$project, ".", bq_table$dataset, ".", bq_table$table),
    omop_schema = omop_schema,
    ...
  )

  new_tb <- bigrquery::bq_project_query(bq_project_id, sql, ...)

  return(new_tb)
}


#' fg_dbplyr_append_concept_info_data
#'
#' @param dbplyr_table a tbl object with the data
#' @param omop_schema string with the schema where the omop tables are stored
#'
#' @return tbl with added columns
#'
#' @importFrom checkmate assert_subset assert_class
#' @importFrom dplyr collect
#'
#' @export
#'
fg_dbplyr_append_concept_info_data <- function(
    dbplyr_table,
    omop_schema,
    ...) {
  # validate
  dbplyr_table |> checkmate::assert_class("tbl")
  c('omop_concept_id') |> checkmate::assert_subset(dbplyr_table |> colnames())

  connection = dbplyr_table$src$con

  sql <- fg_append_concept_info_data_sql(
    data_table = paste0( "( ", as.character(dbplyr::sql_render(dbplyr_table)), ")"),
    omop_schema = omop_schema,
    ...
  )

  new_dbplyr_table  <-  dplyr::tbl(connection, dbplyr::sql(sql))

  return(new_dbplyr_table)
}
