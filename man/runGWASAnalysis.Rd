% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/connectAndRunGWASAnalysis.R
\name{runGWASAnalysis}
\alias{runGWASAnalysis}
\title{runGWASAnalysis}
\usage{
runGWASAnalysis(
  connection_sandboxAPI,
  cases_finngenids,
  controls_finngenids,
  phenotype_name,
  title = phenotype_name,
  description = phenotype_name,
  notification_email = connection_sandboxAPI$notification_email,
  analysis_type = "additive",
  release = "Regenie12"
)
}
\arguments{
\item{connection_sandboxAPI}{PARAM_DESCRIPTION}

\item{cases_finngenids}{PARAM_DESCRIPTION}

\item{controls_finngenids}{PARAM_DESCRIPTION}

\item{phenotype_name}{PARAM_DESCRIPTION}

\item{title}{PARAM_DESCRIPTION, Default: phenotype_name}

\item{description}{PARAM_DESCRIPTION, Default: phenotype_name}

\item{notification_email}{PARAM_DESCRIPTION, Default: connection_sandboxAPI$notification_email}

\item{analysis_type}{Specifies type of the analysis to perform (additive, recessive, dominant), Default: 'additive'}

\item{release}{PARAM_DESCRIPTION, Default: 'Regenie12'}
}
\description{
runGWASAnalysis
}
