

#' Create FinnGen BigQuery Connection
#'
#' @param environment Environment identifier (e.g., "build", "preview", or "sandbox-XX")
#'
#' @return A BigQuery connection object
#'
#' @importFrom DBI dbConnect
#' @importFrom bigrquery bigquery bq_auth
#'
#' @export
fg_connection <- function(
  environment
) {
  #
  # Validation
  #
  .assertEnvironment(environment)

  #
  # Function
  #
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

  connection <- DBI::dbConnect(
    bigrquery::bigquery(),
    project = project_id,
    billing = billing_project_id,
    bigint = "integer64"
  )

  return(connection)
}



#' Assert Environment
#'
#' @param environment Environment identifier to validate
#'
#' @return NULL (called for side effects)
#'
#' @importFrom checkmate assertString
#'
#' @keywords internal
.assertEnvironment <- function(
  environment
) {
  environment |>
    checkmate::assertString(
      pattern = "^(sandbox-[0-9]+|build|preview)$"
    )
}
