library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


nonresid_file <- dir_ls("data/fetched", regexp = "de-nonresid.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier non-résidents détecté : ", nonresid_file)


df <- read_csv_utf8(nonresid_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    genre = genre,
    age = age,
    residence = residence,
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
  DBI::Id(schema = "student_ibtissam", table = "demandeurs_nonresid"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'non-résidents' importées avec succès.")
