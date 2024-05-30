
# common variables
# to avoid collide in the parallel github actions
test_rename <- function(name){
  paste0(
    name,'_',
    R.version$major, R.version$minor, R.version$`svn rev`,
    R.version$os,
    '_',
    format(Sys.time(), "%Y%m%d%H%M%S")) |>
    stringr::str_replace_all("\\W", "") |> tolower()
}
