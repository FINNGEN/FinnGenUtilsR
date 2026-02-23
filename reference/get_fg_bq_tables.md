# Get FinnGen BigQuery Tables

Creates a new fg_bq_tables object

## Usage

``` r
get_fg_bq_tables(environment, dataFreeze = NULL, tablesPathsTibble = NULL)
```

## Arguments

- environment:

  Environment identifier (e.g., "build", "prod")

- dataFreeze:

  (Optional) Data freeze identifier (default is NULL)

- tablesPathsTibble:

  (Optional) Tibble containing table paths (default is NULL)

## Value

An fg_bq_tables R6 object
