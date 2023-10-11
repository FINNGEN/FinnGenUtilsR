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


knitr::knit("vignettes/tutorial_connection_handler.Rmd.orig", output = "vignettes/tutorial_connection_handler.Rmd")
devtools::build_rmd("vignettes/tutorial_connection_handler.Rmd")
browseURL("vignettes/tutorial_connection_handler.html")
# increase version



#rhub::check_for_cran()
usethis::use_version()

pkgdown::build_site(new_process = FALSE)

gert::git_push()
