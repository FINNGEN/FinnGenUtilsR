% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/HadesExtras.R
\name{tmp_ConnectionHandler}
\alias{tmp_ConnectionHandler}
\title{tmp fix for ConnectionHandler}
\description{
tmp fix for ConnectionHandler

tmp fix for ConnectionHandler
}
\details{
till this is fixed https://github.com/OHDSI/DatabaseConnector/issues/236
}
\section{Super class}{
\code{FinnGenUtilsR::ConnectionHandler} -> \code{tmp_ConnectionHandler}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-tmp_ConnectionHandler-tbl}{\code{tmp_ConnectionHandler$tbl()}}
\item \href{#method-tmp_ConnectionHandler-clone}{\code{tmp_ConnectionHandler$clone()}}
}
}
\if{html}{\out{
<details><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="closeConnection"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-closeConnection'><code>FinnGenUtilsR::ConnectionHandler$closeConnection()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="dbIsValid"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-dbIsValid'><code>FinnGenUtilsR::ConnectionHandler$dbIsValid()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="dbms"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-dbms'><code>FinnGenUtilsR::ConnectionHandler$dbms()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="executeFunction"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-executeFunction'><code>FinnGenUtilsR::ConnectionHandler$executeFunction()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="executeSql"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-executeSql'><code>FinnGenUtilsR::ConnectionHandler$executeSql()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="finalize"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-finalize'><code>FinnGenUtilsR::ConnectionHandler$finalize()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="getConnection"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-getConnection'><code>FinnGenUtilsR::ConnectionHandler$getConnection()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="initConnection"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-initConnection'><code>FinnGenUtilsR::ConnectionHandler$initConnection()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="initialize"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-initialize'><code>FinnGenUtilsR::ConnectionHandler$initialize()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="queryDb"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-queryDb'><code>FinnGenUtilsR::ConnectionHandler$queryDb()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="queryFunction"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-queryFunction'><code>FinnGenUtilsR::ConnectionHandler$queryFunction()</code></a></span></li>
<li><span class="pkg-link" data-pkg="FinnGenUtilsR" data-topic="ConnectionHandler" data-id="renderTranslateSql"><a href='../../FinnGenUtilsR/html/ConnectionHandler.html#method-ConnectionHandler-renderTranslateSql'><code>FinnGenUtilsR::ConnectionHandler$renderTranslateSql()</code></a></span></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-tmp_ConnectionHandler-tbl"></a>}}
\if{latex}{\out{\hypertarget{method-tmp_ConnectionHandler-tbl}{}}}
\subsection{Method \code{tbl()}}{
get a dplyr table object (i.e. lazy loaded)
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{tmp_ConnectionHandler$tbl(table, databaseSchema = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{table}}{table name}

\item{\code{databaseSchema}}{databaseSchema to which table belongs}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-tmp_ConnectionHandler-clone"></a>}}
\if{latex}{\out{\hypertarget{method-tmp_ConnectionHandler-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{tmp_ConnectionHandler$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
