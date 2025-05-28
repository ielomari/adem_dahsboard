library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")


offres_file <- dir_ls("data/fetched", regexp = "offres-details.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier offres-details détecté : ", offres_file)


df <- read_csv_utf8(offres_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    date_ref = date,
    nature_contrat = nature_contrat,
    rome_niveau1 = rome_niveau1,
    rome_niveau1_libelle = rome_niveau1_libelle,
    rome_niveau2 = rome_niveau2,
    rome_niveau2_libelle = rome_niveau2_libelle,
    rome_metier = rome_metier,
    rome_metier_libelle = rome_metier_libelle,
    rome_appellation = rome_appellation,
    nace = nace,
    nace2 = nace2,
    nace3 = nace3,
    nom_commune = nom_commune,
    postes_declares = postes_declares,
    stock_postes_vacants = stock_postes_vacants
  ) %>%
  mutate(
    date_ref = as.Date(date_ref, format = "%d-%m-%Y"),
    postes_declares = as.integer(postes_declares),
    stock_postes_vacants = as.integer(stock_postes_vacants)
  )


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")
DBI::dbWriteTable(
  con,
  DBI::Id(schema = "student_ibtissam", table = "offres_details"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'offres-details' importées avec succès.")
