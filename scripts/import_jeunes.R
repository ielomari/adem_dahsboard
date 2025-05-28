library(readr)
library(dplyr)
library(DBI)
library(fs)
library(tidyr)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


jeunes_file <- dir_ls("data/fetched", regexp = "de-jeunes.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier jeunes détecté : ", jeunes_file)


df <- read_csv_utf8(jeunes_file)


df_long <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    niveau_diplome = niveau_de_diplome,
    duree_inscription = duree_d_inscription,
    duree_inactivite = duree_d_inactivite
  ) %>%
  pivot_longer(cols = starts_with("_"), 
               names_to = "tranche_age", 
               values_to = "personnes") %>%
  mutate(
    tranche_age = gsub("_", "", tranche_age),
    date_ref = as.Date(date_ref, format = "%d-%m-%Y"),
    personnes = as.integer(personnes)
  )


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")

DBI::dbWriteTable(
  con,
  name = DBI::Id(schema = "student_ibtissam", table = "demandeurs_jeunes"),
  value = df_long,
  append = TRUE,
  row.names = FALSE
)

DBI::dbDisconnect(con)

message("✅ Données 'jeunes' importées avec succès.")
