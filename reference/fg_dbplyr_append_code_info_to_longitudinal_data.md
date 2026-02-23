# fg_dbplyr_append_code_info_to_longitudinal_data

Wrap around fg_append_code_info_to_longitudinal_data_sql to work with
dbplyr package

## Usage

``` r
fg_dbplyr_append_code_info_to_longitudinal_data(
  dbplyr_table,
  fg_bq_tables,
  ...
)
```

## Arguments

- dbplyr_table:

  an object of type representing a table in longitudinal_data format

- fg_bq_tables:

  an object of type \<fg_bq_tables\> with the connections to the
  bigquery tables. The function will use the connection to the bigquery
  project and the path to fg_codes_info_table to run the query generated
  by `fg_append_code_info_to_longitudinal_data_sql`

- ...:

  see
  [fg_append_code_info_to_longitudinal_data_sql](https://finngen.github.io/FinnGenUtilsR/reference/fg_append_code_info_to_longitudinal_data_sql)
  for the mapping options

## Value

with added columns
