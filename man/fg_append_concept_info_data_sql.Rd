% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fg_append_concept_info_data.R
\name{fg_append_concept_info_data_sql}
\alias{fg_append_concept_info_data_sql}
\title{fg_append_concept_info_data_sql}
\usage{
fg_append_concept_info_data_sql(data_table, omop_schema, new_colums_sufix = "")
}
\arguments{
\item{data_table}{string with the full path (project.schema.table) to the bq table with the data}

\item{omop_schema}{string with the schema where the omop tables are stored}

\item{new_colums_sufix}{string indicating a prefix to add to the appended columns, default="".}
}
\value{
sql script ready to be ran
}
\description{
fg_append_concept_info_data_sql
}
