library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


indem_file <- dir_ls("data/fetched", regexp = "de-indemnites.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier indemnités détecté : ", indem_file)


df <- read_csv_utf8(indem_file)


df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    genre = genre,
    age = age,
    residence = residence,
    chomage_complet = chomage_complet,
    indemnite_pro_attente = indemnite__professionnelle__d_attente
  ) %>%
  mutate(
    date_ref = as.Date(date_ref, format = "%d-%m-%Y"),
    chomage_complet = as.integer(chomage_complet),
    indemnite_pro_attente = as.integer(indemnite_pro_attente)
  )


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")
DBI::dbWriteTable(
  con,
  DBI::Id(schema = "student_ibtissam", table = "demandeurs_indemnites"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'indemnités' importées avec succès.")
