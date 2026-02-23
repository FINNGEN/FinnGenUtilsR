# fg_dbplyr_append_provider_info_to_service_sector_data

Wrap around fg_append_provider_info_to_service_sector_data_sql to work
with dbplyr package

## Usage

``` r
fg_dbplyr_append_provider_info_to_service_sector_data(
  dbplyr_table,
  fg_bq_tables,
  ...
)
```

## Arguments

- dbplyr_table:

  an object of type representing a table in longitudinal_data format

- fg_bq_tables:

  an object of type \<fg_bq_tables\> containing the fg_codes_info table

- ...:

  see
  [fg_append_code_info_to_longitudinal_data_sql](https://finngen.github.io/FinnGenUtilsR/reference/fg_append_code_info_to_longitudinal_data_sql)
  for the mapping options

## Value

with added columns
