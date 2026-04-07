# Generate OMOP CDM Summaries Report

Creates a markdown report with summary statistics for OMOP CDM tables

## Usage

``` r
fg_omop_summaries(fg_bq_tables, output_path = NULL)
```

## Arguments

- fg_bq_tables:

  An fg_bq_tables object with CDM tables

- output_path:

  Path where the markdown file will be written. If NULL, creates a temp
  file, renders to HTML, and opens in browser.

## Value

The path to the generated markdown file (invisibly)
