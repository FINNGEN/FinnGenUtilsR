########################################
#### CURRENT FILE: ON START SCRIPT #####
########################################

## Fill the DESCRIPTION ----
usethis::use_description(
  fields = list(
    Title = "FinnGenTableTypes",
    Description = "Functions validate, transform, and operate tables used in FinnGen",
    `Authors@R` = 'person("Javier", "Gracia-Tabuenca", email = "javier.graciatabuenca@tuni.fi",
                          role = c("aut", "cre"),
                          comment = c(ORCID = "YOUR-ORCID-ID"))',
    License = "none",
    Language =  "en"
  )
)


usethis::use_readme_md()


usethis::use_git()
#usethis::use_github(organisation = "FINNGEN", private = TRUE)
