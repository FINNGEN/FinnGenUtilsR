
#' Generate Data Summaries Report for FinnGen Register Data
#'
#' @description
#' Creates an R Markdown report with summary statistics for each table in fg_bq_tables
#'
#' @param fg_bq_tables An fg_bq_tables object
#' @param output_path Path where the R Markdown file will be written. If NULL, creates a temp file, renders to HTML, and opens in browser.
#' @param detailedOutput Logical flag to include detailed column-level statistics (default: FALSE)
#'
#' @return The path to the generated R Markdown file (invisibly)
#'
#' @importFrom checkmate assert_class assertString assertLogical
#' @importFrom dplyr tally n_distinct summarise collect across where
#' @importFrom purrr map_chr
#' @importFrom glue glue
#' @importFrom utils head
#'
#' @export
fg_register_data_summaries <- function(
  fg_bq_tables,
  output_path = NULL,
  detailedOutput = FALSE
) {
  fg_bq_tables |> checkmate::assert_class('fg_bq_tables')
  if (!is.null(output_path)) output_path |> checkmate::assertString()
  detailedOutput |> checkmate::assertLogical()
  
  # Create temp file if output_path is NULL
  render_html <- is.null(output_path)
  if (render_html) {
    output_path <- tempfile(fileext = ".md")
  }
  
  # Initialize markdown content
  md_lines <- c(
    "---",
    "title: \"FinnGen Register Data Summaries\"",
    glue::glue("date: \"{Sys.Date()}\""),
    "output: md_document",
    "---",
    "",
    "",
    glue::glue("# Data Summaries for {fg_bq_tables$environment} - {fg_bq_tables$dataFreeze}"),
    ""
  )
  
  # Iterate through each table
  for (table_name in names(fg_bq_tables$tbl)) {
    message("Processing table: ", table_name)
    md_lines <- c(md_lines, "", glue::glue("## {table_name}"), "")
    
    tbl_obj <- fg_bq_tables$tbl[[table_name]]
    
    # Check if table exists
    if (is.null(tbl_obj)) {
      md_lines <- c(md_lines, "*Table not available or connection failed.*", "")
      next
    }
    
    # Get basic stats
    tryCatch({
      # Count rows
      n_rows <- tbl_obj |> dplyr::tally() |> dplyr::collect() |> dplyr::pull(n)
      
      if (n_rows == 0) {
        md_lines <- c(md_lines, "*Table is empty (0 rows).*", "")
        next
      }
      
      md_lines <- c(md_lines, "### Basic Statistics", "")
      md_lines <- c(md_lines, glue::glue("- **Number of rows:** {format(n_rows, big.mark = ',')}"))
      
      # Try to find patient ID column
      col_names <- colnames(tbl_obj)
      id_col <- NULL
      if ("FINNGENID" %in% col_names) {
        id_col <- "FINNGENID"
      } else if ("MOTHER_FINNGENID" %in% col_names) {
        id_col <- "MOTHER_FINNGENID"
      }
      
      if (!is.null(id_col)) {
        n_patients <- tbl_obj |> 
          dplyr::summarise(n_distinct = dplyr::n_distinct(!!rlang::sym(id_col))) |>
          dplyr::collect() |>
          dplyr::pull(n_distinct)
        md_lines <- c(md_lines, glue::glue("- **Number of distinct patients:** {format(n_patients, big.mark = ',')}"))
      }
      
      # Find date columns
      date_cols <- col_names[grepl("DATE|_YEAR$|DELIVERY_YEAR", col_names, ignore.case = TRUE)]
      date_cols <- date_cols[!grepl("UPDATE|MODIFIED|CREATED", date_cols, ignore.case = TRUE)]
      
      if (length(date_cols) > 0) {
        for (date_col in date_cols[1:min(3, length(date_cols))]) {
          date_stats <- tbl_obj |>
            dplyr::summarise(
              min_date = min(!!rlang::sym(date_col), na.rm = TRUE),
              max_date = max(!!rlang::sym(date_col), na.rm = TRUE)
            ) |>
            dplyr::collect()
          
          if (!is.na(date_stats$min_date[[1]]) && !is.na(date_stats$max_date[[1]])) {
            md_lines <- c(
              md_lines,
              glue::glue("- **{date_col} range:** {date_stats$min_date} to {date_stats$max_date}")
            )
          }
        }
      }
      
      md_lines <- c(md_lines, "")
      
      # Detailed output
      if (detailedOutput) {
        md_lines <- c(md_lines, "### Column-Level Statistics", "")
        
        # Sample data to inspect column types
        sample_data <- tbl_obj |> head(1000) |> dplyr::collect()
        
        for (col in col_names) {
          col_data <- sample_data[[col]]
          col_class <- class(col_data)[1]
          
          md_lines <- c(md_lines, glue::glue("#### {col}"), "")
          md_lines <- c(md_lines, glue::glue("*Type: {col_class}*"), "")
          
          # Get distinct count
          distinct_count <- tbl_obj |>
            dplyr::summarise(n_distinct = dplyr::n_distinct(!!rlang::sym(col))) |>
            dplyr::collect() |>
            dplyr::pull(n_distinct)
          
          md_lines <- c(md_lines, glue::glue("- Distinct values: {format(distinct_count, big.mark = ',')}"))
          
          # Handle different column types
          if (col_class %in% c("character", "factor")) {
            # Categorical
            if (distinct_count <= 20) {
              freq_table <- tbl_obj |>
                dplyr::count(!!rlang::sym(col), sort = TRUE) |>
                head(20) |>
                dplyr::collect()
              
              if (nrow(freq_table) > 0) {
                md_lines <- c(md_lines, "", "| Value | Count |", "|-------|-------|")
                for (i in 1:nrow(freq_table)) {
                  val <- ifelse(is.na(freq_table[[col]][i]), "NA", as.character(freq_table[[col]][i]))
                  cnt <- format(freq_table$n[i], big.mark = ',')
                  md_lines <- c(md_lines, glue::glue("| {val} | {cnt} |"))
                }
              }
            }
          } else if (col_class %in% c("numeric", "integer", "double", "integer64")) {
            # Numeric
            stats <- tbl_obj |>
              dplyr::summarise(
                min_val = min(!!rlang::sym(col), na.rm = TRUE),
                max_val = max(!!rlang::sym(col), na.rm = TRUE),
                mean_val = mean(!!rlang::sym(col), na.rm = TRUE)
              ) |>
              dplyr::collect()
            
            if (!is.na(stats$min_val[[1]])) {
              md_lines <- c(
                md_lines,
                glue::glue("- Min: {round(stats$min_val[[1]], 2)}"),
                glue::glue("- Max: {round(stats$max_val[[1]], 2)}"),
                glue::glue("- Mean: {round(stats$mean_val[[1]], 2)}")
              )
            }
          } else if (col_class %in% c("Date", "POSIXct", "POSIXt")) {
            # Date
            date_stats <- tbl_obj |>
              dplyr::summarise(
                min_date = min(!!rlang::sym(col), na.rm = TRUE),
                max_date = max(!!rlang::sym(col), na.rm = TRUE)
              ) |>
              dplyr::collect()
            
            if (!is.na(date_stats$min_date[[1]])) {
              md_lines <- c(
                md_lines,
                glue::glue("- Min: {date_stats$min_date}"),
                glue::glue("- Max: {date_stats$max_date}")
              )
            }
          }
          
          md_lines <- c(md_lines, "")
        }
      }
      
    }, error = function(e) {
      md_lines <<- c(md_lines, glue::glue("*Error processing table: {e$message}*"), "")
    })
  }
  
  # Write to file
  writeLines(md_lines, output_path)
  message("Report written to: ", output_path)
  
  # Render to HTML and open in browser if requested
  if (render_html) {
    html_file <- rmarkdown::render(output_path, output_format = "html_document", quiet = TRUE)
    message("Opening HTML report in browser...")
    utils::browseURL(html_file)
    invisible(html_file)
  } else {
    invisible(output_path)
  }
}


