#
# SETUP
#

# bigquery
bigrquery::bq_auth(path = Sys.getenv("GCP_SERVICE_KEY"))
project_id <- "atlas-development-270609"

test_longitudinal_data_table <- "atlas-development-270609.sandbox_tools_dev.finngen_dev_service_sector_detailed_longitudinal_dev"
fg_codes_info_table <- "atlas-development-270609.medical_codes_dev.fg_codes_info_dev"
tmp_schema <- "sandbox"

# Environment
test_environment <- "build"

