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
#> Successfully connected to all 17 tables in 7.89 seconds
```

We can access the Kanta lab data using the `fgbq` object as follows:

``` r
fgbq$tbl$kanta |> head()
#> # Source:   SQL [?? x 21]
#> # Database: BigQueryConnection
#>   FINNGENID  EVENT_AGE APPROX_EVENT_DATETIME TEST_NAME TEST_ID OMOP_CONCEPT_ID
#>   <chr>          <dbl> <dttm>                <chr>     <chr>           <int64>
#> 1 FG00000034      65.7 2022-03-17 07:55:00   na        NA                   -1
#> 2 FG00000035      82.7 2022-08-30 09:58:00   na        NA                   -1
#> 3 FG00000069      66.4 2020-10-16 07:01:00   na        NA                   -1
#> 4 FG00000107      64.7 2019-09-22 13:55:00   na        NA                   -1
#> 5 FG00000172      91.0 2022-09-01 11:59:00   na        NA                   -1
#> 6 FG00000186      82.8 2021-08-04 07:37:00   na        NA                   -1
#> # ℹ 15 more variables: MEASUREMENT_VALUE <dbl>, MEASUREMENT_UNIT <chr>,
#> #   MEASUREMENT_VALUE_HARMONIZED <dbl>, MEASUREMENT_UNIT_HARMONIZED <chr>,
#> #   MEASUREMENT_VALUE_EXTRACTED <dbl>, MEASUREMENT_VALUE_MERGED <dbl>,
#> #   TEST_OUTCOME <chr>, MEASUREMENT_STATUS <chr>,
#> #   REFERENCE_RANGE_LOW_VALUE <dbl>, REFERENCE_RANGE_HIGH_VALUE <dbl>,
#> #   CODING_SYSTEM_OID <chr>, TEST_ID_SOURCE <chr>, TEST_NAME_SOURCE <chr>,
#> #   MEASUREMENT_VALUE_SOURCE <dbl>, MEASUREMENT_UNIT_SOURCE <chr>
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
  head()
#> # Source:     SQL [?? x 6]
#> # Database:   BigQueryConnection
#> # Ordered by: desc(APPROX_EVENT_DATETIME)
#>   FINNGENID  EVENT_AGE APPROX_EVENT_DATETIME TEST_NAME TEST_ID OMOP_CONCEPT_ID
#>   <chr>          <dbl> <dttm>                <chr>     <chr>           <int64>
#> 1 FG00000001      71.7 2022-12-07 12:07:00   pt-gfre   656400               -1
#> 2 FG00000001      71.6 2022-11-04 16:18:00   p-crp     1605013         3020460
#> 3 FG00000001      71.6 2022-10-17 12:00:11   b-trom    3002791         3007461
#> 4 FG00000001      71.6 2022-10-15 07:01:00   e-mchc    1557            3003338
#> 5 FG00000001      71.5 2022-09-22 11:53:00   e-mchc    1557            3003338
#> 6 FG00000001      71.5 2022-09-12 12:03:00   s-ca-ion  9010            3016431
```

(same table in html format for exploration)

### Adding info to OMOP_CONCEPT_ID codes

Function `fg_dbplyr_append_concept_info_data` adds a new column with
information about the OMOP_CONCEPT_ID name.

``` r
kanta_subject_1_tbl_with_omop_name <- kanta_subject_1_tbl |> 
   fg_dbplyr_append_concept_info_data(fg_bq_tables = fgbq)
```

``` r
kanta_subject_1_tbl_with_omop_name |>  
  dplyr::select(FINNGENID, EVENT_AGE, APPROX_EVENT_DATETIME, TEST_NAME, TEST_ID, OMOP_CONCEPT_ID, concept_name) |> 
  head()
#> Warning: ORDER BY is ignored in subqueries without LIMIT
#> ℹ Do you need to move arrange() later in the pipeline or use window_order() instead?
#> # Source:     SQL [?? x 7]
#> # Database:   BigQueryConnection
#> # Ordered by: desc(APPROX_EVENT_DATETIME)
#>   FINNGENID  EVENT_AGE APPROX_EVENT_DATETIME TEST_NAME TEST_ID OMOP_CONCEPT_ID
#>   <chr>          <dbl> <dttm>                <chr>     <chr>           <int64>
#> 1 FG00000001      67.6 2018-10-19 11:00:00   ab-be     50030           3003396
#> 2 FG00000001      65.4 2016-08-01 07:57:00   ab-be     10083           3003396
#> 3 FG00000001      66.2 2017-06-08 15:34:00   fp-gluk   1468            3018251
#> 4 FG00000001      68.0 2019-03-18 12:46:00   p-probnp  4760            3029187
#> 5 FG00000001      70.8 2021-12-21 01:28:00   l-baso(a) 3001168         3022096
#> 6 FG00000001      67.1 2018-05-02 14:06:00   b-leuk    2218            3010813
#> # ℹ 1 more variable: concept_name <chr>
```

(same table in html format for exploration)

    #> Warning: ORDER BY is ignored in subqueries without LIMIT
    #> ℹ Do you need to move arrange() later in the pipeline or use window_order() instead?

## Alternative: Running SQL Queries

You can also run SQL queries directly on the BigQuery tables. See the
`tutorial_service_sector_data` vignette for examples of how to do this
with the service sector data, but the same principles apply to the Kanta
lab data.
