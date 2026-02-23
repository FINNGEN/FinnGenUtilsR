# Adding names to longitudinal and service sector codes

## Intro

This tutorial shows how to append additional information to a
longitudinal or service-sector table using `dplyr` package and the
`fgbq` object from the `FinnGenUtilsR` package.

Information to add includes: name of the medical codes in English, name
for the type of visit, name for the type of provider.

To understand what the `fgbq` object is, see the dedicated vignette
`tutorial_fgbq`.

This tutorial also includes how to append additional information to the
Kanta lab data. In particular, the name of the OMOP concept for the lab
test.

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
#>   - minimum_extended: sandbox_tools_dev.minimum_extended_dev_dev
#>   - service_sector_detailed_longitudinal: sandbox_tools_dev.finngen_dev_service_sector_detailed_longitudinal_dev
#>   - kanta: sandbox_tools_dev.kanta_dev_dev
#>   - kidney: sandbox_tools_dev.kidney_dev_dev
#>   - vision: sandbox_tools_dev.vision_dev_dev
#>   - birth_mother: sandbox_tools_dev.birth_mother_dev_dev
#>   - hla_imputed: sandbox_tools_dev.hla_imputed_dev_dev
#>   - drug_events: sandbox_tools_dev.drug_events_dev_dev
#>   - kanta_medication_delivery: sandbox_tools_dev.kanta_medication_delivery_dev_dev
#>   - kanta_prescription: sandbox_tools_dev.kanta_prescription_dev_dev
#>   - code_counts: sandbox_tools_dev.code_counts_dev_dev
#>   - code_prevalence_stratified: sandbox_tools_dev.code_prevalence_stratified_dev_dev
#>   - endpoint_cohorts: sandbox_tools_dev.endpoint_cohorts_dev_dev
#>   - fg_codes_info: medical_codes.fg_codes_info_dev
#>   - finngen_vnrs: medical_codes.finngen_vnr_dev
#>   - omop_concept: finngen_omop_dev_dev.concept
#> Creating table connections (this may take a moment)...
#> Successfully connected to 16 tables in 8.21 seconds
```

We can access the service sector data using the `fgbq` object as
follows:

``` r
fgbq$tbl$service_sector_detailed_longitudinal |> head()
#> # Source:   SQL [?? x 16]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE EVENT_AGE APPROX_EVENT_DAY CODE1   CODE2 CODE3  CODE4 CODE5
#>   <chr>      <chr>      <dbl> <date>           <chr>   <chr> <chr>  <chr> <chr>
#> 1 FG00000001 PURCH       41.9 2018-04-30       C10AA05 NA    119478 1     NA   
#> 2 FG00000001 PURCH       42.1 2018-07-01       R03BA07 NA    007549 1     NA   
#> 3 FG00000001 PURCH       42.2 2018-08-15       D06BX01 NA    007623 1     NA   
#> 4 FG00000001 PURCH       42.6 2018-12-16       R01AD08 NA    018285 1     NA   
#> 5 FG00000001 PURCH       41.9 2018-04-14       A06AC01 NA    063219 1     NA   
#> 6 FG00000001 PURCH       41.8 2018-03-07       C10AA02 NA    014253 1     NA   
#> # ℹ 7 more variables: CODE6 <chr>, CODE7 <chr>, CODE8 <chr>, CODE9 <chr>,
#> #   ICDVER <chr>, CATEGORY <chr>, INDEX <chr>
```

## Generate a table in service sector format

For example we create a subset of the main service sector table by
filtering events for one patient.

``` r
# Get events for subject FG00000001
ss_subject_1_tbl <- fgbq$tbl$service_sector_detailed_longitudinal |> 
  dplyr::filter(FINNGENID == "FG00000001")
