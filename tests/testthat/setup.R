#
# SETUP
#

# bigquery
bigrquery::bq_auth(path = Sys.getenv("GCP_SERVICE_KEY"))
project_id <- "atlas-development-270609"

test_longitudinal_data_table <- "atlas-development-270609.sandbox_tools_r13.finngen_r13_service_sector_detailed_longitudinal_v1"
fg_codes_info_table <- "atlas-development-270609.medical_codes.fg_codes_info_v9"
finngen_vnr <- "atlas-development-270609.sandbox_tools_r13.finngen_vnr_v2"
tmp_schema <- "sandbox"


# databaseConnector
test_handler_config <-fg_get_bq_config(
  environment = "atlasDevelopment",
  dataFreezeNumber = 13
)

