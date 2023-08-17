
#' Get CDM Configuration
#'
#' This function retrieves the configuration settings to work with the OMOP-CDM database for a specified environment and data freeze number.
#'
#' @param environment Environment must be 'sandbox-' followed by the sandbox number (Alternatively, it can be 'atlasDevelopment' for testing outside sandbox).
#' @param dataFreezeNumber The data freeze number to retrieve configuration settings for.
#' @param cohortTableName If a cohort table is needed, it can be set here, (default is "test_cohort_table").
#' @param atlasDevelopment_gckey If environment = 'atlasDevelopment', the path to the Google Cloud key file.
#' @param atlasDevelopment_pathToDriver If environment = 'atlasDevelopment', the path to the BigQuery driver.
#' @param asYaml Whether to return the configuration settings as a YAML string (default is FALSE).
#'
#' @return A list of configuration settings for the specified environment and data freeze number.
#'
#' @examples
#' get_cdm_config("sandbox-6", 13)
#'
#' @importFrom checkmate assert_string assert_number
#' @importFrom stringr str_detect str_replace_all
#' @importFrom yaml yaml.load
#'
#' @export
get_cdm_config <- function(
    environment,
    dataFreezeNumber,
    cohortTableName = "test_cohort_table",
    atlasDevelopment_gckey =  Sys.getenv("GCP_SERVICE_KEY"),
    atlasDevelopment_pathToDriver = paste0(Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"),"/bigquery/"),
    asYaml = FALSE
) {

#browser()
  checkmate::assert_string(environment)
  if(environment!="atlasDevelopment" & !stringr::str_detect(environment, "^sandbox-[:digit:]+")){
    stop("Environment must be 'sandbox-' followed by the sandbox number.
         you can see that number in the url in your browser.
         e.g https://sandbox.finngen.fi/fg-production-sandbox-6/vm will be environment = sandbox-6.
         (Alternatively, it can be 'atlasDevelopment' for testing outside sandbox)")
  }

  checkmate::assert_number(dataFreezeNumber)
  checkmate::assert_string(cohortTableName)


  if (environment == "atlasDevelopment") {
    configYalm <- '
        databaseName: atlasDevelopment
        connection:
          connectionDetailsSettings:
            dbms: bigquery
            user: ""
            password: ""
            connectionString: jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443;ProjectId=atlas-development-270609;OAuthType=0;OAuthServiceAcctEmail=146473670970-compute@developer.gserviceaccount.com;OAuthPvtKeyPath=<atlasDevelopment_gckey>;Timeout=100000;
            pathToDriver: <atlasDevelopment_pathToDriver>
          tempEmulationSchema: atlas-development-270609.sandbox #needed for creating tmp table in BigQuery
          useBigrqueryUpload: true # option for HadesExtras
        cdm:
          cdmDatabaseSchema: atlas-development-270609.finngen_omop_r<dataFreezeNumber>
          vocabularyDatabaseSchema: atlas-development-270609.finngen_omop_r<dataFreezeNumber>
        cohortTable:
          cohortDatabaseSchema: atlas-development-270609.sandbox
          cohortTableName: <cohortTableName>
        webAPIurl: https://localhost:8080/WebAPI/
    ' |>
      stringr::str_replace_all("<dataFreezeNumber>", as.character(dataFreezeNumber)) |>
      stringr::str_replace_all("<cohortTableName>", cohortTableName) |>
      stringr::str_replace_all("<atlasDevelopment_gckey>", atlasDevelopment_gckey) |>
      stringr::str_replace_all("<atlasDevelopment_pathToDriver>", atlasDevelopment_pathToDriver)
  }

  if (stringr::str_detect(environment, "^sandbox-")) {
    configYalm <- '
        databaseName: FinnGen-DF<dataFreezeNumber>
        connection:
          connectionDetailsSettings:
            dbms: bigquery
            user: ""
            password: ""
            connectionString: jdbc:bigquery://https://www.googleapis.com/auth/bigquery:433;ProjectId=fg-production-<environment>;OAuthType=3;Timeout=10000;
            pathToDriver: /home/ivm/.jdbc_drivers/bigquery
          tempEmulationSchema: fg-production-<environment>.sandbox #needed for creating tmp table in BigQuery
          useBigrqueryUpload: true # option for HadesExtras
        cdm:
          cdmDatabaseSchema: finngen-production-library.finngen_omop_r<dataFreezeNumber>
          vocabularyDatabaseSchema: finngen-production-library.finngen_omop_r<dataFreezeNumber>
        cohortTable:
          cohortDatabaseSchema: fg-production-<environment>.sandbox
          cohortTableName: <cohortTableName>
        webAPIurl: https://ohdsi-webapi.app.finngen.fi/WebAPI/
    ' |>
      stringr::str_replace_all("<environment>", environment) |>
      stringr::str_replace_all("<dataFreezeNumber>", as.character(dataFreezeNumber)) |>
      stringr::str_replace_all("<cohortTableName>", cohortTableName)
  }

  configList <- yaml::yaml.load(configYalm)

  options(sqlRenderTempEmulationSchema = configList$connection$tempEmulationSchema)
  message("Set option sqlRenderTempEmulationSchema = '", configList$connection$tempEmulationSchema, "'")

  if (asYaml==TRUE) {
    return(configYalm)
  }
  return(configList)


}
