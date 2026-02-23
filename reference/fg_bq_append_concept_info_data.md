# fg_bq_append_concept_info_data

Wrap around fg_bq_append_concept_info_data_sql to work with bigrquery
package

## Usage

``` r
fg_bq_append_concept_info_data(bq_project_id, bq_table, omop_schema, ...)
```

## Arguments

- bq_project_id:

  string with the bigquery project id

- bq_table:

  an object of type \<bq_table\> with a table in longitudinal_data
  format

- omop_schema:

  string with the schema where the omop tables are stored

- ...:

  see `fg_append_concept_info_data_sql` for the mapping options

## Value

bq_table with added columns
