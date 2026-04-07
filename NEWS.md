# FinnGenUtilsR 4.0.3
- Updates GWAS to run from standard API
- Other fixes after production checked

# FinnGenUtilsR 4.0.0
- Refactor: Now we use an fg_table R6 object that finds automatically the connection parameters, last datafreeze and last table versions, or a specific datafreeze if needed.
- fg_table provides a dbplyr interface to the BQ tables to seemingly use them as tibbles.
- Raw SQL queries can still be executed using the fg_table object.
- All appending name functions now work for fg_table.


# FinnGenUtilsR 3.1.3
- Improvement: Allow lower case and underscores for custom gwas phenotype names

# FinnGenUtilsR 3.1.2
- hot fix: change in sandbox API name and notification email
  
# FinnGenUtilsR 3.1.1
- hot fix: `fg_append_visit_type_info_to_service_sector_data_sql` error with large data

# FinnGenUtilsR 3.1.0
- `fg_append_visit_type_info_to_service_sector_data_sql` now adds two columns to the data: `is_clinic_visit` and `is_follow_up_visit`
- new functions to append the omop lab test name to the Kanta data. See examples in the vignettes. 

# FinnGenUtilsR 3.0.0
- Make package compatible with Sandbox local CRAN
- Added functions to add info to longitudinal data using dbplyr
- Added tutorial to work with FGconnectionHandler and dbplyr
- Added Github actions to r-check the package every week with latest dependencies

# FinnGenUtilsR 2.2.1
- Fix bug in fg_get_bq_config

# FinnGenUtilsR 2.2.0
- Added `FGconnectionHandler` and `fg_get_bq_config()` to connect and work with to FinnGen BQ databases as data frames 

# FinnGenUtilsR 2.1.0
- Added `fg_get_cdm_config` function and "Tutorial using OMOP-CDM" vignette

# FinnGenUtilsR 2.0.1

- fg_bq_append_xxx functions pass extra parameters to bq_project_query, (e.g  allows to pass quiet=TRUE)

# FinnGenUtilsR 2.0.0

- Added function to name visit type in service sector data
- Added function to name provider in service sector data


# FinnGenUtilsR 1.0.0

- Created with only function `fg_append_code_info_to_longitudinal_data_sql`
