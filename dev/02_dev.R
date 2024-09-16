#
###################################
#### CURRENT FILE: DEV SCRIPT #####
###################################

## Add one line by package you want to add as dependency
usethis::use_package( "checkmate")
usethis::use_package( "bigrquery")
usethis::use_package( "SqlRender")


usethis::use_package( "dplyr", type = "Suggests" )
usethis::use_package( "stringr", type = "Suggests" )
usethis::use_package( "tibble", type = "Suggests" )
usethis::use_package( "lubridate", type = "Suggests" )
usethis::use_package( "readr", type = "Suggests" )



## Add functions
usethis::use_r("fg_append_code_info_to_longitudinal_data")
usethis::use_r("fg_append_service_sector_info_to_service_sector_data")
usethis::use_r("fg_append_specialtiy_info_to_service_sector_data")
usethis::use_r("fg_fg_get_cdm_config")

## Add internal datasets ----
## If you have data in your package
# usethis::use_data_raw( name = "test_data", open = FALSE )

## Tests ----
## Add one line by test you want to create
usethis::use_testthat()
usethis::use_test( "fg_append_code_info_to_longitudinal_data")
usethis::use_test( "fg_append_service_sector_info_to_service_sector_data")
usethis::use_test("fg_fg_get_cdm_config")

# Documentation

## Vignette ----
usethis::use_vignette("tutorial_add_info")
usethis::use_vignette("tutorial_using_omop_cdm")

#usethis::use_pkgdown()

## Code coverage ----
## (You'll need GitHub there)
#usethis::use_github()
#usethis::use_travis()
#usethis::use_appveyor()

# Compute the code coverage of your application
#covr::package_coverage()




