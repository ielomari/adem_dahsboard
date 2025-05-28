library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


dispo_age_file <- dir_ls("data/fetched", regexp = "de-dispo-age.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier dispo-age détecté : ", dispo_age_file)


df <- read_csv_utf8(dispo_age_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    genre = genre,
    age = age,
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
  DBI::Id(schema = "student_ibtissam", table = "demandeurs_dispo_age"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'dispo par âge' importées avec succès.")
