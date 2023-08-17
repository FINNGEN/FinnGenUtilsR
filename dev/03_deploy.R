######################################
#### CURRENT FILE: DEPLOY SCRIPT #####
######################################

# Test your app

## Run checks ----
## Check the package before sending to prod
devtools::check()

#
options(rmarkdown.html_vignette.check_title = FALSE)
knitr::knit("vignettes/tutorial_add_info.Rmd.orig", output = "vignettes/tutorial_add_info.Rmd")
devtools::build_rmd("vignettes/tutorial_add_info.Rmd")
browseURL("vignettes/tutorial_add_info.html")

knitr::knit("vignettes/tutorial_using_omop_cdm.Rmd.orig", output = "vignettes/tutorial_using_omop_cdm.Rmd")
devtools::build_rmd("vignettes/tutorial_using_omop_cdm.Rmd")
browseURL("vignettes/tutorial_using_omop_cdm.html")
# increase version




pkgdown::build_site(new_process = FALSE)

#rhub::check_for_cran()
usethis::use_version()

gert::git_push()
