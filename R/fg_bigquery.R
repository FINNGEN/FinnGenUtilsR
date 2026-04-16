# -*- coding: utf-8 -*-

#' Get FinnGen BigQuery Tables
#'
#' @description
#' Creates a new fg_bq_tables object
#'
#' @param environment Environment identifier (e.g., "build", "prod")
#' @param dataFreeze (Optional) Data freeze identifier (default is NULL)
#' @param tablesPathsTibble (Optional) Tibble containing table paths (default is NULL)
#' @param tablesGroup (Optional) Table group to include: 'register' (default), 'cdm', or 'register_and_cdm'
#'
#' @return An fg_bq_tables R6 object
#'
#' @export
get_fg_bq_tables <- function(
  environment,
  dataFreeze = NULL,
  tablesPathsTibble = NULL,
  tablesGroup = "register"
) {
  fg_bq_tables$new(
    environment = environment,
    dataFreeze = dataFreeze,
    tablesPathsTibble = tablesPathsTibble,
    tablesGroup = tablesGroup
  )
}


#' FinnGen BigQuery Tables Handler
#'
#' @description
#' R6 class for handling BigQuery tables information including environment and data freeze
#'
#' @field connection BigQuery connection object (read-only).
#' @field environment Environment identifier (e.g., "build", "prod") (read-only).
#' @field dataFreeze Data freeze identifier (e.g., "r13", "dev") (read-only).
#' @field tablePaths Named list containing table paths (read-only).
#' @field tbl List of dplyr table objects (read-only).
#'
#' @param environment Environment identifier (e.g., "build", "prod")
#' @param dataFreeze (Optional) Data freeze identifier (default is NULL)
#' @param tablesPathsTibble (Optional) Tibble containing table paths (default is NULL)
#' @param tablesGroup (Optional) Table group to include: 'register' (default), 'cdm', or 'register_and_cdm'
#' @param sql Character string containing the SQL query to execute
#' @param ... Additional arguments passed to bigrquery::bq_project_query()
#'
#' @details
#' ## Methods
#'
#' \code{$new(environment, dataFreeze = NULL, tablesPathsTibble = NULL, tablesGroup = "register")} Initialize a new object.
#'
#' \code{$print()} Print information about the object.
#'
#' \code{$query(sql, ...)} Execute a SQL query against BigQuery. Returns a BigQuery table reference.
#'
#' @importFrom R6 R6Class
#' @importFrom checkmate assertString assertTibble assertClass
#' @importFrom dplyr transmute mutate select filter
#' @importFrom purrr map map_chr map2_chr
#' @importFrom tibble deframe
#' @importFrom readr read_csv cols col_character col_integer
#' @importFrom stringr str_extract str_replace str_subset
#' @importFrom glue glue
#' @importFrom bigrquery bq_project_query
#' @importFrom stats na.omit
#' @importFrom utils tail
#'
#' @export
fg_bq_tables <- R6::R6Class(
  classname = "fg_bq_tables",
  private = list(
    .connection = NULL,
    .environment = NULL,
    .dataFreeze = NULL,
    .tablePaths = NULL,
    .tbl = NULL
  ),
  active = list(
    connection = function() {
      return(private$.connection)
    },
    environment = function() {
      return(private$.environment)
    },
    dataFreeze = function() {
      return(private$.dataFreeze)
    },
    tablePaths = function() {
      return(private$.tablePaths)
    },
    tbl = function() {
      return(private$.tbl)
    }
  ),
  public = list(
    #' @description
    #' Initialize method - Creates a new fg_bq_tables object
    #'
    #' @param environment Environment identifier (e.g., "build", "prod")
    #' @param dataFreeze (Optional) Data freeze identifier (default is NULL)
    #' @param tablesPathsTibble (Optional) Tibble containing table paths (default is NULL)
    #' @param tablesGroup (Optional) Table group to include: 'register' (default), 'cdm', or 'register_and_cdm'
    initialize = function(
      environment,
      dataFreeze = NULL,
      tablesPathsTibble = NULL,
      tablesGroup = "register"
    ) {
      start_time <- Sys.time()

      # Validate tablesGroup
      tablesGroup |> checkmate::assertChoice(c("register", "cdm", "register_and_cdm"))

      if (environment == "sandbox-XX") {
        environment <- "build"
      }
      message("Connecting to BigQuery...")
      connection <- fg_connection(environment)

      if (is.null(dataFreeze)) {
        if (environment == "preview") {
          dataFreeze <- 'dev'
        } else if (environment == "build") {
          dataFreeze <- 'dev'
        } else {
          message("Finding latest data freeze...")
          dataFreeze <- fg_getLatestDataFreeze(
            connection = connection
          )
        }
      }
      message("Using data freeze: ", dataFreeze)
      .assertDataFreeze(connection, dataFreeze)

      if (is.null(tablesPathsTibble)) {
        message("Finding latest table versions...")
        tablesPathsTibble <- fg_getLatestTablePaths(
          connection = connection,
          dataFreeze = dataFreeze,
          skipDataFreezeValidation = TRUE,
          tablesGroup = tablesGroup
        )
      }

      # Table paths
      tablePaths <- tablesPathsTibble |>
        dplyr::transmute(
          table_id,
          full_path = purrr::map(
            full_path,
            ~ {
              paste0(connection@project, ".", .x)
            }
          )
        ) |>
        tibble::deframe()

      message("Creating table connections (this may take a moment)...")
      
      failed_tables <- character(0)
      
      tbl <- tablesPathsTibble |>
        dplyr::mutate(
          table_dplyr = purrr::map(
            full_path,
            function(full_path) {
              tbl <- NULL
              tryCatch(
                tbl <- dplyr::tbl(
                  connection,
                  I(paste0(connection@project, ".", full_path))
                ),
                error = function(e) {
                  failed_tables <<- c(failed_tables, full_path)
                }
              )
              return(tbl)
            }
          )
        ) |>
        dplyr::select(
          table_id,
          table_dplyr
        ) |>
        tibble::deframe()

      private$.connection <- connection
      private$.environment <- environment
      private$.dataFreeze <- dataFreeze
      private$.tablePaths <- tablePaths
      private$.tbl <- tbl

      elapsed_time <- round(
        as.numeric(difftime(Sys.time(), start_time, units = "secs")),
        2
      )
      
      # Count successful and failed connections
      n_successful <- sum(sapply(tbl, function(x) !is.null(x)))
      n_failed <- length(tbl) - n_successful
      
      if (n_failed == 0) {
        message(
          "Successfully connected to all ",
          n_successful,
          " tables in ",
          elapsed_time,
          " seconds"
        )
      } else {
        message(
          "Connected to ",
          n_successful,
          " tables (",
          n_failed,
          " failed) in ",
          elapsed_time,
          " seconds"
        )
        if (n_failed > 0) {
          failed_table_names <- names(tbl)[sapply(tbl, is.null)]
          message("Failed tables: \033[31m", paste(failed_table_names, collapse = ", "), "\033[0m")
        }
      }
    },

    #' @description
    #' Print method - Prints information about the fg_bq_tables object
    print = function() {
      cat("FinnGen BigQuery Tables Handler\n")
      cat("================================\n\n")

      cat("Environment:     ", private$.environment, "\n")
      cat("Data Freeze:     ", private$.dataFreeze, "\n")
      cat("Project:         ", private$.connection@project, "\n")
      cat("Billing Project: ", private$.connection@billing, "\n\n")

      cat("Available Tables:\n")
      cat("-----------------\n")
      for (i in seq_along(private$.tablePaths)) {
        table_name <- names(private$.tablePaths)[i]
        table_exists <- !is.null(private$.tbl[[table_name]])
        
        if (table_exists) {
          cat(sprintf(
            "  [v] %-33s %s\n",
            table_name,
            private$.tablePaths[[i]]
          ))
        } else {
          cat(sprintf(
            "  [x] %-33s %s\n",
            table_name,
            private$.tablePaths[[i]]
          ))
        }
      }

      invisible(self)
    },

    #' @description
    #' Query method - Execute a SQL query against BigQuery
    #'
    #' @param sql Character string containing the SQL query to execute
    #' @param ... Additional arguments passed to bigrquery::bq_project_query()
    #'
    #' @return A BigQuery table reference that can be downloaded with bq_table_download()
    query = function(sql, ...) {
      checkmate::assertString(sql)

      bigrquery::bq_project_query(
        x = private$.connection@project,
        query = sql,
        ...
      )
    }
  )
)

