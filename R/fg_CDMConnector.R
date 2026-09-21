#' Connect to FinnGen OMOP CDM
#'
#' @param environment Environment identifier (e.g., "build", "preview", or "sandbox-XX")
#' @param cdmDataFreezeVersion Data freeze version (e.g., "r13_v3", "dev"). If NULL, latest version is used.
#' @param ... Additional arguments passed to CDMConnector::cdmFromCon
#'
#' @return A CDM reference object
#'
#' @export
fg_CDMConnector <- function(
  environment = NULL,
  cdmDataFreezeVersion = NULL,
  ...
){

  if (!requireNamespace("CDMConnector", quietly = TRUE)) {
    stop("Package 'CDMConnector' is required but not installed. Please install it to use this function.")
  }

  if (utils::packageVersion("CDMConnector") < "2.8.0") {
    stop("Package 'CDMConnector' >= 2.8.0 is required. Please update it to use this function.")
  }

  # TMP workaround until https://github.com/darwin-eu/CDMConnector/issues/60 is fixed:
  .tmpPatchCDMConnectorBigQuerySchemaBug()

  # Making a connection object that is used to connect to the tables:
  connection <- fg_connection(environment)

  # The write/scratch dataset used across all environments (see fg_getDatabaseConnector):
  connection@dataset <- "sandbox"

  if (is.null(cdmDataFreezeVersion)) {
    if (environment == "preview") {
      cdmDataFreezeVersion <- 'dev'
    } else if (environment == "build") {
      cdmDataFreezeVersion <- 'dev'
    } else {
      cdmDataFreezeVersion <- cdm_getLatestDataFreezeAndVersion(connection)
    }
  }


  project_id <- connection@project
  billing_project_id <- connection@billing

  cdmSchema <- paste0(project_id, ".finngen_omop_",cdmDataFreezeVersion)
  writeSchema <- paste0(billing_project_id, ".sandbox")


  cdm <- CDMConnector::cdmFromCon(
    con = connection,  # Changed from 'connection =' to 'con ='
    cdmSchema = cdmSchema,
    writeSchema = writeSchema,
    ...
  )

  return(cdm)
}


#' TEMPORARY: Patch CDMConnector's BigQuery Cross-Schema Bug
#'
#' `CDMConnector:::.inSchema()` collapses a 2-part BigQuery schema (project +
#' dataset) into a single dotted string instead of a `DBI::Id()`, which bigrquery
#' later double-qualifies when reading the table back (e.g. when `cdmFromCon()`
#' validates write access, or when `compute()`/`insertTable()`/`generateCohortSet()`
#' create tables in a `writeSchema` on a different project than the connection's
#' default). All other multi-schema dbms already build a proper `DBI::Id()`; this
#' swaps BigQuery onto that same path.
#'
#' This is a **temporary workaround**, tracked upstream at
#' <https://github.com/darwin-eu/CDMConnector/issues/60>. Remove this function and
#' its call site in `fg_CDMConnector()` once that issue is resolved and a fixed
#' CDMConnector version is required in DESCRIPTION.
#'
#' Only patches when the known-buggy implementation is detected (matched by source
#' code pattern, not version number), so it becomes a no-op — with a warning — if a
#' future CDMConnector release fixes this differently.
#'
#' @return NULL (called for side effects)
#'
#' @keywords internal
.tmpPatchCDMConnectorBigQuerySchemaBug <- function() {
  ns <- asNamespace("CDMConnector")
  current <- get(".inSchema", envir = ns)

  if (isTRUE(attr(current, "fg_patched"))) {
    return(invisible(NULL))
  }

  normalizedSource <- gsub("\\s+", " ", paste(deparse(body(current)), collapse = " "))
  isKnownBuggyImplementation <- grepl(
    'dbms == "bigquery" && length(schema) == 2',
    normalizedSource,
    fixed = TRUE
  )

  if (!isKnownBuggyImplementation) {
    warning(
      "CDMConnector's internal .inSchema() no longer matches the known BigQuery ",
      "cross-schema bug that fg_CDMConnector() works around (tracked at ",
      "https://github.com/darwin-eu/CDMConnector/issues/60). The temporary ",
      "workaround was skipped; please verify BigQuery CDM access still works as ",
      "expected, and remove .tmpPatchCDMConnectorBigQuerySchemaBug() if the ",
      "upstream issue is resolved.",
      call. = FALSE
    )
    return(invisible(NULL))
  }

  patched <- function(schema, table, dbms = NULL) {
    checkmate::assertCharacter(schema, min.len = 1, max.len = 3, null.ok = TRUE)
    checkmate::assertCharacter(table, len = 1, min.chars = 1)
    checkmate::assertCharacter(dbms, len = 1, null.ok = TRUE)

    if (is.null(schema)) {
      if (dbms == "sql server") {
        return(DBI::Id(table = paste0("#", table)))
      }
      return(DBI::Id(table = table))
    }

    if ("prefix" %in% names(schema)) {
      checkmate::assertCharacter(
        schema["prefix"], len = 1, min.chars = 1, pattern = "[a-zA-Z1-9_]+"
      )
      if (toupper(table) == table) {
        table <- paste0(toupper(schema["prefix"]), table)
      } else {
        table <- paste0(schema["prefix"], table)
      }
      schema <- schema[!names(schema) %in% "prefix"]
      checkmate::assertCharacter(schema, min.len = 1, max.len = 2)
    }

    if (isFALSE(dbms %in% c("snowflake", "sql server", "spark", "bigquery", "duckdb"))) {
      checkmate::assertCharacter(schema, len = 1)
    }

    schema <- unname(schema)
    if (!is.null(dbms) && dbms == "duckdb" && identical(schema, "main")) {
      out <- table
    } else {
      out <- switch(
        length(schema),
        DBI::Id(schema = schema, table = table),
        DBI::Id(catalog = schema[1], schema = schema[2], table = table)
      )
    }

    return(out)
  }
  attr(patched, "fg_patched") <- TRUE

  utils::assignInNamespace(".inSchema", patched, ns = ns)

  invisible(NULL)
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
#' @importFrom stats na.omit
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
#' @param cdmDataFreezeVersion Data freeze version to validate
#'
#' @return NULL (called for side effects)
#'
#' @importFrom checkmate assertString
#' @importFrom stringr str_extract
#'
#' @keywords internal
.assertDataFreezeVersion <- function(
  connection,
  cdmDataFreezeVersion
) {
  cdmDataFreezeVersion |>  checkmate::assertString(pattern =  "^r[0-9]+_v[0-9]+$|^dev$")

  validDataFreezeVersions <- datasets |>
    stringr::str_extract("(?<=finngen_omop_)[^\")]*") |>
    na.omit() |>
    as.vector()

  dataFreezeNotValid <- setdiff(dataFreeze, validDataFreezeVersions)
  if (length(dataFreezeNotValid) > 0) {
    stop(
      "Invalid cdmDataFreezeVersion: ",
      paste(dataFreezeNotValid, collapse = ", "),
      ". Valid data freezes are: ",
      paste(validDataFreezeVersions, collapse = ", "),
      "."
    )
  }
}