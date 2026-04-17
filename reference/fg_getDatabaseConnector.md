# Get Database Connector

Establishes and returns a database connector object for accessing
FinnGen database resources.

## Usage

``` r
fg_getDatabaseConnector(environment)
```

## Arguments

- environment:

  A character string specifying the database environment. Can be "build"
  for development/build environment, "preview" for preview environment,
  or a sandbox identifier in the format "sandbox-N" where N is the
  sandbox number.

## Value

A database connector object configured with appropriate connection
parameters.

## Details

This function initializes a database connection using DatabaseConnector
package utilities. The connector can be used to query and interact with
FinnGen database tables.
