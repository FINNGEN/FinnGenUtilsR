# Generate Data Summaries Report for FinnGen Register Data

Creates an R Markdown report with summary statistics for each table in
fg_bq_tables

## Usage

``` r
fg_register_data_summaries(
  fg_bq_tables,
  output_path = NULL,
  detailedOutput = FALSE,
  tables_list = NULL
)
```

## Arguments

- fg_bq_tables:

  An fg_bq_tables object

- output_path:

  Path where the R Markdown file will be written. If NULL, creates a
  temp file, renders to HTML, and opens in browser.

- detailedOutput:

  Logical flag to include detailed column-level statistics (default:
  FALSE)

- tables_list:

  Vector of table names to process. If NULL (default), processes all
  tables in fg_bq_tables.

## Value

The path to the generated R Markdown file (invisibly)
