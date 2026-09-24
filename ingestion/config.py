"""Paramètres partagés par les scripts d'ingestion."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
WAREHOUSE = ROOT / "data" / "warehouse.duckdb"

# MVP : Hauts-de-France. Passer à la France entière une fois le pipeline stable.
# (DVF ne couvre ni l'Alsace-Moselle — 57, 67, 68 — ni Mayotte — 976.)
DEPARTEMENTS = ["02", "59", "60", "62", "80"]

# Millésimes disponibles dans geo-dvf (mise à jour d'avril 2026 : 2021 → 2025).
ANNEES_DVF = [2021, 2022, 2023, 2024, 2025]

DVF_URL = "https://files.data.gouv.fr/geo-dvf/latest/csv/{annee}/departements/{dep}.csv.gz"

# DPE logements existants (ADEME, depuis juillet 2021), via l'API data-fair.
DPE_API = "https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines"
DPE_CHAMPS = [
    "numero_dpe",
    "numero_dpe_remplace",
    "date_etablissement_dpe",
    "code_insee_ban",
    "nom_commune_ban",
    "code_departement_ban",
    "identifiant_ban",
    "type_batiment",
    "periode_construction",
    "annee_construction",
    "surface_habitable_logement",
    "etiquette_dpe",
    "etiquette_ges",
    "conso_5_usages_par_m2_ep",
    "emission_ges_5_usages_par_m2",
]

# INSEE — Base du comparateur de territoires (population, revenus, logement… par commune).
INSEE_COMPARATEUR_URL = "https://www.insee.fr/fr/statistiques/fichier/2521169/comparateur.parquet"
