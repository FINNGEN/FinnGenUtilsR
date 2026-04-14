# Adding Names to Kanta Lab Data

## Intro

This tutorial demonstrates how to work with Kanta laboratory data using
the `FinnGenUtilsR` package. The Kanta lab data contains laboratory
measurements with OMOP concept mappings, and this tutorial shows how to
append human-readable names to these OMOP concept IDs.

To understand what the `fgbq` object is, see the dedicated vignette
`tutorial_fgbq`.

## Set up

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(FinnGenUtilsR)
```

Connect to the latest versions of BigQuery tables using
[`get_fg_bq_tables()`](https://finngen.github.io/FinnGenUtilsR/reference/get_fg_bq_tables.md).
Remember to change the environment to your sandbox, or set other data
freeze versions if needed (see `tutorial_fgbq` vignette for more
details).

``` r
fgbq <- get_fg_bq_tables(
  environment = "sandbox-XX"
)
#> Connecting to BigQuery...
#> Using data freeze: dev
#> Finding latest table versions...
#>   - birth_mother: sandbox_tools_dev.birth_mother_dev_dev
#>   - code_prevalence_stratified: sandbox_tools_dev.code_prevalence_stratified_dev_dev
#>   - covariates: sandbox_tools_dev.covariates_dev_dev
#>   - drug_events: sandbox_tools_dev.drug_events_dev_dev
#>   - endpoint_cohorts: sandbox_tools_dev.endpoint_cohorts_dev_dev
#>   - fg_codes_info: medical_codes.fg_codes_info_dev
#>   - finngen_vnrs: medical_codes.finngen_vnr_dev
#>   - hla_imputed: sandbox_tools_dev.hla_imputed_dev_dev
#>   - kanta: sandbox_tools_dev.kanta_dev_dev
#>   - kidney: sandbox_tools_dev.kidney_dev_dev
#>   - minimum_extended: sandbox_tools_dev.minimum_extended_dev_dev
#>   - plasma_samples: sandbox_tools_dev.plasma_samples_dev_dev
#>   - service_sector_detailed_longitudinal: sandbox_tools_dev.finngen_dev_service_sector_detailed_longitudinal
#>   - spirometry: sandbox_tools_dev.spirometry_dev_dev
#>   - vaccination: sandbox_tools_dev.vaccination_dev_dev
#>   - vision: sandbox_tools_dev.vision_dev_dev
#>   - cdm_concept: finngen_omop_dev_dev.concept
#> Creating table connections (this may take a moment)...
#> Successfully connected to all 17 tables in 7.49 seconds
```

We can access the Kanta lab data using the `fgbq` object as follows:

``` r
fgbq$tbl$kanta |> 
  glimpse()
#> Rows: ??
#> Columns: 21
#> Database: BigQueryConnection
#> $ FINNGENID                    <chr> "FG00000034", "FG00000035", "FG00000069",…
#> $ EVENT_AGE                    <dbl> 65.718, 82.712, 66.375, 64.734, 90.995, 8…
#> $ APPROX_EVENT_DATETIME        <dttm> 2022-03-17 07:55:00, 2022-08-30 09:58:00…
#> $ TEST_NAME                    <chr> "na", "na", "na", "na", "na", "na", "na",…
#> $ TEST_ID                      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ OMOP_CONCEPT_ID              <int64> -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,…
#> $ MEASUREMENT_VALUE            <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ MEASUREMENT_UNIT             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ MEASUREMENT_VALUE_HARMONIZED <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ MEASUREMENT_UNIT_HARMONIZED  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ MEASUREMENT_VALUE_EXTRACTED  <dbl> NA, NA, NA, NA, 0.998700, 2.189545, NA, 2…
#> $ MEASUREMENT_VALUE_MERGED     <dbl> NA, NA, NA, NA, 0.998700, 2.189545, NA, 2…
#> $ TEST_OUTCOME                 <chr> "N", NA, NA, "L", "A", NA, NA, NA, NA, NA…
#> $ MEASUREMENT_STATUS           <chr> "F", "F", "F", "F", "F", NA, "F", "F", "F…
#> $ REFERENCE_RANGE_LOW_VALUE    <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ REFERENCE_RANGE_HIGH_VALUE   <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ CODING_SYSTEM_OID            <chr> "Helsinki_13010", "Seinäjoki_601", "Helsi…
#> $ TEST_ID_SOURCE               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TEST_NAME_SOURCE             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ MEASUREMENT_VALUE_SOURCE     <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ MEASUREMENT_UNIT_SOURCE      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
```

## Generate a table for analysis

For example we create a subset of the main Kanta table by querying
latest events from subject “FG00000001”:

``` r
kanta_subject_1_tbl <- fgbq$tbl$kanta |> 
  filter(FINNGENID == "FG00000001") |> 
  arrange(desc(APPROX_EVENT_DATETIME)) 
