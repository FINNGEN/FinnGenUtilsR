# Get Latest Table Paths

Get Latest Table Paths

## Usage

``` r
fg_getLatestTablePaths(
  connection,
  dataFreeze,
  skipDataFreezeValidation = FALSE
)
```

## Arguments

- connection:

  BigQuery connection object

- dataFreeze:

  Data freeze identifier

- skipDataFreezeValidation:

  Whether to skip data freeze validation

## Value

Tibble with table_id and full_path columns
