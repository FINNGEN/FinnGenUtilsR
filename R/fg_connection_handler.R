#' fg_connection_handler
#'
#' @description
#' Class for handling database connection and schema information for a CDM database
#'
#' @field databaseName           A text id for the database the it connects to (read-only).
#' @field connectionHandler           ConnectionHandler object for managing the database connection (read-only).
#' @field sandboxToolsSchema    Name of the vocabulary database schema (read-only).
#' @field medicalCodesSchema           Name of the CDM database schema (read-only).
#' @field connectionStatusLog            Log tibble object for storing connection status information (read-only).
#' @field getTblmedicalCodesSchema               List of functions that create dbplyr table for the vocabulary tables (read-only).
#' @field getTblsandboxToolsSchema                      List of functions that create dbplyr table for the CDM tables (read-only).
#'
#' @importFrom R6 R6Class
#' @importFrom checkmate assertClass assertString
#' @importFrom dplyr filter select collect
#' @importFrom DBI dbIsValid
#' @importFrom DatabaseConnector connect disconnect getTableNames dropEmulatedTempTables
#'
#' @export
fg_connection_handler <- R6::R6Class(
  classname = "fg_connection_handler",
  private = list(
    .databaseName = NULL,
    # database parameters
    .connectionHandler = NULL,
    .medicalCodesSchema = NULL,
    .sandboxToolsSchema = NULL,
    .connectionStatusLog = NULL,
    #
    .getTblmedicalCodesSchema = NULL,
    .getTblsandboxToolsSchema = NULL
  ),
  active = list(
    databaseName = function(){return(private$.databaseName)},
    # database parameters
    connectionHandler = function(){return(private$.connectionHandler)},
    medicalCodesSchema = function(){return(private$.medicalCodesSchema)},
    sandboxToolsSchema = function(){return(private$.sandboxToolsSchema)},
    connectionStatusLog = function(){return(private$.connectionStatusLog$logTibble |>
                                              dplyr::mutate(databaseName = private$.databaseName) |>
                                              dplyr::relocate(databaseName, .before = 1))},

    getTblmedicalCodesSchema = function(){return(private$.getTblmedicalCodesSchema)},
    getTblsandboxToolsSchema = function(){return(private$.getTblsandboxToolsSchema)}
  ),
  public = list(
    #'
    #' @param databaseName           A text id for the database the it connects to
    #' @param connectionHandler             A ConnectionHandler object
    #' @param medicalCodesSchema             Name of the CDM database schema
    #' @param sandboxToolsSchema      (Optional) Name of the vocabulary database schema (default is medicalCodesSchema)
    initialize = function(
    databaseName,
    connectionHandler,
    medicalCodesSchema,
    sandboxToolsSchema
    ) {
      checkmate::assertString(databaseName)
      checkmate::assertClass(connectionHandler, "ConnectionHandler")
      checkmate::assertString(medicalCodesSchema)
      checkmate::assertString(sandboxToolsSchema)

      private$.databaseName <- databaseName
      private$.connectionHandler <- connectionHandler
      private$.sandboxToolsSchema <- sandboxToolsSchema
      private$.medicalCodesSchema <- medicalCodesSchema

      self$loadConnection()
    },

    #' Finalize method
    #' @description
    #' Closes the connection if active.
    finalize = function() {
      private$.connectionHandler$finalize()
    },

    #' Reload connection
    #' @description
    #' Updates the connection status by checking the database connection
    loadConnection = function() {
      connectionStatusLog <- LogTibble$new()

      # Check db connection
      errorMessage <- ""
      tryCatch(
        {
          private$.connectionHandler$initConnection()
        },
        error = function(error) {
          errorMessage <<- error$message
        },
        warning = function(warning){}
      )

      if (errorMessage != "" | !private$.connectionHandler$dbIsValid()) {
        connectionStatusLog$ERROR("Check database connection", errorMessage)
      } else {
        connectionStatusLog$SUCCESS("Check database connection", "Valid connection")
      }

      # Check can create temp tables
      errorMessage <- ""
      tryCatch(
        {
          private$.connectionHandler$getConnection() |>
            HadesExtras:::tmp_dplyr_copy_to(cars, overwrite = TRUE)
          private$.connectionHandler$getConnection() |>
            DatabaseConnector::dropEmulatedTempTables()
        },
        error = function(error) {
          errorMessage <<- error$message
        }
      )

      if (errorMessage != "") {
        connectionStatusLog$WARNING("Check temp table creation", errorMessage)
      } else {
        connectionStatusLog$SUCCESS("Check temp table creation", "can create temp tables")
      }

      # Check sandboxToolsSchema and populates getTblsandboxToolsSchema
      getTblsandboxToolsSchema <- list()
      errorMessage <- ""
      tryCatch(
        {

          tablesInSandboxToolsSchema <- DatabaseConnector::getTableNames(private$.connectionHandler$getConnection(), private$.sandboxToolsSchema)

          for (tableName in tablesInSandboxToolsSchema) {
            text <- paste0('function() { private$.connectionHandler$tbl( "',tableName, '", "', private$.sandboxToolsSchema,'")}')
            getTblsandboxToolsSchema[[tableName]] <- eval(parse(text = text))
          }
        },
        error = function(error) {
          errorMessage <<- error$message
        }
      )

      if (errorMessage != "") {
        connectionStatusLog$ERROR("sandboxToolsSchema connection", errorMessage)
      } else {
        connectionStatusLog$SUCCESS(
          "sandboxToolsSchema connection",
          "Connected to tables:", paste0(names(getTblsandboxToolsSchema), collapse = ", ")
        )
      }

      # Check medicalCodesSchema and populates getTblmedicalCodesSchema
      getTblmedicalCodesSchema <- list()
      errorMessage <- ""
      tryCatch(
        {
          tablesInMedicalCodesSchema <- DatabaseConnector::getTableNames(private$.connectionHandler$getConnection(), private$.medicalCodesSchema)

         for (tableName in tablesInMedicalCodesSchema) {
            text <- paste0('function() { private$.connectionHandler$tbl( "',tableName, '", "', private$.medicalCodesSchema,'")}')
            getTblmedicalCodesSchema[[tableName]] <- eval(parse(text = text))
          }
        },
        error = function(error) {
          errorMessage <<- error$message
        }
      )

      if (errorMessage != "") {
        connectionStatusLog$ERROR("medicalCodesSchema connection", errorMessage)
      } else {
        connectionStatusLog$SUCCESS(
          "medicalCodesSchema connection",
          "Connected to tables:", paste0(names(getTblmedicalCodesSchema), collapse = ", ")
        )
      }

      # update status
      private$.connectionStatusLog <- connectionStatusLog
      private$.getTblmedicalCodesSchema <- getTblmedicalCodesSchema
      private$.getTblsandboxToolsSchema <- getTblsandboxToolsSchema
    }


  )
)


