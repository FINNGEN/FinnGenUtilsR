########################################
#### CURRENT FILE: ON START SCRIPT #####
########################################


## activate renv and install usethis
renv::activate()
renv::install("usethis")
renv::install("devtools")


## Fill the DESCRIPTION ----
usethis::use_description(
  fields = list(
    Title = "FinnGenUtilsR",
    Description = "Usefull functions in R to work with FinnGen data",
    `Authors@R` = 'person("Javier", "Gracia-Tabuenca", email = "javier.graciatabuenca@tuni.fi",
                          role = c("aut", "cre"),
                          comment = c(ORCID = "0000-0002-2455-0598"))',
    Language =  "en"
  )
)
usethis::use_mit_license()


# Set up common files
usethis::use_readme_md()
usethis::use_news_md()
usethis::use_pkgdown_github_pages()


## Set up Github
usethis::use_git()
usethis::use_github(organisation = "FINNGEN", private = TRUE)



usethis::use_pkgdown_github_pages()
