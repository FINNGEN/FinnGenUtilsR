% Generated by roxygen2: do not edit by hand
% Please edit documentation in
%   R/fg_append_visit_type_info_to_service_sector_data.R
\name{fg_append_visit_type_info_to_service_sector_data_sql}
\alias{fg_append_visit_type_info_to_service_sector_data_sql}
\title{fg_append_visit_type_info_to_service_sector_data_sql}
\usage{
fg_append_visit_type_info_to_service_sector_data_sql(
  service_sector_data_table,
  fg_codes_info_table,
  prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector = TRUE,
  add_is_clinic_visist = TRUE,
  add_is_follow_up_visit = TRUE,
  new_colums_sufix = ""
)
}
\arguments{
\item{service_sector_data_table}{full path to the table in longitudinal_data format}

\item{fg_codes_info_table}{full path to the table with the codes info}

\item{prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector}{Some hilmo visits are including both coding systems, SRC|ServiceSector and SRC|Contact|Urgency, if TRUE the second is used}

\item{add_is_clinic_visist}{add a column indicating if the visit is a clinic visit}

\item{add_is_follow_up_visit}{add a column indicating if the visit is a follow up visit}

\item{new_colums_sufix}{string indicating a prefix to add to the appended columns, default="".}
}
\value{
sql script ready to be ran
}
\description{
fg_append_visit_type_info_to_service_sector_data_sql
}
