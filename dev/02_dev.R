#
###################################
#### CURRENT FILE: DEV SCRIPT #####
###################################

renv::init()

## Add one line by package you want to add as dependency
usethis::use_package( "dplyr" )
usethis::use_package( "tidyr" )
usethis::use_package( "stringr")
usethis::use_package( "tibble")
usethis::use_package( "purrr")
usethis::use_package( "readr")
usethis::use_package( "lubridate")
usethis::use_package( "ggplot2")
usethis::use_package( "checkmate")
usethis::use_package( "bigrquery")


## Add functions
usethis::use_r("fg_append_code_info_to_longitudinal_data")

## Add internal datasets ----
## If you have data in your package
# usethis::use_data_raw( name = "test_data", open = FALSE )

## Tests ----
## Add one line by test you want to create
usethis::use_testthat()
usethis::use_test( "fg_append_code_info_to_longitudinal_data")

# Documentation

## Vignette ----
#usethis::use_vignette("connection_tutorial")
#usethis::use_vignette("tutorial")
#devtools::build_vignettes()

#usethis::use_pkgdown()

## Code coverage ----
## (You'll need GitHub there)
#usethis::use_github()
#usethis::use_travis()
#usethis::use_appveyor()

# Compute the code coverage of your application
covr::package_coverage()

# You're now set! ----
# go to dev/03_deploy.R
rstudioapi::navigateToFile("dev/03_deploy.R")