#' Generate OMOP CDM Summaries Report
#'
#' @description
#' Creates a markdown report with summary statistics for OMOP CDM tables
#'
#' @param fg_bq_tables An fg_bq_tables object with CDM tables
#' @param output_path Path where the markdown file will be written. If NULL, creates a temp file, renders to HTML, and opens in browser.
#'
#' @return The path to the generated markdown file (invisibly)
#'
#' @importFrom checkmate assert_class assertString
#' @importFrom dplyr tally n_distinct summarise collect count left_join
#' @importFrom glue glue
#' @importFrom stats setNames
#'
#' @export
fg_omop_summaries <- function(
  fg_bq_tables,
  output_path = NULL
) {
  fg_bq_tables |> checkmate::assert_class('fg_bq_tables')
  if (!is.null(output_path)) output_path |> checkmate::assertString()
  
  # Create temp file if output_path is NULL
  render_html <- is.null(output_path)
  if (render_html) {
    output_path <- tempfile(fileext = ".md")
  }
  
  # Initialize markdown content
  md_lines <- c(
    "---",
    "title: \"FinnGen OMOP CDM Summaries\"",
    glue::glue("date: \"{Sys.Date()}\""),
    "output: md_document",
    "---",
    "",
    glue::glue("# OMOP CDM Summaries for {fg_bq_tables$environment} - {fg_bq_tables$dataFreeze}"),
    ""
  )
  
  # Overall OMOP Stats
  md_lines <- c(md_lines, "## Overall OMOP Statistics", "")
  
  tryCatch({
    # CDM Source information
    if (!is.null(fg_bq_tables$tbl$cdm_cdm_source)) {
      message("Getting CDM source information...")
      cdm_source <- fg_bq_tables$tbl$cdm_cdm_source |> 
        dplyr::collect()
      
      if (nrow(cdm_source) > 0) {
        md_lines <- c(md_lines, "### CDM Source Information", "")
        
        for (col in colnames(cdm_source)) {
          val <- cdm_source[[col]][1]
          if (!is.na(val)) {
            md_lines <- c(md_lines, glue::glue("- **{col}:** {val}"))
          }
        }
        md_lines <- c(md_lines, "")
      }
    }
    
    # Person statistics
    if (!is.null(fg_bq_tables$tbl$cdm_person)) {
      message("Getting person statistics...")
      
      # Total patients
      total_patients <- fg_bq_tables$tbl$cdm_person |>
        dplyr::tally() |>
        dplyr::collect() |>
        dplyr::pull(n)
      
      md_lines <- c(
        md_lines,
        "### Patient Statistics",
        "",
        glue::glue("- **Total number of patients:** {format(total_patients, big.mark = ',')}"),
        ""
      )
      
      # Patients by sex
      sex_stats <- fg_bq_tables$tbl$cdm_person |>
        dplyr::count(gender_concept_id) |>
        dplyr::left_join(
          fg_bq_tables$tbl$cdm_concept |> 
            dplyr::select(concept_id, concept_name),
          by = c("gender_concept_id" = "concept_id")
        ) |>
        dplyr::collect()
      
      if (nrow(sex_stats) > 0) {
        # Add sex names and sort alphabetically
        sex_stats <- sex_stats |>
          dplyr::mutate(
            sex_name = ifelse(
              is.na(concept_name),
              as.character(gender_concept_id),
              concept_name
            )
          ) |>
          dplyr::arrange(sex_name)
        
        md_lines <- c(md_lines, "**Patients by Sex:**", "", "| Count | Sex |", "|-------|-----|")
        for (i in 1:nrow(sex_stats)) {
          cnt <- format(sex_stats$n[i], big.mark = ',')
          md_lines <- c(md_lines, glue::glue("| {cnt} | {sex_stats$sex_name[i]} |"))
        }
        md_lines <- c(md_lines, "")
      }
    }
    
    # Vocabulary version
    if (!is.null(fg_bq_tables$tbl$cdm_vocabulary)) {
      message("Getting vocabulary information...")
      vocab_info <- fg_bq_tables$tbl$cdm_vocabulary |>
        dplyr::filter(vocabulary_id == "None") |>
        dplyr::collect()
      
      if (nrow(vocab_info) > 0) {
        md_lines <- c(
          md_lines,
          "### Vocabulary Information",
          "",
          glue::glue("- **Vocabulary version:** {vocab_info$vocabulary_version[1]}"),
          ""
        )
      }
    }
    
  }, error = function(e) {
    md_lines <<- c(md_lines, glue::glue("*Error getting overall statistics: {e$message}*"), "")
  })
  
  # Domain Tables Statistics
  domain_tables <- list(
    list(name = "Condition Occurrence", table_id = "cdm_condition_occurrence", id_col = "condition_occurrence_id", source_concept_col = "condition_source_concept_id"),
    list(name = "Drug Exposure", table_id = "cdm_drug_exposure", id_col = "drug_exposure_id", source_concept_col = "drug_source_concept_id"),
    list(name = "Procedure Occurrence", table_id = "cdm_procedure_occurrence", id_col = "procedure_occurrence_id", source_concept_col = "procedure_source_concept_id"),
    list(name = "Measurement", table_id = "cdm_measurement", id_col = "measurement_id", source_concept_col = "measurement_source_concept_id"),
    list(name = "Observation", table_id = "cdm_observation", id_col = "observation_id", source_concept_col = "observation_source_concept_id"),
    list(name = "Device Exposure", table_id = "cdm_device_exposure", id_col = "device_exposure_id", source_concept_col = "device_source_concept_id"),
    list(name = "Death", table_id = "cdm_death", id_col = "person_id", source_concept_col = "cause_source_concept_id")
  )
  
  for (domain in domain_tables) {
    md_lines <- c(md_lines, glue::glue("## {domain$name} Statistics"), "")
    
    tryCatch({
      if (!is.null(fg_bq_tables$tbl[[domain$table_id]])) {
        message(glue::glue("Getting {domain$name} statistics..."))
        
        # Total events
        total_events <- fg_bq_tables$tbl[[domain$table_id]] |>
          dplyr::tally() |>
          dplyr::collect() |>
          dplyr::pull(n)
        
        md_lines <- c(
          md_lines,
          glue::glue("- **Total number of events:** {format(total_events, big.mark = ',')}"),
          ""
        )
        
        # Total patients (for death table, just count distinct person_id)
        total_patients <- fg_bq_tables$tbl[[domain$table_id]] |>
          dplyr::summarise(n_patients = dplyr::n_distinct(person_id)) |>
          dplyr::collect() |>
          dplyr::pull(n_patients)
        
        md_lines <- c(
          md_lines,
          glue::glue("- **Total number of patients:** {format(total_patients, big.mark = ',')}"),
          ""
        )
        
        # Events by visit type (skip for death table)
        if (domain$table_id != "cdm_death" && !is.null(fg_bq_tables$tbl$cdm_visit_occurrence)) {
          message(glue::glue("Getting {domain$name} events stratified by visit type..."))
          
          visit_stats <- fg_bq_tables$tbl[[domain$table_id]] |>
            dplyr::left_join(
              fg_bq_tables$tbl$cdm_visit_occurrence |>
                dplyr::select(visit_occurrence_id, visit_source_concept_id),
              by = "visit_occurrence_id"
            ) |>
            dplyr::count(visit_source_concept_id) |>
            dplyr::left_join(
              fg_bq_tables$tbl$cdm_concept |>
                dplyr::select(concept_id, concept_name),
              by = c("visit_source_concept_id" = "concept_id")
            ) |>
            dplyr::collect()
          
          if (nrow(visit_stats) > 0) {
            # Add visit names and extract prefix for grouping
            visit_stats <- visit_stats |>
              dplyr::mutate(
                visit_name = ifelse(
                  is.na(concept_name),
                  as.character(visit_source_concept_id),
                  concept_name
                ),
                visit_prefix = ifelse(
                  grepl(" - ", visit_name),
                  sub(" - .*", "", visit_name),
                  visit_name
                )
              ) |>
              dplyr::group_by(visit_prefix) |>
              dplyr::summarise(n = sum(n), .groups = "drop") |>
              dplyr::arrange(desc(n))
            
            md_lines <- c(
              md_lines,
              "**Events Stratified by Visit Type (Source Concept):**",
              "",
              "| Count | Visit Type |",
              "|-------|------------|"
            )
            
            for (i in 1:nrow(visit_stats)) {
              cnt <- format(visit_stats$n[i], big.mark = ',')
              md_lines <- c(md_lines, glue::glue("| {cnt} | {visit_stats$visit_prefix[i]} |"))
            }
            md_lines <- c(md_lines, "")
          }
        }
        
        # Events by vocabulary
        if (!is.null(fg_bq_tables$tbl$cdm_concept) && !is.null(fg_bq_tables$tbl$cdm_vocabulary)) {
          message(glue::glue("Getting {domain$name} events stratified by vocabulary..."))
          
          vocab_stats <- fg_bq_tables$tbl[[domain$table_id]] |>
            dplyr::left_join(
              fg_bq_tables$tbl$cdm_concept |>
                dplyr::select(concept_id, vocabulary_id, concept_class_id),
              by = setNames("concept_id", domain$source_concept_col)
            ) |>
            dplyr::count(vocabulary_id, concept_class_id) |>
            dplyr::collect()
          
          # Join with vocabulary table only for non-NA vocabulary_id
          vocab_stats <- vocab_stats |>
            dplyr::left_join(
              fg_bq_tables$tbl$cdm_vocabulary |>
                dplyr::select(vocabulary_id, vocabulary_name) |>
                dplyr::collect(),
              by = "vocabulary_id"
            )
          
          if (nrow(vocab_stats) > 0) {
            # For FGVisitType, create vocab_id with concept_class, for others group by vocab
            vocab_stats <- vocab_stats |>
              dplyr::mutate(
                display_vocab_id = ifelse(
                  vocabulary_id == "FGVisitType" & !is.na(concept_class_id),
                  paste0("FGVisitType:", concept_class_id),
                  vocabulary_id
                )
              ) |>
              dplyr::group_by(display_vocab_id, vocabulary_id, vocabulary_name) |>
              dplyr::summarise(n = sum(n), .groups = "drop") |>
              dplyr::arrange(desc(n))
            
            md_lines <- c(
              md_lines,
              "**Events Stratified by Vocabulary:**",
              "",
              "| Count | Vocabulary ID | Vocabulary Name |",
              "|-------|---------------|-----------------|"
            )
            
            for (i in 1:nrow(vocab_stats)) {
              vocab_id <- ifelse(
                is.na(vocab_stats$vocabulary_id[i]),
                "NA",
                as.character(vocab_stats$display_vocab_id[i])
              )
              vocab_name <- ifelse(
                is.na(vocab_stats$vocabulary_id[i]),
                "Missing codes",
                ifelse(
                  is.na(vocab_stats$vocabulary_name[i]),
                  "",
                  vocab_stats$vocabulary_name[i]
                )
              )
              cnt <- format(vocab_stats$n[i], big.mark = ',')
              md_lines <- c(md_lines, glue::glue("| {cnt} | {vocab_id} | {vocab_name} |"))
            }
            md_lines <- c(md_lines, "")
          }
        }
        
      } else {
        md_lines <- c(md_lines, glue::glue("*{domain$name} table not available.*"), "")
      }
      
    }, error = function(e) {
      md_lines <<- c(md_lines, glue::glue("*Error getting {domain$name} statistics: {e$message}*"), "")
    })
  }
  
  # Write to file
  writeLines(md_lines, output_path)
  message("Report written to: ", output_path)
  
  # Render to HTML and open in browser if requested
  if (render_html) {
    html_file <- rmarkdown::render(output_path, output_format = "html_document", quiet = TRUE)
    message("Opening HTML report in browser...")
    utils::browseURL(html_file)
    invisible(html_file)
  } else {
    invisible(output_path)
  }
}