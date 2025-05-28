library(readr)
library(dplyr)
library(DBI)
library(fs)

source("scripts/connect_db.R")
source("scripts/import_utils.R")

skills_file <- dir_ls("data/fetched", regexp = "skills-vacancies.*\\.csv$") %>%
  sort(decreasing = TRUE) %>%
  .[[1]]

message("📁 Fichier skills-vacancies détecté : ", skills_file)


df <- read_csv_utf8(skills_file)

df_clean <- df %>%
  rename_with(tolower) %>%
  rename(
    vacancy_id = vacancy_id,
    skill = skill,
    skill_uri = skill_uri,
    positions = positions,
    month = month,
    year = year,
    canton = canton,
    occupation_code = occupation_code,
    occupation_label = occupation_label
  ) %>%
  mutate(
    positions = as.integer(positions),
    month = as.integer(month),
    year = as.integer(year)
  )


con <- connect_db()
DBI::dbExecute(con, "SET search_path TO student_ibtissam;")
DBI::dbWriteTable(
  con,
  DBI::Id(schema = "student_ibtissam", table = "skills_vacancies"),
  value = df_clean,
  append = TRUE,
  row.names = FALSE
)
DBI::dbDisconnect(con)

message("✅ Données 'skills-vacancies' importées avec succès.")
