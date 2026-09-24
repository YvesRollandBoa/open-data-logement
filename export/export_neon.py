"""Exporte les tables finales de DuckDB vers Neon PostgreSQL, pour Power BI.

Power BI (dans Parallels) lit Neon dans le cloud : plus simple et plus fiable que
de lui faire lire un fichier DuckDB sur le Mac.

Chaque table est remplacée dans une transaction (DROP + CREATE + COPY + COMMIT) :
si l'export plante, l'ancienne version reste intacte dans Neon.

Configuration : un fichier `.env` à la racine du projet (jamais versionné) contenant
    NEON_URL=postgresql://neondb_owner:MOT_DE_PASSE@HOTE/neondb?sslmode=require

Usage :
    python export/export_neon.py
    python export/export_neon.py --tables fct_ventes dim_date
"""
import argparse
import os
import sys
import time
from pathlib import Path

import duckdb
import psycopg

ROOT = Path(__file__).resolve().parents[1]
WAREHOUSE = ROOT / "data" / "warehouse.duckdb"
SCHEMA_CIBLE = "open_data_logement"

# Tables exposées à Power BI (schéma DuckDB `marts`)
TABLES = [
    "dim_date",
    "dim_commune",
    "fct_ventes",
    "fct_dpe_mensuel",
    "mart_logement_commune",
    "mart_dpe_commune_etiquette",
    "mart_prix_commune_annee",
]

# Correspondance des types DuckDB → PostgreSQL
TYPES = {
    "VARCHAR": "text",
    "BOOLEAN": "boolean",
    "DATE": "date",
    "TIMESTAMP": "timestamp",
    "TIMESTAMP WITH TIME ZONE": "timestamptz",
    "TINYINT": "smallint",
    "SMALLINT": "smallint",
    "INTEGER": "integer",
    "BIGINT": "bigint",
    "HUGEINT": "numeric",
    "UBIGINT": "numeric",
    "DOUBLE": "double precision",
    "FLOAT": "real",
}


def type_pg(type_duckdb: str) -> str:
    if type_duckdb.startswith("DECIMAL"):
        return type_duckdb.replace("DECIMAL", "numeric")
    if type_duckdb not in TYPES:
        raise ValueError(f"Type DuckDB non géré : {type_duckdb}")
    return TYPES[type_duckdb]


def lire_env() -> str:
    """Lit NEON_URL depuis l'environnement ou le fichier .env."""
    env = ROOT / ".env"
    if env.exists():
        for ligne in env.read_text().splitlines():
            ligne = ligne.strip()
            if ligne and not ligne.startswith("#") and "=" in ligne:
                cle, valeur = ligne.split("=", 1)
                os.environ.setdefault(cle.strip(), valeur.strip().strip('"').strip("'"))
    url = os.environ.get("NEON_URL")
    if not url:
        raise SystemExit("NEON_URL introuvable : crée le fichier .env (voir README).")
    return url


def exporter_table(duck: duckdb.DuckDBPyConnection, pg: psycopg.Connection, table: str) -> int:
    colonnes = duck.execute(f"describe marts.{table}").fetchall()
    noms = [c[0] for c in colonnes]
    ddl = ",\n    ".join(f'"{nom}" {type_pg(typ)}' for nom, typ, *_ in colonnes)
    cible = f'"{SCHEMA_CIBLE}"."{table}"'

    lignes = duck.execute(f"select * from marts.{table}").fetchall()
    with pg.transaction():
        pg.execute(f"drop table if exists {cible}")
        pg.execute(f"create table {cible} (\n    {ddl}\n)")
        with pg.cursor().copy(f"copy {cible} ({', '.join(chr(34) + n + chr(34) for n in noms)}) from stdin") as copy:
            for ligne in lignes:
                copy.write_row(ligne)
    return len(lignes)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--tables", nargs="+", default=TABLES, choices=TABLES)
    args = p.parse_args()

    url = lire_env()
    if not WAREHOUSE.exists():
        raise SystemExit("warehouse.duckdb introuvable : lance d'abord load_raw.py puis dbt build.")

    with duckdb.connect(str(WAREHOUSE), read_only=True) as duck, psycopg.connect(url, autocommit=True, prepare_threshold=None) as pg:
        pg.execute(f'create schema if not exists "{SCHEMA_CIBLE}"')
        for table in args.tables:
            debut = time.time()
            n = exporter_table(duck, pg, table)
            print(f"{table:<28} {n:>10,} lignes  ({time.time() - debut:.1f}s)")
    print(f"\nExport terminé vers le schéma « {SCHEMA_CIBLE} » de Neon.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
