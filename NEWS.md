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