```

We can see that this table does not currently have information about the
medical codes:

``` r
ss_subject_1_tbl |> head()
#> # Source:   SQL [?? x 16]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE EVENT_AGE APPROX_EVENT_DAY CODE1   CODE2 CODE3  CODE4 CODE5
#>   <chr>      <chr>      <dbl> <date>           <chr>   <chr> <chr>  <chr> <chr>
#> 1 FG00000001 PURCH       41.9 2018-04-30       C10AA05 NA    119478 1     NA   
#> 2 FG00000001 PURCH       42.1 2018-07-01       R03BA07 NA    007549 1     NA   
#> 3 FG00000001 PURCH       42.2 2018-08-15       D06BX01 NA    007623 1     NA   
#> 4 FG00000001 PURCH       42.6 2018-12-16       R01AD08 NA    018285 1     NA   
#> 5 FG00000001 PURCH       41.9 2018-04-14       A06AC01 NA    063219 1     NA   
#> 6 FG00000001 PURCH       41.8 2018-03-07       C10AA02 NA    014253 1     NA   
#> # ℹ 7 more variables: CODE6 <chr>, CODE7 <chr>, CODE8 <chr>, CODE9 <chr>,
#> #   ICDVER <chr>, CATEGORY <chr>, INDEX <chr>
```

(same table in html format for exporation)

### Adding info to medical codes

Function `fg_dbplyr_append_code_info_to_longitudinal_data` adds new
columns with information about the medical code used in each event/row.

We just need to indicate the table with the translations. This is also
available in the `fgbq` object.

``` r
ss_subject_1_with_translations_tbl <- fg_dbplyr_append_code_info_to_longitudinal_data(
  ss_subject_1_tbl, 
  fg_bq_tables = fgbq
)
```

``` r
ss_subject_1_with_translations_tbl |>  
  dplyr::select(FINNGENID, SOURCE, APPROX_EVENT_DAY, CODE1, CODE2, CODE3, code, name_en, name_fi, omop_concept_id) |> 
  head()
#> # Source:   SQL [?? x 10]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE APPROX_EVENT_DAY CODE1   CODE2 CODE3  code   name_en name_fi
#>   <chr>      <chr>  <date>           <chr>   <chr> <chr>  <chr>  <chr>   <chr>  
#> 1 FG00000001 PURCH  2018-04-30       C10AA05 NA    119478 C10AA… atorva… NA     
#> 2 FG00000001 PURCH  2018-07-01       R03BA07 NA    007549 R03BA… mometa… NA     
#> 3 FG00000001 PURCH  2018-08-15       D06BX01 NA    007623 D06BX… metron… NA     
#> 4 FG00000001 PURCH  2018-12-16       R01AD08 NA    018285 R01AD… flutic… NA     
#> 5 FG00000001 PURCH  2018-04-14       A06AC01 NA    063219 A06AC… ispagh… NA     
#> 6 FG00000001 PURCH  2018-03-07       C10AA02 NA    014253 C10AA… lovast… NA     
#> # ℹ 1 more variable: omop_concept_id <chr>
```

(same table in html format for exploration)

### If an event/row uses more than one medical code

Some events include more than one medical code, or more than one way to
understand a medical code. Parameters in
`fg_dbplyr_append_code_info_to_longitudinal_data` allows to chose how to
name the medical code in this situations.

For example:

- PURCH_map_to = “VNR”, tells to use the VNR code in PURCH register,
  instead of the default ATC
- ICD10fi_map_to = “CODE1”, tells to use only the first code in ICD10fi,
  instead of the default CODE1\*CODE2 combination code

``` r
fg_dbplyr_append_code_info_to_longitudinal_data(
  ss_subject_1_tbl, 
  fg_bq_tables = fgbq,
  PURCH_map_to = "VNR", 
  ICD10fi_map_to = "CODE1" 
) |>
  filter(vocabulary_id == "ICD10fi" | vocabulary_id == "VNRfi") |>  
  dplyr::select(FINNGENID, SOURCE, APPROX_EVENT_DAY, CODE1, CODE2, vocabulary_id, code, name_en, name_fi, omop_concept_id) |> 
  head()
#> # Source:   SQL [?? x 10]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE APPROX_EVENT_DAY CODE1   CODE2 vocabulary_id code   name_en 
#>   <chr>      <chr>  <date>           <chr>   <chr> <chr>         <chr>  <chr>   
#> 1 FG00000001 PURCH  2018-04-30       C10AA05 NA    VNRfi         119478 ATORVAS…
#> 2 FG00000001 PURCH  2018-07-01       R03BA07 NA    VNRfi         007549 ASMANEX…
#> 3 FG00000001 PURCH  2018-08-15       D06BX01 NA    VNRfi         007623 ROSAZOL…
#> 4 FG00000001 PURCH  2018-12-16       R01AD08 NA    VNRfi         018285 FLIXONA…
#> 5 FG00000001 PURCH  2018-04-14       A06AC01 NA    VNRfi         063219 VI-SIBL…
#> 6 FG00000001 PURCH  2018-03-07       C10AA02 NA    VNRfi         014253 LOVASTA…
#> # ℹ 2 more variables: name_fi <chr>, omop_concept_id <chr>
```

(same table in html format for exploration)

Se the help, for more options

``` r
?fg_append_code_info_to_longitudinal_data_sql
```

### Reduce code precision

ICD10fi, ICD9fi, ICD8fi, ATC, and NCSPfi, code systems reflect the
hierarchy of the code by the first letters on them.

It is possible to truncate these medical codes before the information is
added. This in practice adds the code and names of the parent codes.

``` r
fg_dbplyr_append_code_info_to_longitudinal_data(
  ss_subject_1_tbl, 
  fg_bq_tables = fgbq, 
  ICD10fi_precision = 3,
  ICD9fi_precision = 3,
  ICD8fi_precision = 3,
  ATC_precision = 3,
  NCSPfi_precision = 2
) |>
  dplyr::select(FINNGENID, SOURCE, APPROX_EVENT_DAY, CODE1, CODE2, vocabulary_id, code, name_en, name_fi, omop_concept_id) |> 
  head()
