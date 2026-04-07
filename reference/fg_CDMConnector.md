# Connect to FinnGen OMOP CDM

Connect to FinnGen OMOP CDM

## Usage

``` r
fg_CDMConnector(environment = NULL, cdmDataFreezeVersion = NULL, ...)
```

## Arguments

- environment:

  Environment identifier (e.g., "build", "preview", or "sandbox-XX")

- cdmDataFreezeVersion:

  Data freeze version (e.g., "r13_v3", "dev"). If NULL, latest version
  is used.

- ...:

  Additional arguments passed to CDMConnector::cdmFromCon

## Value

A CDM reference object
