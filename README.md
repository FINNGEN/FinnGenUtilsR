
# FinnGenUtilsR

<!-- badges: start -->
[![R-CMD-check](https://github.com/FINNGEN/FinnGenUtilsR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/FINNGEN/FinnGenUtilsR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

R package with common functions to work FinnGen data inside Sandbox (FinnGen's secure environment).

## Installation

This package is available in the local CRAN of the FinnGen Sandbox. It can be installed as any other package in R:

``` r
install.packages("FinnGenUtilsR")
```

## Functionality 

- Easy calculation of connection parameters to connect to FinnGen BigQuery databases
- An object `FGconnectionHandler` to connect to FinnGen BigQuery databases and work with the tables as dataframes
- Functions to add info to the longitudinal data. Eg adding names to medical codes, or visit types.  For both:
  - Working with [Bigrquery](https://bigrquery.r-dbi.org/) 
  - Working with [dbplyr](https://dbplyr.tidyverse.org/) 


## Example

See vignettes or articles in [github-page](https://finngen.github.io/FinnGenUtilsR/)
 
