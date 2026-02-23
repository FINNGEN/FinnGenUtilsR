# fg_append_provider_info_to_service_sector_data_sql

fg_append_provider_info_to_service_sector_data_sql

## Usage

``` r
fg_append_provider_info_to_service_sector_data_sql(
  service_sector_data_table,
  fg_codes_info_table,
  new_colums_sufix = ""
)
```

## Arguments

- service_sector_data_table:

  full path to the table in service_sector_data format

- fg_codes_info_table:

  full path to the table with the codes info

- new_colums_sufix:

  string indicating a prefix to add to the appended columns, default="".

## Value

sql script ready to be ran
