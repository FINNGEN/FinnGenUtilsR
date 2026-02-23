# fg_append_concept_info_data_sql

fg_append_concept_info_data_sql

## Usage

``` r
fg_append_concept_info_data_sql(data_table, omop_schema, new_colums_sufix = "")
```

## Arguments

- data_table:

  string with the full path (project.schema.table) to the bq table with
  the data

- omop_schema:

  string with the schema where the omop tables are stored

- new_colums_sufix:

  string indicating a prefix to add to the appended columns, default="".

## Value

sql script ready to be ran
