# fg_append_visit_type_info_to_service_sector_data_sql

fg_append_visit_type_info_to_service_sector_data_sql

## Usage

``` r
fg_append_visit_type_info_to_service_sector_data_sql(
  service_sector_data_table,
  fg_codes_info_table,
  prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = TRUE,
  add_is_clinic_visist = TRUE,
  add_is_follow_up_visit = TRUE,
  new_colums_sufix = ""
)
```

## Arguments

- service_sector_data_table:

  full path to the table in longitudinal_data format

- fg_codes_info_table:

  full path to the table with the codes info

- prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector:

  Some hilmo visits are including both coding systems,
  SRC\|ServiceSector and SRC\|Contact\|Urgency, if TRUE the second is
  used

- add_is_clinic_visist:

  add a column indicating if the visit is a clinic visit

- add_is_follow_up_visit:

  add a column indicating if the visit is a follow up visit

- new_colums_sufix:

  string indicating a prefix to add to the appended columns, default="".

## Value

sql script ready to be ran