```

We can see that this table contains OMOP_CONCEPT_ID but not the names of
the concepts:

``` r
kanta_subject_1_tbl |> 
  select(FINNGENID, EVENT_AGE, APPROX_EVENT_DATETIME, TEST_NAME, TEST_ID, OMOP_CONCEPT_ID) |> 
  glimpse()
#> Rows: ??
#> Columns: 6
#> Database: BigQueryConnection
#> Ordered by: desc(APPROX_EVENT_DATETIME)
#> $ FINNGENID             <chr> "FG00000001", "FG00000001", "FG00000001", "FG000…
#> $ EVENT_AGE             <dbl> 71.718, 71.627, 71.578, 71.573, 71.510, 71.482, …
#> $ APPROX_EVENT_DATETIME <dttm> 2022-12-07 12:07:00, 2022-11-04 16:18:00, 2022-…
#> $ TEST_NAME             <chr> "pt-gfre", "p-crp", "b-trom", "e-mchc", "e-mchc"…
#> $ TEST_ID               <chr> "656400", "1605013", "3002791", "1557", "1557", …
#> $ OMOP_CONCEPT_ID       <int64> -1, 3020460, 3007461, 3003338, 3003338, 301643…
```

### Adding info to OMOP_CONCEPT_ID codes

Function `fg_dbplyr_append_code_info_to_kanta_data` adds a new column
with information about the OMOP_CONCEPT_ID name.

``` r
kanta_subject_1_tbl_with_omop_name <- kanta_subject_1_tbl |> 
   fg_dbplyr_append_code_info_to_kanta_data(fg_bq_tables = fgbq)
```

``` r
kanta_subject_1_tbl_with_omop_name |>  
  dplyr::select(FINNGENID, EVENT_AGE, APPROX_EVENT_DATETIME, TEST_NAME, TEST_ID, OMOP_CONCEPT_ID, concept_name) |> 
  glimpse()
#> Rows: ??
#> Warning: ORDER BY is ignored in subqueries without LIMIT
#> ℹ Do you need to move arrange() later in the pipeline or use window_order() instead?
#> Columns: 7
#> Database: BigQueryConnection
#> Ordered by: desc(APPROX_EVENT_DATETIME)
#> $ FINNGENID             <chr> "FG00000001", "FG00000001", "FG00000001", "FG000…
#> $ EVENT_AGE             <dbl> 71.482, 66.981, 71.241, 66.493, 64.727, 66.616, …
#> $ APPROX_EVENT_DATETIME <dttm> 2022-09-12 12:03:00, 2018-03-13 10:46:00, 2022-…
#> $ TEST_NAME             <chr> "s-ca-ion", "p-k", "p-k", "ab-hbo2", "p-hs-crp",…
#> $ TEST_ID               <chr> "9010", "1999", "1999", "3240", "50435", "689", …
#> $ OMOP_CONCEPT_ID       <int64> 3016431, 3023103, 3023103, 3014007, 3010156, 3…
#> $ concept_name          <chr> "Calcium.ionized [Moles/volume] adjusted to pH 7…
```

## Alternative: Running SQL Queries

You can also run SQL queries directly on the BigQuery tables. See the
`tutorial_service_sector_data` vignette for examples of how to do this
with the service sector data, but the same principles apply to the Kanta
lab data.
