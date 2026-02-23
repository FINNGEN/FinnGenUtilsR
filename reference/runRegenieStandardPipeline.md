# runRegenieStandardPipeline

Submit the Regenie unmodifiable standard pipeline via internal
standard-pipelines API. Creates phenotype + description files locally,
uploads them to SANDBOX_RED/CO2_temp//\<run_tag\>/ (using RED_BUCKET for
gsutil), builds WDL-style input JSON referencing SANDBOX_RED paths, and
submits the workflow. Users are allowed to add additional covariates
using a dataframe of columns for each additional covariate.

## Usage

``` r
runRegenieStandardPipeline(
  connection_sandboxAPI,
  standard_pipeline_id = "5718330904150016",
  cases_finngenids,
  controls_finngenids,
  phenotype_name,
  phenotype_description,
  covariates =
    "SEX_IMPUTED,AGE_AT_DEATH_OR_END_OF_FOLLOWUP,PC{1:10},IS_FINNGEN2_CHIP,BATCH_DS1_BOTNIA_Dgi_norm,BATCH_DS10_FINRISK_Palotie_norm,BATCH_DS11_FINRISK_PredictCVD_COROGENE_Tarto_norm,BATCH_DS12_FINRISK_Summit_norm,BATCH_DS13_FINRISK_Bf_norm,BATCH_DS14_GENERISK_norm,BATCH_DS15_H2000_Broad_norm,BATCH_DS16_H2000_Fimm_norm,BATCH_DS17_H2000_Genmets_norm_relift,BATCH_DS18_MIGRAINE_1_norm_relift,BATCH_DS19_MIGRAINE_2_norm,BATCH_DS2_BOTNIA_T2dgo_norm,BATCH_DS20_SUPER_1_norm_relift,BATCH_DS21_SUPER_2_norm_relift,BATCH_DS22_TWINS_1_norm,BATCH_DS23_TWINS_2_norm_nosymmetric,BATCH_DS24_SUPER_3_norm,BATCH_DS25_BOTNIA_Regeneron_norm,BATCH_DS26_DIREVA_norm,BATCH_DS27_NFBC66_norm,BATCH_DS28_NFBC86_norm,BATCH_DS3_COROGENE_Sanger_norm,BATCH_DS4_FINRISK_Corogene_norm,BATCH_DS5_FINRISK_Engage_norm,BATCH_DS6_FINRISK_FR02_Broad_norm_relift,BATCH_DS7_FINRISK_FR12_norm,BATCH_DS8_FINRISK_Finpcga_norm,BATCH_DS9_FINRISK_Mrpred_norm",
  extra_covariates_df = NULL,
  test = "additive",
  is_binary = "true",
  endpoint_path = "v2/standard-pipelines",
  timeout_sec = 300
)
```

## Arguments

- connection_sandboxAPI:

  List-like object containing base_url, token, conn_status_tibble

- standard_pipeline_id:

  Standard pipeline id of the pipeline to be used

- cases_finngenids:

  Character vector of FINNGENIDs for cases

- controls_finngenids:

  Character vector of FINNGENIDs for controls

- phenotype_name:

  Phenotype column name (must start with a letter; letters/numbers/\_)

- phenotype_description:

  Single string description written to phenodescription file (1 line)

- covariates:

  Optional comma-separated covariate string of the standard FinnGen
  covariates

- extra_covariates_df:

  data.frame with FID/IID + extra covariate columns

- test:

  Genetic model test string, Default: "additive"

- is_binary:

  String "true"/"false" to specify binary or quantitative GWAS analysis
  type, Default: "true"

- endpoint_path:

  internal API path, Default: "v2/standard-pipelines"

- timeout_sec:

  httr timeout seconds, Default: 300

## Value

list(status, http_status, workflow_id, content, temp_files,
sandbox_paths_used, upload_logs)