#' Get Latest Data Freeze
#'
#' @param connection BigQuery connection object
#'
#' @return Character string with the latest data freeze (e.g., "r13")
#'
#' @importFrom checkmate assertClass
#' @importFrom bigrquery bq_project_datasets
#' @importFrom purrr map_chr
#' @importFrom stringr str_extract
#'
#' @export
fg_getLatestDataFreeze <- function(
  connection
) {
  #
  # Valid data freezes
  #
  connection |> checkmate::assertClass("BigQueryConnection")

  #
  # Function
  #
  datasets <- bigrquery::bq_project_datasets(connection@project) |>
    purrr::map_chr(~ .x$dataset)

  validDataFreezes <- datasets |>
    stringr::str_extract("(?<=sandbox_tools_)[^\")]*") |>
    na.omit() |>
    as.vector()

  if (length(validDataFreezes) == 0) {
    stop(
      "There is not datasets that start with 'sandbox_tools_' in the project."
    )
  }
  lastDataFreeze <- validDataFreezes |>
    .lastNumberSuffix(prefix = "r")

  return(lastDataFreeze)
}


#' Assert Data Freeze
#'
#' @param connection BigQuery connection object
#' @param dataFreeze Data freeze identifier to validate
#'
#' @return NULL (called for side effects)
#'
#' @importFrom checkmate assertClass assertString
#' @importFrom bigrquery bq_project_datasets
#' @importFrom purrr map_chr
#' @importFrom stringr str_extract
#'
#' @keywords internal
.assertDataFreeze <- function(
  connection,
  dataFreeze
) {
  #
  # Valid data freezes
  #
  connection |> checkmate::assertClass("BigQueryConnection")
  dataFreeze |> checkmate::assertString(pattern = "^(r[0-9]+|dev)$")

  #
  # Function
  #
  datasets <- bigrquery::bq_project_datasets(connection@project) |>
    purrr::map_chr(~ .x$dataset)

  validDataFreezes <- datasets |>
    stringr::str_extract("(?<=sandbox_tools_)[^\")]*") |>
    na.omit() |>
    as.vector()

  dataFreezeNotValid <- setdiff(dataFreeze, validDataFreezes)
  if (length(dataFreezeNotValid) > 0) {
    stop(
      "Invalid dataFreeze: ",
      paste(dataFreezeNotValid, collapse = ", "),
      ". Valid data freezes are: ",
      paste(validDataFreezes, collapse = ", "),
      "."
    )
  }
}

