read_csv_utf8 <- function(file_path, delim = ";") {
  df <- readr::read_delim(
    file = file_path,
    delim = delim,
    locale = readr::locale(encoding = "latin1")
  )
  df <- df %>%
    dplyr::mutate(across(where(is.character), ~ iconv(.x, from = "latin1", to = "UTF-8")))
  return(df)
}
