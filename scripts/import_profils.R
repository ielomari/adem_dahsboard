library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")

# Trouver le dernier fichier profils
profils_file <- dir_ls("data/fetched", regexp = "de-dispo-profils.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier profils détecté : ", profils_file)

#  Lire + convertir les encodages
df <- read_csv_utf8(profils_file)

#  Nettoyage
df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    genre = genre,
    age = age,
    niveau_diplome = niveau_de_diplome,
    duree_inscription = duree_d_inscription,
    duree_inactivite = duree_d_inactivite,
    statut_specifique = statut_specifique,
    personnes = personnes
  ) %>%
  mutate(
    date_ref = as.Date(date_ref, format = "%d-%m-%y"),
    personnes = as.integer(personnes)
  )

#  Insertion PostgreSQL
con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")

DBI::dbWriteTable(
  con,
  name = DBI::Id(schema = "student_ibtissam", table = "demandeurs_profils"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)

DBI::dbDisconnect(con)

message("✅ Données 'profils' importées avec succès")
