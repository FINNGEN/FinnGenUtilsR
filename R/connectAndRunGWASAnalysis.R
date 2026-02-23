
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
    error_message <- stringr::str_c("Could not connect to sandbox API url: ", url, " token:", token, " Error: ", e)
  }else if(httr::status_code(res) != 200){
    res_content <- httr::content(res)
    error_message <- as.character(res_content)[1]
  }else{
    res_content <- httr::content(res)
    name <- res_content$name
    notification_email <- res_content$notification_email
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

  if(!stringr::str_detect(phenotype_name, "^[A-Za-z][A-Za-z0-9_]*$")){
    stop("phenotype_name must start with a letter and contain only letters, numbers, or underscores")
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


#' @title runRegenieStandardPipeline
#' @description Submit the Regenie unmodifiable standard pipeline via internal standard-pipelines API.
#'   Creates phenotype + description files locally, uploads them to
#'   SANDBOX_RED/CO2_temp/<usertemp>/<run_tag>/ (using RED_BUCKET for gsutil),
#'   builds WDL-style input JSON referencing SANDBOX_RED paths, and submits the workflow.
#'   Users are allowed to add additional covariates using a dataframe of columns for each additional covariate.
#'
#' @param connection_sandboxAPI List-like object containing base_url, token, conn_status_tibble
#' @param standard_pipeline_id Standard pipeline id of the pipeline to be used
#' @param cases_finngenids Character vector of FINNGENIDs for cases
#' @param controls_finngenids Character vector of FINNGENIDs for controls
#' @param phenotype_name Phenotype column name (must start with a letter; letters/numbers/_)
#' @param phenotype_description Single string description written to phenodescription file (1 line)
#' @param covariates Optional comma-separated covariate string of the standard FinnGen covariates
#' @param extra_covariates_df data.frame with FID/IID + extra covariate columns
#' @param test Genetic model test string, Default: "additive"
#' @param is_binary String "true"/"false" to specify binary or quantitative GWAS analysis type, Default: "true"
#' @param endpoint_path internal API path, Default: "v2/standard-pipelines"
#' @param timeout_sec httr timeout seconds, Default: 300
#'
#' @return list(status, http_status, workflow_id, content, temp_files, sandbox_paths_used, upload_logs)
#'
#' @export
#' @importFrom httr add_headers upload_file POST status_code content timeout
#' @importFrom jsonlite toJSON write_json
#' @importFrom readr write_tsv write_lines
#' @importFrom dplyr bind_rows left_join
#' @importFrom tibble tibble
#' @importFrom stringr str_detect str_c
runRegenieStandardPipeline <- function(
    connection_sandboxAPI,
    standard_pipeline_id = "5718330904150016",
    cases_finngenids,
    controls_finngenids,
    phenotype_name,
    phenotype_description,
    covariates = "SEX_IMPUTED,AGE_AT_DEATH_OR_END_OF_FOLLOWUP,PC{1:10},IS_FINNGEN2_CHIP,BATCH_DS1_BOTNIA_Dgi_norm,BATCH_DS10_FINRISK_Palotie_norm,BATCH_DS11_FINRISK_PredictCVD_COROGENE_Tarto_norm,BATCH_DS12_FINRISK_Summit_norm,BATCH_DS13_FINRISK_Bf_norm,BATCH_DS14_GENERISK_norm,BATCH_DS15_H2000_Broad_norm,BATCH_DS16_H2000_Fimm_norm,BATCH_DS17_H2000_Genmets_norm_relift,BATCH_DS18_MIGRAINE_1_norm_relift,BATCH_DS19_MIGRAINE_2_norm,BATCH_DS2_BOTNIA_T2dgo_norm,BATCH_DS20_SUPER_1_norm_relift,BATCH_DS21_SUPER_2_norm_relift,BATCH_DS22_TWINS_1_norm,BATCH_DS23_TWINS_2_norm_nosymmetric,BATCH_DS24_SUPER_3_norm,BATCH_DS25_BOTNIA_Regeneron_norm,BATCH_DS26_DIREVA_norm,BATCH_DS27_NFBC66_norm,BATCH_DS28_NFBC86_norm,BATCH_DS3_COROGENE_Sanger_norm,BATCH_DS4_FINRISK_Corogene_norm,BATCH_DS5_FINRISK_Engage_norm,BATCH_DS6_FINRISK_FR02_Broad_norm_relift,BATCH_DS7_FINRISK_FR12_norm,BATCH_DS8_FINRISK_Finpcga_norm,BATCH_DS9_FINRISK_Mrpred_norm",
    extra_covariates_df = NULL,
    test = "additive",
    is_binary = "true",
    endpoint_path = "v2/standard-pipelines",
    timeout_sec = 300
) {

  .extract_uuid <- function(x) {
    m <- regmatches(
      x,
      regexpr("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", x, ignore.case = TRUE)
    )
    if (length(m) == 0 || is.na(m) || m == "") return(NA_character_)
    m
  }

  .safe_user_temp <- function(connection_sandboxAPI) {
    u <- NULL
    if (!is.null(connection_sandboxAPI$name) && nzchar(as.character(connection_sandboxAPI$name))) {
      u <- as.character(connection_sandboxAPI$name)
    } else {
      u <- Sys.info()[["user"]]
    }
    if (is.null(u) || is.na(u) || !nzchar(u)) u <- "unknown_user"
    gsub("[^A-Za-z0-9._-]+", "_", u)
  }

  .get_red_bucket_gs <- function() {
    out <- tryCatch(
      system("bash -ic 'echo $RED_BUCKET' 2>/dev/null", intern = TRUE),
      error = function(e) character(0)
    )

    # Pick the first gs://...-red line
    gs_line <- grep("^\\s*gs://.*-red\\b", out, value = TRUE)
    if (length(gs_line) == 0) stop("Could not detect RED sandbox bucket from shell output")

    trimws(gs_line[1])
  }

  .require_gsutil <- function() {
    if (!nzchar(Sys.which("gsutil"))) stop("gsutil not found on PATH.")
  }

  .gsutil_cp <- function(src, dest_gs) {
    out <- system2("gsutil", c("cp", src, dest_gs), stdout = TRUE, stderr = TRUE)
    status <- attr(out, "status")
    if (!is.null(status) && status != 0) {
      stop("gsutil cp failed for dest: ", dest_gs, "\n", paste(out, collapse = "\n"))
    }
    out
  }

  .gsutil_stat <- function(dest_gs) {
    out <- system2("gsutil", c("-q", "stat", dest_gs), stdout = TRUE, stderr = TRUE)
    status <- attr(out, "status")
    if (!is.null(status) && status != 0) stop("gsutil stat failed for: ", dest_gs)
    TRUE
  }

  .parse_covariate_names <- function(covariates_str) {
    if (is.null(covariates_str) || !nzchar(covariates_str)) return(character(0))
    x <- unlist(strsplit(covariates_str, ",", fixed = TRUE), use.names = FALSE)
    x <- trimws(x)
    x[nzchar(x)]
  }

  # validate
  if (!stringr::str_detect(phenotype_name, "^[A-Za-z][A-Za-z0-9_]*$")) {
    stop("phenotype_name must start with a letter and contain only letters, numbers, or underscores")
  }
  if (is.null(standard_pipeline_id) || standard_pipeline_id == "") {
    stop("standard_pipeline_id is required and must be a non-empty string")
  }
  if (length(cases_finngenids) == 0 || length(controls_finngenids) == 0) {
    stop("cases_finngenids and controls_finngenids must be non-empty")
  }

  if (!is.null(connection_sandboxAPI$conn_status_tibble$logTibble$type) &&
      identical(connection_sandboxAPI$conn_status_tibble$logTibble$type, "ERROR")) {
    return(list(status = FALSE, message = "Connection in connection_sandboxAPI not stabilised"))
  }

  .require_gsutil()

  red_bucket_gs <- .get_red_bucket_gs()
  red_bucket_gs <- sub("/+$", "", red_bucket_gs)

  # Build base phenotype file df: FID, IID, phenotype
  pheno_df <- dplyr::bind_rows(
    tibble::tibble(FID = cases_finngenids,    IID = cases_finngenids,    value = 1),
    tibble::tibble(FID = controls_finngenids, IID = controls_finngenids, value = 0)
  )
  names(pheno_df)[names(pheno_df) == "value"] <- phenotype_name

  # Merge extra covariates if provided
  if (!is.null(extra_covariates_df)) {
    if (!is.data.frame(extra_covariates_df)) {
      stop("extra_covariates_df must be a data.frame (or NULL).")
    }
    if (!any(c("FID", "IID") %in% colnames(extra_covariates_df))) {
      stop("extra_covariates_df must contain a FINNGENID identifier column named FID or IID.")
    }

    extra <- extra_covariates_df

    # ensure FID exists for join
    if (!("FID" %in% colnames(extra))) {
      extra$FID <- extra$IID
    }

    # enforce one row per FID
    if (anyDuplicated(extra$FID)) {
      stop("extra_covariates_df has duplicate FID values. Must be one row per individual.")
    }

    # covariate columns
    cov_cols <- setdiff(colnames(extra), c("FID", "IID"))
    if (length(cov_cols) == 0) {
      stop("extra_covariates_df provided but contains no covariate columns (only FID/IID).")
    }

    # name checks
    if (any(cov_cols %in% c("FID", "IID", phenotype_name))) {
      stop("extra covariate columns cannot be named FID, IID, or equal to phenotype_name.")
    }

    # forbid collisions with standard covariate names in covariates
    standard_cov_names <- .parse_covariate_names(covariates)
    collisions <- intersect(cov_cols, standard_cov_names)
    if (length(collisions) > 0) {
      stop(
        "extra_covariates_df contains covariate column(s) that collide with names in `covariates`: ",
        paste(collisions, collapse = ", "),
        ". Rename those extra covariate columns."
      )
    }

    pheno_df <- dplyr::left_join(pheno_df, extra[, c("FID", cov_cols), drop = FALSE], by = "FID")
  }

  # Write files to tempdir
  tmp_dir <- tempdir()
  tmp_pheno_path <- file.path(tmp_dir, "phenofile.tsv")
  tmp_desc_path  <- file.path(tmp_dir, "phenodescriptionfile.txt")
  tmp_input_json_path <- file.path(tmp_dir, "standard_pipeline_input.json")

  readr::write_tsv(pheno_df, tmp_pheno_path)
  readr::write_lines(c(phenotype_description), tmp_desc_path)

  # Upload to RED bucket, reference SANDBOX_RED in inputs JSON
  usertemp <- .safe_user_temp(connection_sandboxAPI)
  run_tag  <- format(Sys.time(), "%Y%m%d_%H%M%S")

  sandbox_dir_alias <- paste0("SANDBOX_RED/CO2_temp/", usertemp, "/", run_tag)
  dest_pheno_alias  <- paste0(sandbox_dir_alias, "/phenofile.tsv")
  dest_desc_alias   <- paste0(sandbox_dir_alias, "/phenodescriptionfile.txt")

  sandbox_dir_gs <- paste0(red_bucket_gs, "/CO2_temp/", usertemp, "/", run_tag)
  dest_pheno_gs  <- paste0(sandbox_dir_gs, "/phenofile.tsv")
  dest_desc_gs   <- paste0(sandbox_dir_gs, "/phenodescriptionfile.txt")

  upload_log_pheno <- .gsutil_cp(tmp_pheno_path, dest_pheno_gs)
  upload_log_desc  <- .gsutil_cp(tmp_desc_path,  dest_desc_gs)
  invisible(.gsutil_stat(dest_pheno_gs))
  invisible(.gsutil_stat(dest_desc_gs))

  # Build WDL-style input JSON
  inputs_obj <- list(
    "regenie_unmod.pheno_file" = dest_pheno_alias,
    "regenie_unmod.phenolist"  = phenotype_name,
    "regenie_unmod.phenodescriptionlist" = dest_desc_alias,
    "regenie_unmod.test"       = test,
    "regenie_unmod.is_binary"  = is_binary
  )
  if (!is.null(covariates) && nzchar(covariates)) {
    inputs_obj[["regenie_unmod.covariates"]] <- covariates
  }

  jsonlite::write_json(
    x = inputs_obj,
    path = tmp_input_json_path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  # POST to standard pipelines API
  authorization <- paste("Bearer", connection_sandboxAPI$token)
  headers <- httr::add_headers(c("Authorization" = authorization))
  url <- paste0(connection_sandboxAPI$base_url, endpoint_path)

  data_json <- jsonlite::toJSON(list(id = standard_pipeline_id), auto_unbox = TRUE)

  body <- list(
    input = httr::upload_file(tmp_input_json_path, type = "application/json"),
    data  = data_json
  )

  logTibble <- connection_sandboxAPI$conn_status_tibble$logTibble

  if (!is.null(logTibble$type) && identical(logTibble$type, "ERROR")) {

    res <- list(
      status = FALSE,
      message = "Connection in connection_sandboxAPI not stabilised"
    )

  } else {

    res <- tryCatch({
      r <- httr::POST(
        url = url,
        body = body,
        encode = "multipart",
        headers,
        httr::timeout(timeout_sec)
      )

      raw_content <- paste(httr::content(r), collapse = "\n")

      list(
        status = httr::status_code(r) %in% c(200, 201),
        http_status = httr::status_code(r),
        workflow_id = .extract_uuid(raw_content),
        content = raw_content,
        temp_files = list(
          phenofile = tmp_pheno_path,
          phenodescription = tmp_desc_path,
          input_json = tmp_input_json_path
        ),
        sandbox_paths_used = list(
          RED_BUCKET = red_bucket_gs,
          sandbox_dir_alias = sandbox_dir_alias,
          sandbox_dir_gs = sandbox_dir_gs,
          regenie_unmod.pheno_file = dest_pheno_alias,
          regenie_unmod.phenodescriptionlist = dest_desc_alias
        )
      )
    }, error = function(cond) {
      list(
        status = FALSE,
        message = stringr::str_c("Unexpected error in runRegenieStandardPipeline: ", cond$message),
        temp_files = list(
          phenofile = tmp_pheno_path,
          phenodescription = tmp_desc_path,
          input_json = tmp_input_json_path
        )
      )
    })

  }

  return(res)
}








