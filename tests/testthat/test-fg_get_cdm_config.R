
test_that("fg_get_cdm_config works", {

  config <- fg_get_cdm_config(environment = "sandbox-1", dataFreezeNumber = 11)
  config |> checkmate::expect_list()

  config <- fg_get_cdm_config(environment = "sandbox-1", dataFreezeNumber = 11, asYaml = TRUE)
  config |> checkmate::expect_string()
})



test_that("fg_get_cdm_config fail messages", {
  config <- fg_get_cdm_config(environment = "sandbox-uno", dataFreezeNumber = 11) |>
    expect_error("Environment must be 'sandbox-' followed by the sandbox number.")
})
