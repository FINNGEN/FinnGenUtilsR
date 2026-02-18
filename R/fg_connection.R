

#' Create FinnGen BigQuery Connection
#'
#' @param enviroment Environment identifier (e.g., "build", "review", or "sandbox-XX")
#'
#' @return A BigQuery connection object
#'
#' @importFrom DBI dbConnect
#' @importFrom bigrquery bigquery bq_auth
#'
#' @export
fg_connection <- function(
  enviroment
) {
  #
  # Validation
  #
  .assertEnvironment(enviroment)

  #
  # Function
  #
  if (enviroment == "build") {
    if (
      is.null(Sys.getenv("GCP_SERVICE_KEY")) ||
        Sys.getenv("GCP_SERVICE_KEY") == ""
    ) {
      stop("GCP_SERVICE_KEY environment variable is not set.")
    }
    bigrquery::bq_auth(path = Sys.getenv("GCP_SERVICE_KEY"))
    billing_project_id <- "atlas-development-270609"
    project_id <- "atlas-development-270609"
    dataset_id <- "sandbox"
  } else if (enviroment == "review") {
    billing_project_id <- "fg-production-sandbox-46"
    project_id <- "finngen-production-library"
    dataset_id <- "sandbox"
  } else {
    billing_project_id <- paste0("fg-production-", sandboxNumber)
    project_id <- "finngen-production-library"
    dataset_id <- "sandbox"
  }

  connection <- DBI::dbConnect(
    bigrquery::bigquery(),
    project = project_id,
    dataset = dataset_id,
    billing = billing_project_id,
    bigint = "integer64"
  )

  return(connection)
}



#' Assert Environment
#'
#' @param enviroment Environment identifier to validate
#'
#' @return NULL (called for side effects)
#'
#' @importFrom checkmate assertString
#'
#' @keywords internal
.assertEnvironment <- function(
  enviroment
) {
  enviroment |>
    checkmate::assertString(
      pattern = "^(sandbox-[0-9]+|build|review)$"
    )
}
