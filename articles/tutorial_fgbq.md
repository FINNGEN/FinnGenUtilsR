# Tutorial connection to FinnGen BQ tables

``` r
library(FinnGenUtilsR)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## Getting Started

The
[`get_fg_bq_tables()`](https://finngen.github.io/FinnGenUtilsR/reference/get_fg_bq_tables.md)
function creates a connection to FinnGen BigQuery tables and provides
easy access to all available tables.

The minimum required argument is the `environment` which specifies where
you running your queries. Typically, the environment is sandbox-XX,
where XX is the number of the sandbox you are using. You can find the
number of your sandbox in the URL when you are logged in to the FinnGen
Data Access Portal.

![](pic/sandbox_number.png)

Moreover, for internal use it is possible to specify ‘build’ or
‘preview’ as environment.

### Create Connection to BigQuery Tables

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
#> Successfully connected to all 17 tables in 8.57 seconds
```

By default
[`get_fg_bq_tables()`](https://finngen.github.io/FinnGenUtilsR/reference/get_fg_bq_tables.md)
will find the latest available data freeze and table versions but you
can specify a specific version if needed.

``` r
fgbq <- get_fg_bq_tables(
  environment = "sandbox-XX",
  dataFreeze = "r13"
)
```

### View Connection Information

The `bq_tables` object displays all relevant connection information when
printed:

``` r
fgbq
#> FinnGen BigQuery Tables Handler
#> ================================
#> 
#> Environment:      build 
#> Data Freeze:      dev 
#> Project:          atlas-development-270609 
#> Billing Project:  atlas-development-270609 
#> 
#> Available Tables:
#> -----------------
#>   [v] birth_mother                      atlas-development-270609.sandbox_tools_dev.birth_mother_dev
#>   [v] code_prevalence_stratified        atlas-development-270609.sandbox_tools_dev.code_prevalence_stratified_dev
#>   [v] covariates                        atlas-development-270609.sandbox_tools_dev.covariates_dev
#>   [v] drug_events                       atlas-development-270609.sandbox_tools_dev.drug_events_dev
#>   [v] endpoint_cohorts                  atlas-development-270609.sandbox_tools_dev.endpoint_cohorts_dev
#>   [v] fg_codes_info                     atlas-development-270609.medical_codes_dev.fg_codes_info_dev
#>   [v] finngen_vnrs                      atlas-development-270609.medical_codes_dev.finngen_vnr_dev
#>   [v] hla_imputed                       atlas-development-270609.sandbox_tools_dev.hla_imputed_dev
#>   [v] kanta                             atlas-development-270609.sandbox_tools_dev.kanta_dev
#>   [v] kidney                            atlas-development-270609.sandbox_tools_dev.kidney_dev
#>   [v] minimum_extended                  atlas-development-270609.sandbox_tools_dev.minimum_extended_dev
#>   [v] plasma_samples                    atlas-development-270609.sandbox_tools_dev.plasma_samples_dev
#>   [v] service_sector_detailed_longitudinal atlas-development-270609.sandbox_tools_dev.finngen_dev_service_sector_detailed_longitudinal
#>   [v] spirometry                        atlas-development-270609.sandbox_tools_dev.spirometry_dev
#>   [v] vaccination                       atlas-development-270609.sandbox_tools_dev.vaccination_dev
#>   [v] vision                            atlas-development-270609.sandbox_tools_dev.vision_dev
#>   [v] cdm_concept                       atlas-development-270609.finngen_omop_dev.concept
```

This shows: - Environment (e.g., build, sandbox, preview) - Data Freeze
version (e.g., dev, r13_v3) - Project ID - Billing Project ID - All
available tables with their full paths in case you want to run raw SQL
queries

## Using BigQuery Tables

The `bq_tables` object provides access to all tables through the `tbl`
field. These tables can be used as if they were tibbles thanks to
[dbplyr](https://dbplyr.tidyverse.org/).

### Available Tables

You can view all available table names:

``` r
names(fgbq$tbl)
#>  [1] "birth_mother"                        
#>  [2] "code_prevalence_stratified"          
#>  [3] "covariates"                          
#>  [4] "drug_events"                         
#>  [5] "endpoint_cohorts"                    
#>  [6] "fg_codes_info"                       
#>  [7] "finngen_vnrs"                        
#>  [8] "hla_imputed"                         
#>  [9] "kanta"                               
#> [10] "kidney"                              
#> [11] "minimum_extended"                    
#> [12] "plasma_samples"                      
#> [13] "service_sector_detailed_longitudinal"
#> [14] "spirometry"                          
#> [15] "vaccination"                         
#> [16] "vision"                              
#> [17] "cdm_concept"
```

### Accessing Tables

Access individual tables using the `$tbl` field:

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

(same table in html format for exploration)

You can treat these tables as if they were regular tibbles. For example,
to filter for events with code “D45” in the OUTPAT source:

``` r
# Get events with code "J45" in OUTPAT
fgbq$tbl$service_sector_detailed_longitudinal |> 
  filter(CODE1 == "J45" & SOURCE == "OUTPAT")
#> # Source:   SQL [?? x 16]
#> # Database: BigQueryConnection
#>    FINNGENID  SOURCE EVENT_AGE APPROX_EVENT_DAY CODE1 CODE2 CODE3 CODE4 CODE5
#>    <chr>      <chr>      <dbl> <date>           <chr> <chr> <chr> <chr> <chr>
#>  1 FG00399691 OUTPAT      59.8 2019-07-23       J45   NA    NA    NA    NA   
#>  2 FG00399829 OUTPAT      44.3 2018-04-23       J45   NA    NA    NA    NA   
#>  3 FG00400713 OUTPAT      51.3 2022-03-28       J45   J45   NA    NA    83   
#>  4 FG00418367 OUTPAT      50.7 2015-08-08       J45   NA    NA    NA    91   
#>  5 FG00418845 OUTPAT      42.5 2021-04-16       J45   NA    NA    NA    83   
#>  6 FG00419209 OUTPAT      47.0 2014-12-22       J45   NA    NA    NA    93   
#>  7 FG00420151 OUTPAT      59.8 2019-07-23       J45   NA    NA    NA    NA   
#>  8 FG00420289 OUTPAT      44.3 2018-04-23       J45   NA    NA    NA    NA   
#>  9 FG00119530 OUTPAT      41.3 2019-08-08       J45   NA    NA    NA    93   
#> 10 FG00119530 OUTPAT      23.7 2002-01-26       J45   NA    NA    NA    91   
#> # ℹ more rows
#> # ℹ 7 more variables: CODE6 <chr>, CODE7 <chr>, CODE8 <chr>, CODE9 <chr>,
#> #   ICDVER <chr>, CATEGORY <chr>, INDEX <chr>
```

Or other tidyverse functions like
[`stringr::str_detect()`](https://stringr.tidyverse.org/reference/str_detect.html)

``` r
# Get events with code "J45" in OUTPAT
fgbq$tbl$service_sector_detailed_longitudinal |> 
  filter(CODE1 == "J45" & SOURCE == "OUTPAT")
#> # Source:   SQL [?? x 16]
#> # Database: BigQueryConnection
#>    FINNGENID  SOURCE EVENT_AGE APPROX_EVENT_DAY CODE1 CODE2 CODE3 CODE4 CODE5
#>    <chr>      <chr>      <dbl> <date>           <chr> <chr> <chr> <chr> <chr>
#>  1 FG00399691 OUTPAT      59.8 2019-07-23       J45   NA    NA    NA    NA   
#>  2 FG00399829 OUTPAT      44.3 2018-04-23       J45   NA    NA    NA    NA   
#>  3 FG00400713 OUTPAT      51.3 2022-03-28       J45   J45   NA    NA    83   
#>  4 FG00418367 OUTPAT      50.7 2015-08-08       J45   NA    NA    NA    91   
#>  5 FG00418845 OUTPAT      42.5 2021-04-16       J45   NA    NA    NA    83   
#>  6 FG00419209 OUTPAT      47.0 2014-12-22       J45   NA    NA    NA    93   
#>  7 FG00420151 OUTPAT      59.8 2019-07-23       J45   NA    NA    NA    NA   
#>  8 FG00420289 OUTPAT      44.3 2018-04-23       J45   NA    NA    NA    NA   
#>  9 FG00119530 OUTPAT      41.3 2019-08-08       J45   NA    NA    NA    93   
#> 10 FG00119530 OUTPAT      23.7 2002-01-26       J45   NA    NA    NA    91   
#> # ℹ more rows
#> # ℹ 7 more variables: CODE6 <chr>, CODE7 <chr>, CODE8 <chr>, CODE9 <chr>,
#> #   ICDVER <chr>, CATEGORY <chr>, INDEX <chr>
```

Or other tidyverse functions like
[`stringr::str_detect()`](https://stringr.tidyverse.org/reference/str_detect.html)

``` r
# This will error
fgbq$tbl$service_sector_detailed_longitudinal |> 
  filter(stringr::str_detect(CODE1, "^J45")) |> 
  count(CODE1) |> 
  head()
#> # Source:   SQL [?? x 2]
#> # Database: BigQueryConnection
#>   CODE1       n
#>   <chr> <int64>
#> 1 J458    13542
#> 2 J459   183889
#> 3 J45    100414
#> 4 J451    58219
#> 5 J450    88559
```

### Joining Tables

You can join multiple tables together. For example, to get smoking
status for asthma patients:

``` r
fgbq$tbl$service_sector_detailed_longitudinal |> 
  filter(stringr::str_detect(CODE1, "^J45")) |> 
  distinct(FINNGENID) |> 
  left_join(
    fgbq$tbl$minimum_extended, 
    by = "FINNGENID"
  ) |> 
  count(SMOKE2, SMOKE3, sort = TRUE) |> 
  head()
#> # Source:     SQL [?? x 3]
#> # Database:   BigQueryConnection
#> # Ordered by: desc(n)
#>   SMOKE2 SMOKE3        n
#>   <chr>  <chr>   <int64>
#> 1 no     NA        43697
#> 2 NA     NA        35806
#> 3 no     never     32092
#> 4 NA     never     26376
#> 5 no     current   16633
#> 6 yes    NA        15056
```

(same table in html format for exploration)

### Collect results into R

Once you have reduce the size of the total data you can download it into
memory using
[`collect()`](https://dplyr.tidyverse.org/reference/compute.html). For
example:

``` r
fgbq$tbl$service_sector_detailed_longitudinal |> 
  filter(stringr::str_detect(CODE1, "^J45")) |> 
  filter(EVENT_AGE > 50) |> 
  head() |>
  collect() 
#> # A tibble: 6 × 16
#>   FINNGENID  SOURCE   EVENT_AGE APPROX_EVENT_DAY CODE1 CODE2 CODE3 CODE4 CODE5
#>   <chr>      <chr>        <dbl> <date>           <chr> <chr> <chr> <chr> <chr>
#> 1 FG00464967 OUTPAT        80.1 2016-09-04       J459  NA    NA    NA    93   
#> 2 FG00464967 OUTPAT        80.1 2016-09-04       J459  NA    NA    NA    93   
#> 3 FG00464967 OUTPAT        80.5 2017-02-06       J450  NA    NA    NA    93   
#> 4 FG00464969 PRIM_OUT      90.1 2021-06-11       J450  NA    NA    NA    R52  
#> 5 FG00464969 PRIM_OUT      86.4 2017-10-06       J45   NA    NA    NA    R20  
#> 6 FG00464973 PRIM_OUT      54.4 2015-12-30       J45   NA    NA    NA    R50  
#> # ℹ 7 more variables: CODE6 <chr>, CODE7 <chr>, CODE8 <chr>, CODE9 <chr>,
#> #   ICDVER <chr>, CATEGORY <chr>, INDEX <chr>
```

### Running SQL Queries

However, if dbplyr is not sufficient, you can still use the `query()`
method to directly run SQL queries against the BigQuery tables. For
example:

``` r
# Write a custom SQL query
sql <- paste0("SELECT FINNGENID, CODE1, SOURCE, APPROX_EVENT_DAY
        FROM `", fgbq$tablePaths$service_sector_detailed_longitudinal, "`
        WHERE CODE1 = 'J45' AND SOURCE = 'OUTPAT' 
        LIMIT 5")

# Execute the query
result <- fgbq$query(sql)

# Download the results
bigrquery::bq_table_download(result)
#> # A tibble: 5 × 4
#>   FINNGENID  CODE1 SOURCE APPROX_EVENT_DAY
#>   <chr>      <chr> <chr>  <date>          
#> 1 FG00255635 J45   OUTPAT 2007-11-20      
#> 2 FG00257218 J45   OUTPAT 2018-08-26      
#> 3 FG00257493 J45   OUTPAT 2022-03-28      
#> 4 FG00132875 J45   OUTPAT 2007-11-20      
#> 5 FG00134458 J45   OUTPAT 2018-08-26
```

### Connection Details

You can access the underlying BigQuery connection and other properties:

``` r
# Access the connection object
fgbq$connection

# Access specific fields
fgbq$environment
fgbq$dataFreeze
fgbq$tablePaths
```
