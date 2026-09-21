# R Package Style Guide

## Pipe operator

- Always use `|>` (native pipe) instead of `%>%` (magrittr pipe).

## Roxygen documentation

- Use Roxygen2 for all function documentation.
- Always include `@importFrom` directives for functions imported from other
  packages.
- Do NOT include `@examples` sections.
- Standard format: `@title`, `@description`, `@param`, `@return`,
  `@importFrom package function`.
- `@export` is only used for functions that are intended to be used by the
  user. Internal functions should not be exported and must start with a dot.

## Package preferences

- Prefer tidyverse functions over base R when possible.
- Use `dplyr`, `readr`, `tibble`, `stringr`, `purrr` instead of base R
  equivalents.
- Use base R when it's more appropriate or when tidyverse adds unnecessary
  dependencies.

## Code style

- Use camelCase: function and variable names start with lowercase, package
  names start with uppercase.
- Function names are verbs, variable names are nouns
  (e.g. `fitModel`, `population`).
- Use `<-` for assignment, not `=`.
- Place spaces around infix operators (`=`, `+`, `-`, `<-`, etc.) and after
  commas.
- Always use curly braces `{}` for if-then-else, even single statements.
- Use named arguments when calling functions with more than one argument.
- Pipes (`|>`) should be at the end of the line.
- Limit lines to 100 characters.
- Comments explain *why*, not *what*; use `#` with a space.

## SQL (SqlRender)

- Write SQL in the OHDSI **SQL Server** dialect — this is SqlRender's source
  dialect — and let `SqlRender::translate()` convert it to the target dbms at
  runtime. The canonical templates live in `inst/sql/sql_server/`.
- Parameterise with `@name` placeholders and render with `SqlRender::render()`;
  never paste values straight into a query string.
- Add a dialect-specific file (e.g. `inst/sql/bigquery/`) only when translation
  can't produce correct SQL for that platform. Keep it a minimal override of the
  `sql_server` version, not a divergent rewrite.
- Reference OMOP CDM tables and columns by their standard names.
- Column names and aliases in SQL are **snake_case** — never camelCase aliases
  (e.g. `AS visit_group_concept_id`, not `AS visitGroupConceptId`). Some backends
  (BigQuery) fold identifiers to lowercase, so a camelCase alias comes back
  mangled and differs by dialect; snake_case is already lowercase and survives
  unchanged. Returned data frames therefore stay snake_case. If a function ever
  needs camelCase in R, convert the returned names with
  `SqlRender::snakeCaseToCamelCase()` — do not alias in the SQL.