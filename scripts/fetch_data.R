library(httr)
library(jsonlite)
library(glue)
library(fs)

# Slug du dataset (depuis l'URL stable du site)
dataset_slug <- "chiffres-cles-de-ladem"
api_url <- glue("https://data.public.lu/api/1/datasets/{dataset_slug}/")

# Créer dossier s'il n'existe pas
dir_create("data/fetched")

# Requête à l'API
res <- GET(api_url)
stop_for_status(res)
parsed <- fromJSON(content(res, "text", encoding = "UTF-8"))

# Filtrer les ressources CSV (casse insensible)
csv_files <- subset(parsed$resources, tolower(format) == "csv")

# Télécharger les fichiers
for (i in seq_len(nrow(csv_files))) {
  titre <- csv_files$title[i]
  file_url <- csv_files$url[i]
  date <- as.Date(csv_files$last_modified[i])
  nom_fichier <- glue("data/fetched/{date}_{basename(file_url)}")
  
  if (!file_exists(nom_fichier)) {
    message("⬇️ Téléchargement : ", titre)
    try({
      download.file(file_url, nom_fichier, mode = "wb")
    }, silent = TRUE)
  } else {
    message("✅ Déjà téléchargé : ", titre)
  }
}
