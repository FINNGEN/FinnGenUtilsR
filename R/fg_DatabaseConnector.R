#' Get Database Connector
#'
#' Establishes and returns a database connector object for accessing FinnGen database resources.
#'
#' @param environment A character string specifying the database environment. 
#'   Can be "build" for development/build environment, "preview" for preview environment,
#'   or a sandbox identifier in the format "sandbox-N" where N is the sandbox number.
#'
#' @return A database connector object configured with appropriate connection parameters.
#'
#' @details
#' This function initializes a database connection using DatabaseConnector package utilities.
#' The connector can be used to query and interact with FinnGen database tables.
#'
#' @export
#' @importFrom bigrquery bq_auth
#' @importFrom DatabaseConnector createDbiConnectionDetails connect
fg_getDatabseConnector <- function(
  environment
) {

  if (environment == "build") {
    if (
      is.null(Sys.getenv("GCP_SERVICE_KEY")) ||
        Sys.getenv("GCP_SERVICE_KEY") == ""
    ) {
      stop("GCP_SERVICE_KEY environment variable is not set.")
    }
    bigrquery::bq_auth(path = Sys.getenv("GCP_SERVICE_KEY"))
    billing_project_id <- "atlas-development-270609"
    project_id <- "atlas-development-270609"
  } else if (environment == "preview") {
    billing_project_id <- "fg-production-sandbox-46"
    project_id <- "fg-production-sandbox-46"
  } else {
    sandboxNumber <- sub("sandbox-([0-9]+)", "\\1", environment)
    billing_project_id <- paste0("fg-production-sandbox-", sandboxNumber)
    project_id <- "finngen-production-library"
  }

  connectionDetails <- DatabaseConnector::createDbiConnectionDetails(
    dbms = "bigquery",
    drv = bigrquery::bigquery(),
    project = project_id,
    billing = billing_project_id,
    bigint = "integer64"
  )

  options(sqlRenderTempEmulationSchema = paste0(billing_project_id, ".sandbox"))
  message("Using temporary emulation schema: ", options("sqlRenderTempEmulationSchema"))

  tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails)
  }, error = function(e) {
    stop("Failed to connect to the database: ", e$message)
  })

  lastVersion <- 'dev'
  if (! (environment %in% c("build", "preview"))) {
    lastVersion <- cdm_getLatestDataFreezeAndVersion(connection@dbiConnection)
  }
   
  return(list(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = paste0(project_id, ".finngen_omop_", lastVersion),
    vocabularyDatabaseSchema = paste0(project_id, ".finngen_omop_", lastVersion),
    resultsDatabaseSchema = paste0(project_id, ".finngen_omop_results_", lastVersion)
  ))


}
