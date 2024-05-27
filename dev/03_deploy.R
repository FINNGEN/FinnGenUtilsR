######################################
#### CURRENT FILE: DEPLOY SCRIPT #####
######################################

# Set up

## Run checks ----
## Check the package before sending to prod
devtools::check()


#rhub::check_for_cran()
usethis::use_version()

usethis

gert::git_push()