#> # Source:   SQL [?? x 10]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE APPROX_EVENT_DAY CODE1   CODE2 vocabulary_id code  name_en  
#>   <chr>      <chr>  <date>           <chr>   <chr> <chr>         <chr> <chr>    
#> 1 FG00000001 PURCH  2018-04-30       C10AA05 NA    ATC           C10   LIPID MO…
#> 2 FG00000001 PURCH  2018-07-01       R03BA07 NA    ATC           R03   DRUGS FO…
#> 3 FG00000001 PURCH  2018-08-15       D06BX01 NA    ATC           D06   ANTIBIOT…
#> 4 FG00000001 PURCH  2018-12-16       R01AD08 NA    ATC           R01   NASAL PR…
#> 5 FG00000001 PURCH  2018-04-14       A06AC01 NA    ATC           A06   DRUGS FO…
#> 6 FG00000001 PURCH  2018-03-07       C10AA02 NA    ATC           C10   LIPID MO…
#> # ℹ 2 more variables: name_fi <chr>, omop_concept_id <chr>
```

(same table in html format for exploration)

We can see in column `code` the truncated code and in `name_en` the name
of the truncated code.

## Adding info to visit type

Function `fg_dbplyr_append_visit_type_info_to_service_sector_data` adds
new columns with information about the visit type.

In the service-sector data, information about the visit type is defined
in CODE5 to CODE9 depending on the SOURCE and time period.
`fg_dbplyr_append_visit_type_info_to_service_sector_data` abstracts this
nuances, and assign one visit type code per row. Notice that a visit may
contain more than one event/row. Events/rows belonging to the same visit
share the same combination of SOURCE+INDEX.

By default, `fg_bq_append_visit_type_info_to_service_sector_data` will
also include two columns `is_clinic_visit` and `is_follow_up_visit` that
will be TRUE if the visit is a clinic visit or a follow-up visit,
respectively. However, this works only if `fg_codes_info_table` version
is v7 or higher. If you need to use lower versions set the parameters
`add_is_clinic_visist` and `add_is_follow_up_visit` to FALSE. See the
help for more details.

``` r
fg_dbplyr_append_visit_type_info_to_service_sector_data(
  ss_subject_1_tbl, 
  fg_bq_tables = fgbq
) |> 
  dplyr::select(FINNGENID, SOURCE, INDEX, APPROX_EVENT_DAY, CODE5, CODE6, CODE8, CODE9, visit_type_code, visit_type_name_en, is_clinic_visit, is_follow_up_visit) |> 
  head()
#> # Source:   SQL [?? x 12]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE INDEX APPROX_EVENT_DAY CODE5 CODE6 CODE8 CODE9
#>   <chr>      <chr>  <chr> <date>           <chr> <chr> <chr> <chr>
#> 1 FG00000001 PURCH  1     2018-04-30       NA    NA    NA    NA   
#> 2 FG00000001 PURCH  2     2018-07-01       NA    NA    NA    NA   
#> 3 FG00000001 PURCH  3     2018-08-15       NA    NA    NA    NA   
#> 4 FG00000001 PURCH  4     2018-12-16       NA    NA    NA    NA   
#> 5 FG00000001 PURCH  5     2018-04-14       NA    NA    NA    NA   
#> 6 FG00000001 PURCH  6     2018-03-07       NA    NA    NA    NA   
#> # ℹ 4 more variables: visit_type_code <chr>, visit_type_name_en <chr>,
#> #   is_clinic_visit <lgl>, is_follow_up_visit <lgl>
```

(same table in html format for exploration)

## Adding info to provider type

Function `fg_dbplyr_append_provider_info_to_service_sector_data` adds
new columns with information about the personal or unit that provided
the diagnose during the visit.

In the service-sector data, information about the provider is defined in
CODE6 to CODE7 depending on the SOURCE.
`fg_dbplyr_append_provider_info_to_service_sector_data` abstracts this
nuances, and assign one provider type code per row.

``` r
fg_dbplyr_append_provider_info_to_service_sector_data(
  ss_subject_1_tbl, 
  fg_bq_tables = fgbq
) |> 
  dplyr::select(FINNGENID, SOURCE, INDEX, APPROX_EVENT_DAY, CODE5, CODE6, CODE8, CODE9, provider_code, provider_name_en, provider_concept_class_id) |> 
  head()
