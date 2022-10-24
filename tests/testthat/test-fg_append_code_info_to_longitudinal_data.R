library(testthat)
library(bigrquery)

bigrquery::bq_auth(path = Sys.getenv("GCP_SERVICE_KEY"))
project_id <- "atlas-development-270609"

test_longitudinal_data_table <- "atlas-development-270609.sandbox_tools_r6.finngen_dummy50k_detailed_longitudinal_v1_0"
fg_codes_info_table <- "atlas-development-270609.medical_codes.fg_codes_info_v1_0"


# sql <- paste("SELECT * FROM ", fg_codes_info_table, " LIMIT 10")
# tb <- bq_project_query(billing, sql)
# bq_table_download(tb, n_max = 10)

test_that("fg_append_code_info_to_longitudinal_data works", {


  sql <- paste("SELECT * FROM ", test_longitudinal_data_table, " WHERE FINNGENID='FG00000001'")
  tb <- bq_project_query(project_id, sql)
  tb_with_translations <- FinnGenUtilsR::fg_bq_append_code_info_to_longitudinal_data(project_id, tb, fg_codes_info_table, PURCH_map_to = "VNR")
 a <- bq_table_download(tb_with_translations)
 a

})



s <- paste("SELECT * FROM ", fg_codes_info_table, "WHERE FG_CODE1='T814'")
tb2 <- bq_project_query(billing, s)
 bq_table_download(tb2, n_max = 10)



 sql <- fg_append_code_info_to_longitudinal_data_sql(test_longitudinal_data_table, fg_codes_info_table)


 library(plotly)


 fig <- a |>
   plot_ly(type="scatter",  x = ~APPROX_EVENT_DAY , y = ~CODE1, fill = vocabulary_id    )

 fig


 a |> arrange(vocabulary_id) |>
   plotly::plot_ly(
   type = 'scatter', mode = 'markers',
   x = ~APPROX_EVENT_DAY,
   y = ~ CODE1,
   text = ~name_en,
   hoverinfo = 'text',
   color = ~vocabulary_id,
   showlegend = T
 )