#' createfg_connection_handlerFromList
#'
#' A function to create a fg_connection_handler object from a list of configuration settings.
#'
#' @param config A list containing configuration settings for the fg_connection_handler.
#'   - databaseName: The name of the database.
#'   - connection: A list of connection details settings.
#'   - cdm: A list of CDM database schema settings.
#'   - cohortTable: The name of the cohort table.
#'
#' @return A fg_connection_handler object.
#'
#' @importFrom checkmate assertList assertSubset
#'
#' @export
create_fg_connection_handler_FromList <- function(
    config
) {

  config |> checkmate::assertList()
  config |> names() |> checkmate::assertNames(must.include = c("databaseName", "connection", "schemas" ))

  connectionHandler <- HadesExtras::ResultModelManager_createConnectionHandler(
    connectionDetailsSettings = config$connection$connectionDetailsSettings,
    tempEmulationSchema = config$connection$tempEmulationSchema,
    useBigrqueryUpload = config$connection$useBigrqueryUpload
  )

  FGdb <- fg_connection_handler$new(
    databaseName = config$databaseName,
    connectionHandler = connectionHandler,
    medicalCodesSchema = config$schemas$medicalCodesSchema,
    sandboxToolsSchema = config$schemas$sandboxToolsSchema
  )

  return(FGdb)

}
































