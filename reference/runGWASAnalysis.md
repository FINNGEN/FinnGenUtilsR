# runGWASAnalysis

runGWASAnalysis

## Usage

``` r
runGWASAnalysis(
  connection_sandboxAPI,
  cases_finngenids,
  controls_finngenids,
  phenotype_name,
  title = phenotype_name,
  description = phenotype_name,
  notification_email = connection_sandboxAPI$notification_email,
  analysis_type = "additive",
  release = "Regenie12"
)
```

## Arguments

- connection_sandboxAPI:

  PARAM_DESCRIPTION

- cases_finngenids:

  PARAM_DESCRIPTION

- controls_finngenids:

  PARAM_DESCRIPTION

- phenotype_name:

  PARAM_DESCRIPTION

- title:

  PARAM_DESCRIPTION, Default: phenotype_name

- description:

  PARAM_DESCRIPTION, Default: phenotype_name

- notification_email:

  PARAM_DESCRIPTION, Default: connection_sandboxAPI\$notification_email

- analysis_type:

  Specifies type of the analysis to perform (additive, recessive,
  dominant), Default: 'additive'

- release:

  PARAM_DESCRIPTION, Default: 'Regenie12'
