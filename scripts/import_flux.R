# scripts/import_flux.R

library(readr)
library(dplyr)
library(DBI)

source("scripts/connect_db.R")

# Lire le fichier CSV
df <- read_delim(
  file = "data/demandeurs_flux.csv",
  delim = ";",
  locale = locale(encoding = "latin1")
)

# Corriger les encodages éventuels
df <- df %>%
  mutate(across(where(is.character), ~ iconv(.x, from = "latin1", to = "UTF-8")))

# Nettoyage
df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    residence = residence,
    ouvertures = ouvertures,
    clotures = clotures
  ) %>%
  mutate(
    date_ref = as.Date(date_ref, format = "%d-%m-%y"),
    ouvertures = as.integer(ouvertures),
    clotures = as.integer(clotures)
  )


# Connexion à la base
con <- connect_db()

# Définir le schéma actif
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")

# Insertion
DBI::dbWriteTable(
  con,
  name = DBI::Id(schema = "student_ibtissam", table = "demandeurs_flux"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)

DBI::dbDisconnect(con)

message("✅ Données flux importées dans student_ibtissam.demandeurs_flux !")
