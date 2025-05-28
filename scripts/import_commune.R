library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


commune_file <- dir_ls("data/fetched", regexp = "de-dispo-commune.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier dispo_commune détecté : ", commune_file)


df <- read_csv_utf8(commune_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    commune = commune,
    canton = canton,
    sexe = sexe,
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
  DBI::Id(schema = "student_ibtissam", table = "demandeurs_commune"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'disponibles par commune' importées avec succès.")
