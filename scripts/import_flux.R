library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


flux_file <- dir_ls("data/fetched", regexp = "de-flux.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier flux détecté : ", flux_file)


df <- read_csv_utf8(flux_file)


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


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")

DBI::dbWriteTable(
  con,
  name = DBI::Id(schema = "student_ibtissam", table = "demandeurs_flux"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)

DBI::dbDisconnect(con)

message("✅ Données 'flux' importées avec succès")
