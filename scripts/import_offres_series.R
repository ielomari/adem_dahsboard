library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


series_file <- dir_ls("data/fetched", regexp = "offres-series.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier offres-series détecté : ", series_file)


df <- read_csv_utf8(series_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    nature_contrat = nature_contrat,
    postes_declares = postes_declares,
    stock_postes_vacants = stock_postes_vacants
  ) %>%
  mutate(
    date_ref = as.Date(date_ref, format = "%d-%m-%Y"),
    postes_declares = as.integer(postes_declares),
    stock_postes_vacants = as.integer(stock_postes_vacants)
  )


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")
DBI::dbWriteTable(
  con,
  DBI::Id(schema = "student_ibtissam", table = "offres_series"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'offres-series' importées avec succès.")