#' Get Latest Table Paths
#'
#' @param connection BigQuery connection object
#' @param dataFreeze Data freeze identifier
#' @param skipDataFreezeValidation Whether to skip data freeze validation
#' @param tablesGroup Table group to include: 'register' (default), 'cdm', or 'register_and_cdm'
#'
#' @return Tibble with table_id and full_path columns
#'
#' @importFrom checkmate assertClass
#' @importFrom readr read_csv cols col_character col_integer
#' @importFrom dplyr filter mutate select
#' @importFrom stringr str_replace str_extract str_remove
#' @importFrom purrr map_chr map2_chr
#' @importFrom glue glue
#'
#' @export
fg_getLatestTablePaths <- function(
  connection,
  dataFreeze,
  skipDataFreezeValidation = FALSE,
  tablesGroup = "register"
) {
  # connection
  connection |> checkmate::assertClass("BigQueryConnection")

  # dataFreeze
  if (!skipDataFreezeValidation) {
    .assertDataFreeze(connection, dataFreeze)
  }

  # Validate tablesGroup
  tablesGroup |> checkmate::assertChoice(c("register", "cdm", "register_and_cdm"))

  # table paths
  validTablesPath <- system.file("csv/tables.csv", package = "FinnGenUtilsR")
  tablesPathsTibble <- readr::read_csv(
    validTablesPath,
    col_types = readr::cols(
      table_id = readr::col_character(),
      table_path_template = readr::col_character(),
      first_data_freeze = readr::col_integer()
    )
  )

  # Filter tables based on tablesGroup
  if (tablesGroup == "register") {
    tablesPathsTibble <- tablesPathsTibble |>
      dplyr::filter(!grepl("^cdm_", table_id) | table_id == "cdm_concept")
  } else if (tablesGroup == "cdm") {
    tablesPathsTibble <- tablesPathsTibble |>
      dplyr::filter(grepl("^cdm_", table_id))
  }
  # "register_and_cdm" keeps all tables
  dataFreezeNumber <- ifelse(
    dataFreeze == "dev",
    Inf,
    as.numeric(stringr::str_remove(dataFreeze, "^r"))
  )

  tablesPathsTibble <- tablesPathsTibble |>
    dplyr::filter(
      first_data_freeze <= dataFreezeNumber
    ) |>
    dplyr::mutate(
      table_path = stringr::str_replace(
        table_path_template,
        "\\{data_freeze\\}",
        dataFreeze
      )
    )

  tablesPathsTibble <- tablesPathsTibble |>
    dplyr::mutate(
      full_path = purrr::map_chr(
        table_id,
        function(table_id) {
          template <- tablesPathsTibble$table_path_template[
            tablesPathsTibble$table_id == table_id
          ]
          if (dataFreeze == "dev") {
            version <- "dev"
          } else {
            version <- .lastTableVersion(
              connection,
              glue::glue(
                template,
                datafreeze = dataFreeze,
                version = "{version}"
              )
            )
          }
          a <- glue::glue(
            template,
            datafreeze = dataFreeze,
            version = version
          ) |>
            as.character()
          message("  - ", table_id, ": ", a)
          return(a)
        }
      )
    ) |>
    dplyr::select(
      table_id,
      full_path
    )

  # special case
  if (dataFreeze == "dev") {
    tablesPathsTibble <- tablesPathsTibble |>
      dplyr::mutate(
        full_path = stringr::str_replace(full_path, "dev_dev", "dev"),
        full_path = stringr::str_replace(
          full_path,
          "medical_codes",
          "medical_codes_dev"
        )
      )
  }

  return(tablesPathsTibble)
}

