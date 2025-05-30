# 📦 Required libraries
library(httr)
library(jsonlite)
library(glue)
library(fs)
library(DBI)

# 📡 Dataset API
dataset_slug <- "chiffres-cles-de-ladem"
api_url <- glue("https://data.public.lu/api/1/datasets/{dataset_slug}/")

# 📁 Create folder if not existing
dir_create("data/fetched")

# 🌐 Request API
res <- GET(api_url)
stop_for_status(res)
parsed <- fromJSON(content(res, "text", encoding = "UTF-8"))

# 🎯 Filter CSV files
csv_files <- subset(parsed$resources, tolower(format) == "csv")

# 🗄️ Connect to PostgreSQL
source("scripts/connect_db.R")
con <- connect_db()

# 🧠 Create log table if needed
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS student_ibtissam.etl_run_log (
    id SERIAL PRIMARY KEY,
    filename TEXT,
    download_date TIMESTAMP DEFAULT NOW(),
    status TEXT,
    message TEXT
  )
")

# 🔁 Loop through CSV files
new_files_downloaded <- 0

for (i in seq_len(nrow(csv_files))) {
  titre <- csv_files$title[i]
  file_url <- csv_files$url[i]
  date <- as.Date(csv_files$last_modified[i])
  nom_fichier <- glue("data/fetched/{date}_{basename(file_url)}")
  
  if (!file_exists(nom_fichier)) {
    message("⬇️ Téléchargement : ", titre)
    tryCatch({
      download.file(file_url, nom_fichier, mode = "wb")
      dbExecute(con, "INSERT INTO student_ibtissam.etl_run_log (filename, status, message)
                      VALUES ($1, 'SUCCESS', $2)", params = list(nom_fichier, titre))
      new_files_downloaded <- new_files_downloaded + 1
    }, error = function(e) {
      dbExecute(con, "INSERT INTO student_ibtissam.etl_run_log (filename, status, message)
                      VALUES ($1, 'ERROR', $2)", params = list(nom_fichier, e$message))
      message("❌ Échec : ", titre)
    })
  } else {
    message("✅ Déjà téléchargé : ", titre)
  }
}

# ✅ Final summary
message("📦 ", nrow(csv_files), " fichiers détectés dans l’API")
message("✅ ", new_files_downloaded, " nouveaux fichiers téléchargés")

# 🔌 Disconnect from DB
dbDisconnect(con)
