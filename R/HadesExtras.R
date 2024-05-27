# copied from https://github.com/FINNGEN/HadesExtras to reduce dependencies


#' createConnectionHandler
#'
#' Creates a connection handler object based on the provided connection details settings.
#'
#' @param connectionDetailsSettings A list of connection details settings to pass directly to DatabaseConnector::createConnectionDetails.
#' @param tempEmulationSchema The temporary emulation schema (optional).
#' @param usePooledConnection Logical indicating whether to use a pooled connection (default is FALSE).
#' @param useBigrqueryUpload Logical indicating whether to use fast table upload for bigquery (default is FALSE)
#' @param ... Additional arguments to be passed to the connection handler object.
#'
#' @importFrom checkmate assertList assertCharacter assertLogical
#' @importFrom Eunomia getEunomiaConnectionDetails
#' @importFrom rlang exec
#' @importFrom DatabaseConnector createConnectionDetails
#' @importFrom ResultModelManager PooledConnectionHandler
#'
#' @return A connection handler object.
#'
#' @export
ResultModelManager_createConnectionHandler  <- function(
    connectionDetailsSettings,
    tempEmulationSchema = NULL,
    useBigrqueryUpload = NULL,
    usePooledConnection = FALSE,
    ...
){

  #
  # Check parameters
  #
  checkmate::assertList(connectionDetailsSettings)
  checkmate::assertCharacter(tempEmulationSchema, null.ok = TRUE)
  checkmate::assertLogical(usePooledConnection, null.ok = TRUE)

  #
  # function
  #

  if(connectionDetailsSettings$dbms == "eunomia"){
    connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  }else{
    connectionDetails <- rlang::exec(DatabaseConnector::createConnectionDetails, !!!connectionDetailsSettings)
  }

  # set tempEmulationSchema if in config
  if(!is.null(tempEmulationSchema)){
    options(sqlRenderTempEmulationSchema = tempEmulationSchema)
  }else{
    options(sqlRenderTempEmulationSchema = NULL)
  }

  # set useBigrqueryUpload if in config
  if(!is.null(useBigrqueryUpload)){
    options(useBigrqueryUpload = useBigrqueryUpload)

    # bq authentication
    if(useBigrqueryUpload==TRUE){
      checkmate::assertTRUE(connectionDetails$dbms=="bigquery")

      options(gargle_oauth_cache=FALSE) #to avoid the question that freezes the app
      connectionString <- connectionDetails$connectionString()
      if( connectionString |> stringr::str_detect(";OAuthType=0;")){
        OAuthPvtKeyPath <- connectionString |>
          stringr::str_extract("OAuthPvtKeyPath=([:graph:][^;]+);") |>
          stringr::str_remove("OAuthPvtKeyPath=") |> stringr::str_remove(";")

        checkmate::assertFileExists(OAuthPvtKeyPath)
        bigrquery::bq_auth(path = OAuthPvtKeyPath)

      }else{
        bigrquery::bq_auth(scopes = "https://www.googleapis.com/auth/bigquery")
      }

      connectionDetails$connectionString
    }

  }else{
    options(useBigrqueryUpload = NULL)
  }


  if (usePooledConnection) {
    stop("not implemented")
    connectionHandler <- ResultModelManager::PooledConnectionHandler$new(connectionDetails, loadConnection = FALSE, ...)
  } else {
    connectionHandler <- tmp_ConnectionHandler$new(connectionDetails, loadConnection = FALSE, ...)
  }

  return(connectionHandler)

}

#' tmp fix for DatabaseConnector::inDatabaseSchema
#'
#' till this is fixed https://github.com/OHDSI/DatabaseConnector/issues/236
#'
#' @param databaseSchema The name of the database schema.
#' @param table The name of the table.
#'
#' @importFrom dbplyr in_schema
#'
#' @return The fully qualified table name with the database schema.
#'
#' @export
tmp_inDatabaseSchema <- function (databaseSchema, table)
{
  return(dbplyr::in_schema(databaseSchema, table))
}


#' tmp fix for ConnectionHandler
#'
#' till this is fixed https://github.com/OHDSI/DatabaseConnector/issues/236
#'
#' @importFrom R6 R6Class
#' @importFrom ResultModelManager ConnectionHandler
#' @importFrom checkmate assertString
#' @importFrom dbplyr in_schema
#' @importFrom dplyr tbl
#'
#' @export

tmp_ConnectionHandler <- R6::R6Class(
  "tmp_ConnectionHandler",
  inherit = ResultModelManager::ConnectionHandler,
  public = list(
    #'
    #' @description get a dplyr table object (i.e. lazy loaded)
    #' @param table                     table name
    #' @param databaseSchema            databaseSchema to which table belongs
    tbl = function(table, databaseSchema = NULL) {
      checkmate::assertString(table)
      checkmate::assertString(databaseSchema, null.ok = TRUE)
      if (!is.null(databaseSchema)) {
        table <- dbplyr::in_schema(databaseSchema, table)
      }
      dplyr::tbl(self$getConnection(), table)
    }
  )

)

#' tmp fix for dplyr::copy_to
#'
#' dplyr::copy_to is very slow to upload tables to BQ.
#' This is function calls dplyr::copy_to except if option "useBigrqueryUpload" option is set to TRUE
#' In that case it uses package bigrquery to upload the table
#'
#' @param dest The destination database connection or table name.
#' @param df The data frame to be copied.
#' @param name The name of the destination table (default is the name of the data frame).
#' @param overwrite Logical value indicating whether to overwrite an existing table (default is FALSE).
#' @param ... pass parameters to dplyr::copy_to
#'
#' @importFrom dplyr filter copy_to
#' @importFrom dbplyr remote_name
#' @importFrom stringr str_replace str_to_lower
#' @importFrom checkmate assertString
#' @importFrom bigrquery bq_table bq_table_upload
#'
#' @return The new table created or the updated table.
#'
#' @export
tmp_dplyr_copy_to <- function(dest, df, name = deparse(substitute(df)), overwrite = FALSE, ...) {

  if(!is.null(getOption("useBigrqueryUpload")) && getOption("useBigrqueryUpload")){

    # create empty table
    empty_df <- df |> dplyr::filter(FALSE)
    newTable <- dplyr::copy_to(dest, empty_df, name, overwrite, ...)

    # get table name as created by SqlRender
    bq_table_name <- newTable |> dbplyr::remote_name() |>
      stringr::str_replace("#", SqlRender::getTempTablePrefix()) |>
      stringr::str_to_lower()

    # get project and dataset from sqlRenderTempEmulationSchema
    tempEmulationSchema = getOption("sqlRenderTempEmulationSchema")
    checkmate::assertString(tempEmulationSchema)

    strings <- strsplit(tempEmulationSchema, "\\.")
    bq_project <- strings[[1]][1]
    bq_dataset <- strings[[1]][2]

    # upload
    bq_table <- bigrquery::bq_table(bq_project, bq_dataset, bq_table_name)
    bigrquery::bq_table_upload(bq_table, df)

    # tmp_table <- bigrquery::bq_table(bq_project, bq_dataset, "")
    # if(bigrquery::bq_table_exists(tmp_table)){bigrquery::bq_table_delete(tmp_table)}
    #
    #
    # bigrquery::bq_table_create(tmp_table, tibble_cohors)
    # bigrquery::bq_table_upload(tmp_table, tibble_cohors)

  }else{

    newTable <- dplyr::copy_to(dest, df, name, overwrite, ...)

  }

  return(newTable)

}
