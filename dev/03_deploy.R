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


# increase version
usethis::use_version()




pkgdown::build_site(new_process = FALSE)

#rhub::check_for_cran()
gert::git_commit_all("Version 2.0.0 ready");gert::git_push()
