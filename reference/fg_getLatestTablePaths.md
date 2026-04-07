# Get Latest Table Paths

Get Latest Table Paths

## Usage

``` r
fg_getLatestTablePaths(
  connection,
  dataFreeze,
  skipDataFreezeValidation = FALSE,
  tablesGroup = "register"
)
```

## Arguments

- connection:

  BigQuery connection object

- dataFreeze:

  Data freeze identifier

- skipDataFreezeValidation:

  Whether to skip data freeze validation

- tablesGroup:

  Table group to include: 'register' (default), 'cdm', or
  'register_and_cdm'

## Value

Tibble with table_id and full_path columns
