
#' @title FUNCTION_TITLE
#' @description FUNCTION_DESCRIPTION
#' @param base_url PARAM_DESCRIPTION
#' @param token PARAM_DESCRIPTION
#' @return OUTPUT_DESCRIPTION
#' @details DETAILS
#' @export
#' @importFrom httr add_headers GET content status_code
#' @importFrom tibble tibble
createSandboxAPIConnection <- function(base_url, token) {

  # if different version of openssl package is used in docker and URL host
  # there will be an error. To avoid the error set up the following configs
  httr::set_config(httr::config(ssl_verifypeer = FALSE, ssl_verifyhost = FALSE))

  # create call to get users info
  authorization = paste("Bearer", token)
  headers = httr::add_headers(c('Authorization'=authorization))
  url = paste0(base_url, "v2/user/information")

  e <- tryCatch({
    res = httr::GET(url, config = headers)
  },
  error = function(cond) {
    return(cond$message)
  })

  # prepare output depending on error
  error_message <- ""
  name = ""
  notification_email = ""
  if (class(e)[1] == "character") {
    error_message <- stringr::str_c("Could not connect to sangbox API url: ", url, " token:", token, " Error: ", e)
  }else if(httr::status_code(res) != 200){
    res_content <- httr::content(res)
    error_message <- as.character(res_content)[1]
  }else{
    res_content <- httr::content(res)
    name <- res_content$Name
    notification_email <- res_content$NotificationEmail
  }

  # status tibble
  conn_status <- LogTibble$new()
  if (error_message !=""){
    conn_status$ERROR("Test connection Sandbox API", error_message)
  } else {
    conn_status$SUCCESS("Test connection Sandbox API", "Valid connection")
  }

  return(list(
    base_url = base_url,
    token = token,
    name = name,
    notification_email = notification_email,
    conn_status_tibble = conn_status
  ))

}



#' @title runGWASAnalysis
#' @description runGWASAnalysis
#' @param connection_sandboxAPI PARAM_DESCRIPTION
#' @param cases_finngenids PARAM_DESCRIPTION
#' @param controls_finngenids PARAM_DESCRIPTION
#' @param phenotype_name PARAM_DESCRIPTION
#' @param title PARAM_DESCRIPTION, Default: phenotype_name
#' @param description PARAM_DESCRIPTION, Default: phenotype_name
#' @param notification_email PARAM_DESCRIPTION, Default: connection_sandboxAPI$notification_email
#' @param analysis_type Specifies type of the analysis to perform (additive, recessive, dominant), Default: 'additive'
#' @param release PARAM_DESCRIPTION, Default: 'Regenie12'
#' @export
#' @importFrom stringr str_detect
#' @importFrom dplyr bind_rows
#' @importFrom tibble tibble
#' @importFrom readr write_tsv
#' @importFrom httr add_headers upload_file POST status_code content
#' @importFrom jsonlite toJSON
runGWASAnalysis <- function(
    connection_sandboxAPI,
    cases_finngenids,
    controls_finngenids,
    phenotype_name,
    title = phenotype_name,
    description = phenotype_name,
    notification_email = connection_sandboxAPI$notification_email,
    analysis_type = "additive",
    release = "Regenie12"
) {

  if(!stringr::str_detect(phenotype_name, "^[[:upper:]|[:digit:]]+$")){
    stop("phenotype_name must contain only in capital letters or numbers" )
  }

  # create phenofile
  tmp_path_phenofile = file.path(tempdir(), "phenofile.tsv")

  dplyr::bind_rows(
    tibble::tibble( FID = cases_finngenids, {{phenotype_name}}:=1),
    tibble::tibble( FID = controls_finngenids, {{phenotype_name}}:=0)
  ) |> readr::write_tsv(tmp_path_phenofile)

  # prepare api params
  authorization = paste("Bearer", connection_sandboxAPI$token)
  headers = httr::add_headers(c('Authorization'=authorization, 'Content-Type'="multipart/form-data"))

  url = paste0(connection_sandboxAPI$base_url, "v2/gwas")

  json = jsonlite::toJSON(
    list(
      num_cases=length(cases_finngenids),
      num_controls=length(controls_finngenids),
      title = title,
      description = description,
      phenotype_name = phenotype_name,
      notification_email = notification_email,
      analysistype = analysis_type,
      release = release
    ),
    auto_unbox = TRUE)

  body = list(data=json, phenofile=httr::upload_file(tmp_path_phenofile))

  logTibble = connection_sandboxAPI$conn_status_tibble$logTibble

  if(logTibble$type == "ERROR"){
    res <- list(
      status = FALSE,
      message = "Connection in connection_sandboxAPI not stablised"
    )
  }else{
    # post call
    res <- tryCatch({
      res <- httr::POST(url, body=body, headers)
      res <- list(
        status = httr::status_code(res) == 200,
        content = paste(httr::content(res), collapse = "\n")
      )
    },
    error = function(cond) {
      return(list(
        status = FALSE,
        message = stringr::str_c("Un expected error in runGWASAnalysis", cond$message)
      ))
    })
  }


  return(res)

}




