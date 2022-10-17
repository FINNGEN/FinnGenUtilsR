#
###################################
#### CURRENT FILE: DEV SCRIPT #####
###################################

# Engineering

## Dependencies ----
usethis::use_pipe()
usethis::use_tibble()

## Add one line by package you want to add as dependency
usethis::use_package( "dplyr" )
usethis::use_package( "tidyr" )
usethis::use_package( "stringr")
usethis::use_package( "tibble")
usethis::use_package( "purrr")
usethis::use_package( "readr")
usethis::use_package( "lubridate")
usethis::use_package( "janitor")
usethis::use_package( "apexcharter")
usethis::use_package( "forcats")
usethis::use_package( "ggupset")
usethis::use_package( "ggplot2")
usethis::use_package( "checkmate")

usethis::use_package( "vdiffr", type = "Suggest")



## Add functions
usethis::use_r("data")
usethis::use_r("cohortData_table")
usethis::use_r("cohortData_operations")
usethis::use_r("summarise_cohortData")
usethis::use_r("plot_upset_cohortsOverlap")
usethis::use_r("table_summarycohortData")
usethis::use_r("plot_cohortData_comparison")


## Add internal datasets ----
## If you have data in your package
usethis::use_data_raw( name = "test_data", open = FALSE )

## Tests ----
## Add one line by test you want to create
usethis::use_testthat()
usethis::use_test( "as_cohortData" )
usethis::use_test( "is_cohortData" )
usethis::use_test( "bind_cohortData" )
usethis::use_test( "cohortData_union" )
usethis::use_test( "bracketNotClosed" )
usethis::use_test("summarise_cohortData")
usethis::use_test("plot_upset_cohortData")
usethis::use_test("table_summarycohortData")

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




