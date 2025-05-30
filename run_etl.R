# run_etl.R

message("🚀 Démarrage du pipeline ETL ADEM")

# 📦 Chargement des scripts
source("scripts/fetch_data.R")                # Téléchargement API
source("scripts/import_flux.R")               # Import flux
source("scripts/import_profils.R")            # Import profils
source("scripts/import_metier.R")             # Import métier
source("scripts/import_jeunes.R")             # Import jeunes
source("scripts/import_nationalite.R")        # Import nationalité
source("scripts/import_nonresid.R")           # Import non-résidents
source("scripts/import_age_duree.R")          # Import âge/durée
source("scripts/import_dispo_age.R")          # Import dispo par âge
source("scripts/import_commune.R")            # Import dispo commune
source("scripts/import_indemnites.R")         # Import indemnités
source("scripts/import_mesures.R")            # Import mesures
source("scripts/import_offres_details.R")     # Import offres détaillées
source("scripts/import_offres_series.R")      # Import séries offres
source("scripts/import_skills_vacancies.R")   # Import compétences ESCO

message("✅ ETL terminé avec succès 🥳")
