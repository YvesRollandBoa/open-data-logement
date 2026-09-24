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
