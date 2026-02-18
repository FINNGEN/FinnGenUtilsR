test_that("fg_tables works", {

  connection <- fg_connection(enviroment = "build") 


  fg_getLatestDataFreeze(connection)


})

