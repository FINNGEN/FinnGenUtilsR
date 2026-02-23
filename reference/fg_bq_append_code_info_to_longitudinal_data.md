# fg_bq_append_code_info_to_longitudinal_data

Wrap around fg_append_code_info_to_longitudinal_data_sql to work with
bigrquery package

## Usage

``` r
fg_bq_append_code_info_to_longitudinal_data(
  bq_project_id,
  bq_table,
  fg_codes_info_table,
  ...
)
```

## Arguments

- bq_project_id:

  string with the bigquery project id

- bq_table:

  an object of type \<bq_table\> with a table in longitudinal_data
  format

- fg_codes_info_table:

  string with the full path (project.schema.table) to the bq table with
  the fg_codes_info

- ...:

  see
  [fg_append_code_info_to_longitudinal_data_sql](https://finngen.github.io/FinnGenUtilsR/reference/fg_append_code_info_to_longitudinal_data_sql)
  for the mapping options

## Value

bq_table with added columns
