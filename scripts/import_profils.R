# scripts/import_profils.R

library(readr)
library(dplyr)
library(DBI)

# Charger la fonction de connexion
source("scripts/connect_db.R")

# Lecture du fichier avec encodage latin1 (Windows)
df <- read_delim(
  file = "data/demandeurs_profils.csv",
  delim = ";",
  locale = locale(encoding = "latin1")
)

# Conversion des colonnes caractères en UTF-8 pour éviter les erreurs PostgreSQL
df <- df %>%
  mutate(across(where(is.character), ~ iconv(.x, from = "ISO-8859-1", to = "UTF-8")))

# Nettoyage / renommage des colonnes
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
    date_ref = as.Date(date_ref)
  )

# Connexion à la base
con <- connect_db()

# Optionnel : définir le schéma par défaut
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")

# Insertion dans le bon schéma
DBI::dbWriteTable(
  con,
  name = DBI::Id(schema = "student_ibtissam", table = "demandeurs_profils"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)

# Déconnexion
DBI::dbDisconnect(con)

message("✅ Données profils importées dans student_ibtissam.demandeurs_profils !")