#> # Source:   SQL [?? x 11]
#> # Database: BigQueryConnection
#>   FINNGENID  SOURCE INDEX APPROX_EVENT_DAY CODE5 CODE6 CODE8 CODE9 provider_code
#>   <chr>      <chr>  <chr> <date>           <chr> <chr> <chr> <chr> <chr>        
#> 1 FG00000001 PURCH  39    2020-03-13       NA    NA    NA    NA    NA           
#> 2 FG00000001 PURCH  91    2022-05-09       NA    NA    NA    NA    NA           
#> 3 FG00000001 PURCH  92    2022-10-07       NA    NA    NA    NA    NA           
#> 4 FG00000001 PURCH  144   2008-03-06       NA    NA    NA    NA    NA           
#> 5 FG00000001 PURCH  145   2008-03-12       NA    NA    NA    NA    NA           
#> 6 FG00000001 PURCH  169   2010-08-09       NA    NA    NA    NA    NA           
#> # ℹ 2 more variables: provider_name_en <chr>, provider_concept_class_id <chr>
```

(same table in html format for exploration)

## Alternative: Running SQL Queries

The previous examples used `dplyr` syntax with `fgbq$tbl` objects.
Alternatively, you can work directly with BigQuery tables using the
`fg_bq_*` family of functions, which execute SQL queries directly on
BigQuery.

This approach is useful when you need more control over the query
execution or when working with existing BigQuery table references.

### Setup for BigQuery approach

First, we need to set up the BigQuery connection and table references:

``` r
library(bigrquery)

# Your BigQuery project ID
project_id <- "atlas-development-270609"

# Path to the fg_codes_info table
fg_codes_info_table <- "atlas-development-270609.medical_codes_dev.fg_codes_info_dev"

# Create a bq_table reference to your service sector data
# This could be a table you've already created in BigQuery
service_sector_bq_table <- bq_table(
  project = project_id,
  dataset = "sandbox_tools_dev",
  table = "finngen_dev_service_sector_detailed_longitudinal_dev"
)
```

### Generate a table in service sector format

``` r
# Get events for subject FG00000001 directly from BigQuery
ss_subject_1_bq <- bq_project_query(
  project_id,
  "SELECT * FROM `atlas-development-270609.sandbox_tools_dev.finngen_dev_service_sector_detailed_longitudinal_dev` WHERE FINNGENID = 'FG00000001'"
) 
```

### Adding info to medical codes with BigQuery

Function `fg_bq_append_code_info_to_longitudinal_data` works similarly
to the `dplyr` version, but operates directly on BigQuery tables:

``` r
# Add code information to the service sector table
result_bq_table <- fg_bq_append_code_info_to_longitudinal_data(
  bq_project_id = project_id,
  bq_table = ss_subject_1_bq,
  fg_codes_info_table = fg_codes_info_table
)

# The result is a new temporary table in BigQuery
result_bq_table |> bq_table_download() |>  
  dplyr::select(FINNGENID, SOURCE, APPROX_EVENT_DAY, CODE1, CODE2, vocabulary_id, code, name_en, name_fi, omop_concept_id) |> 
  head()
#> # A tibble: 6 × 10
#>   FINNGENID  SOURCE APPROX_EVENT_DAY CODE1   CODE2 vocabulary_id code    name_en
#>   <chr>      <chr>  <date>           <chr>   <chr> <chr>         <chr>   <chr>  
#> 1 FG00000001 PURCH  2018-04-30       C10AA05 NA    ATC           C10AA05 atorva…
#> 2 FG00000001 PURCH  2018-07-01       R03BA07 NA    ATC           R03BA07 mometa…
#> 3 FG00000001 PURCH  2018-08-15       D06BX01 NA    ATC           D06BX01 metron…
#> 4 FG00000001 PURCH  2018-12-16       R01AD08 NA    ATC           R01AD08 flutic…
#> 5 FG00000001 PURCH  2018-04-14       A06AC01 NA    ATC           A06AC01 ispagh…
#> 6 FG00000001 PURCH  2018-03-07       C10AA02 NA    ATC           C10AA02 lovast…
#> # ℹ 2 more variables: name_fi <chr>, omop_concept_id <chr>
```
