test_that("fg_tables works", {

  connection <- fg_connection(environment = test_environment) 

  connection |> checkmate::assert_class("DBIConnection")

})