#' Get Last Table Version
#'
#' @param connection BigQuery connection object
#' @param full_path Full path template for the table
#'
#' @return Character string with the latest version (e.g., "v3")
#'
#' @importFrom bigrquery bq_dataset_tables bq_dataset
#' @importFrom purrr map_chr
#' @importFrom stringr str_extract str_subset str_replace
#'
#' @keywords internal
.lastTableVersion <- function(
  connection,
  full_path
) {
  project_id <- connection@project
  dataset_id <- stringr::str_extract(full_path, "^[^.]+")

  if (grepl("finngen_omop", dataset_id)) {
    currentFinngenOmopDataFreeze <- stringr::str_extract(dataset_id, "^finngen_omop_r[0-9]+")
    lastVersion <- bigrquery::bq_project_datasets(project_id) |>
      purrr::map_chr(~ .x$dataset) |>
      stringr::str_subset(currentFinngenOmopDataFreeze) |>
      stringr::str_extract("[^_]+$") |>
      .lastNumberSuffix(prefix = "v")
  } else {
    table_id <- stringr::str_extract(full_path, "(?<=\\.)[^.]+$") |>
      stringr::str_replace("\\{version\\}", "")

    dataSet <- bigrquery::bq_dataset_tables(
      bigrquery::bq_dataset(
        project = project_id,
        dataset = dataset_id
      )
    ) |>
      purrr::map_chr(~ .x$table)

    lastVersion <- dataSet |>
      stringr::str_subset(paste0("^", table_id)) |>
      stringr::str_extract("[^_]+$") |>
      .lastNumberSuffix(prefix = "v")
  }

  return(lastVersion)
}


#' Get Last Number Suffix
#'
#' @param stringVector Vector of strings with number suffixes
#' @param prefix Prefix before the number (either "r" or "v")
#'
#' @return Character string with the highest number suffix
#'
#' @importFrom checkmate checkSubset
#' @importFrom stringr str_remove
#'
#' @keywords internal
.lastNumberSuffix <- function(
  stringVector,
  prefix
) {
  prefix |> checkmate::checkSubset(c("r", "v"))
  suppressWarnings(
    sortStringVector <- paste0(
      prefix,
      stringVector |>
        stringr::str_remove(paste0("^", prefix)) |>
        as.numeric() |>
        max(na.rm = TRUE)
    )
  )

  return(sortStringVector |> tail(1))
}
