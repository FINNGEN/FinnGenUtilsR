######################################
#### CURRENT FILE: DEPLOY SCRIPT #####
######################################

# Test your app

## Run checks ----
## Check the package before sending to prod
devtools::check()
devtools::build()
#rhub::check_for_cran()
