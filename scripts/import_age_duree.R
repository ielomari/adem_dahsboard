library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


age_duree_file <- dir_ls("data/fetched", regexp = "de-age-duree.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier age-duree détecté : ", age_duree_file)


df <- read_csv_utf8(age_duree_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    age = age,
    duree_inscription = duree_inscription,
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
  DBI::Id(schema = "student_ibtissam", table = "demandeurs_age_duree"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'âge/durée' importées avec succès.")
