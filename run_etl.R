# run_etl.R

message("🚀 Lancement du pipeline ETL ADEM")

# Charger les fonctions de connexion
source("scripts/connect_db.R")

# Importer chaque fichier de données un par un
tryCatch({
  source("scripts/import_profils.R")
  message("✅ Import profils terminé")
}, error = function(e) {
  message("❌ Erreur import profils: ", e$message)
})

tryCatch({
  source("scripts/import_flux.R")
  message("✅ Import flux terminé")
}, error = function(e) {
  message("❌ Erreur import flux: ", e$message)
})

# Tu pourras rajouter ici les autres (jeunes, métiers, etc.)

message("✅ ETL terminé")
