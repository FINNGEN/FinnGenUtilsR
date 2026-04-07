# FinnGen BigQuery Tables Handler

R6 class for handling BigQuery tables information including environment
and data freeze

## Details

### Methods

`$new(environment, dataFreeze = NULL, tablesPathsTibble = NULL, tablesGroup = "register")`
Initialize a new object.

`$print()` Print information about the object.

`$query(sql, ...)` Execute a SQL query against BigQuery. Returns a
BigQuery table reference.

## Active bindings

- `connection`:

  BigQuery connection object (read-only).

- `environment`:

  Environment identifier (e.g., "build", "prod") (read-only).

- `dataFreeze`:

  Data freeze identifier (e.g., "r13", "dev") (read-only).

- `tablePaths`:

  Named list containing table paths (read-only).

- `tbl`:

  List of dplyr table objects (read-only).

## Methods

### Public methods

- [`fg_bq_tables$new()`](#method-fg_bq_tables-new)

- [`fg_bq_tables$print()`](#method-fg_bq_tables-print)

- [`fg_bq_tables$query()`](#method-fg_bq_tables-query)

- [`fg_bq_tables$clone()`](#method-fg_bq_tables-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize method - Creates a new fg_bq_tables object

#### Usage

    fg_bq_tables$new(
      environment,
      dataFreeze = NULL,
      tablesPathsTibble = NULL,
      tablesGroup = "register"
    )

#### Arguments

- `environment`:

  Environment identifier (e.g., "build", "prod")

- `dataFreeze`:

  (Optional) Data freeze identifier (default is NULL)

- `tablesPathsTibble`:

  (Optional) Tibble containing table paths (default is NULL)

- `tablesGroup`:

  (Optional) Table group to include: 'register' (default), 'cdm', or
  'register_and_cdm'

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print method - Prints information about the fg_bq_tables object

#### Usage

    fg_bq_tables$print()

------------------------------------------------------------------------

### Method `query()`

Query method - Execute a SQL query against BigQuery

#### Usage

    fg_bq_tables$query(sql, ...)

#### Arguments

- `sql`:

  Character string containing the SQL query to execute

- `...`:

  Additional arguments passed to bigrquery::bq_project_query()

#### Returns

A BigQuery table reference that can be downloaded with
bq_table_download()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    fg_bq_tables$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
