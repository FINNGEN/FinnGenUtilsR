#' Connect to FinnGen OMOP CDM
#'
#' @param environment Environment identifier (e.g., "build", "review", or "sandbox-XX")
#' @param dataFreeze_version Data freeze version (e.g., "r13_v3", "dev"). If NULL, latest version is used.
#' @param ... Additional arguments passed to CDMConnector::cdmFromCon
#'
#' @return A CDM reference object
#'
#' @importFrom CDMConnector cdmFromCon
#'
#' @export
fg_CDMConnector <- function(
  environment = NULL,
  dataFreeze_version = NULL,
  ...
){

  # Making a connection object that is used to connect to the tables:
  connection <- fg_connection(environment)

  if (is.null(dataFreeze_version)) {
    if (environment == "review") {
      dataFreeze_version <- 'dev'
    } else if (environment == "build") {
      dataFreeze_version <- 'dev'
    } else {
      dataFreeze_version <- cdm_getLatestDataFreezeAndVersion(connection)
    }
  }


  project_id <- connection@project
  billing_project_id <- connection@billing
  dataset_id <- connection@dataset


  cdmSchema <- paste0(billing_project_id, ".finngen_omop_",dataFreeze_version)
  writeSchema <- paste0(project_id, ".", dataset_id)


  cdm <- CDMConnector::cdmFromCon(
    con = connection,  # Changed from 'connection =' to 'con ='
    cdmSchema = cdmSchema,
    writeSchema = writeSchema,
    ...
  )

  return(cdm)
}


#' Get Latest Data Freeze and Version
#'
#' @param connection BigQuery connection object
#'
#' @return Character string with the latest data freeze and version (e.g., "r13_v3")
#'
#' @importFrom bigrquery bq_project_datasets
#' @importFrom purrr map_chr
#' @importFrom stringr str_extract str_starts
#'
#' @export
cdm_getLatestDataFreezeAndVersion <- function(
  connection
) {
  datasets <- bigrquery::bq_project_datasets(connection@project) |>
    purrr::map_chr(~ .x$dataset)

  validDataFreezeVersions <- datasets |>
    stringr::str_extract("(?<=finngen_omop_)[^\")]*") |>
    (\(x) ifelse(stringr::str_starts(x, "result"), NA, x))() |>
    na.omit() |>
    as.vector()

  lastFreeze <- validDataFreezeVersions |>
    stringr::str_extract("r[0-9]+") |>
    .lastNumberSuffix(prefix = "r")

  lastVersion <- validDataFreezeVersions |>
    stringr::str_extract("v[0-9]+") |>
    .lastNumberSuffix(prefix = "v")

   lastFreezeAndVersion <- paste0(lastFreeze, "_", lastVersion)

}

#' Assert Data Freeze Version
#'
#' @param connection BigQuery connection object
#' @param dataFreeze_version Data freeze version to validate
#'
#' @return NULL (called for side effects)
#'
#' @importFrom checkmate assertString
#' @importFrom stringr str_extract
#'
#' @keywords internal
.assertDataFreezeVersion <- function(
  connection,
  dataFreeze_version
) {
  dataFreeze_version |>  checkmate::assertString(pattern =  "^r[0-9]+_v[0-9]+$|^dev$")

  validDataFreezeVersions <- datasets |>
    stringr::str_extract("(?<=finngen_omop_)[^\")]*") |>
    na.omit() |>
    as.vector()

  dataFreezeNotValid <- setdiff(dataFreeze, validDataFreezeVersions)
  if (length(dataFreezeNotValid) > 0) {
    stop(
      "Invalid dataFreeze_version: ",
      paste(dataFreezeNotValid, collapse = ", "),
      ". Valid data freezes are: ",
      paste(validDataFreezeVersions, collapse = ", "),
      "."
    )
  }
}