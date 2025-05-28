library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


metier_file <- dir_ls("data/fetched", regexp = "de-metier.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier métier détecté : ", metier_file)


df <- read_csv_utf8(metier_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    genre = genre,
    rome_niveau2 = rome_niveau2,
    rome_niveau2_libelle = rome_niveau2_libelle,
    rome_niveau1 = rome_niveau1,
    rome_niveau1_libelle = rome_niveau1_libelle,
    groupe = groupe,
    personnes = personnes
  ) %>%
  mutate(
    date_ref = as.Date(date_ref, format = "%d-%m-%Y"),
    personnes = as.integer(personnes)
  )


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")
DBI::dbWriteTable(
  con,
  DBI::Id(schema = "student_ibtissam", table = "demandeurs_metier"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'métier' importées avec succès.")
