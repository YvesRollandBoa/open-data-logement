"""Charge les fichiers bruts dans DuckDB (schéma `raw`), sans transformation.

Les colonnes des fichiers CSV/JSON sont lues en texte : le typage se fait dans dbt
(staging), ce qui évite de perdre les zéros des codes (ex. département "02",
commune "02001") et garde la couche raw fidèle à la source.

Chaque source est chargée si ses fichiers sont présents, ignorée sinon.

Usage :
    python ingestion/load_raw.py
"""
import sys

import duckdb

from config import RAW_DIR, WAREHOUSE


def charger_dvf(con: duckdb.DuckDBPyConnection) -> bool:
    fichiers = sorted((RAW_DIR / "dvf").glob("*/*.csv.gz"))
    if not fichiers:
        return False
    motif = str(RAW_DIR / "dvf" / "*" / "*.csv.gz")
    con.execute(f"""
        create or replace table raw.dvf_mutations as
        select
            *,
            regexp_extract(filename, '(\\d{{4}})[/\\\\][^/\\\\]+$', 1) as _annee_fichier,
            current_timestamp as _loaded_at
        from read_csv(
            '{motif}',
            header = true,
            all_varchar = true,
            union_by_name = true,
            filename = true
        )
    """)
    compter(con, "raw.dvf_mutations", len(fichiers))
    return True


def charger_dpe(con: duckdb.DuckDBPyConnection) -> bool:
    fichiers = sorted((RAW_DIR / "dpe").glob("*.ndjson.gz"))
    if not fichiers:
        return False
    motif = str(RAW_DIR / "dpe" / "*.ndjson.gz")
    con.execute(f"""
        create or replace table raw.dpe_logements as
        select
            *,
            current_timestamp as _loaded_at
        from read_json(
            '{motif}',
            format = 'newline_delimited',
            union_by_name = true,
            -- tout en texte, comme pour DVF : le typage est fait par dbt
            columns = {{
                numero_dpe: 'VARCHAR', numero_dpe_remplace: 'VARCHAR',
                date_etablissement_dpe: 'VARCHAR', code_insee_ban: 'VARCHAR',
                nom_commune_ban: 'VARCHAR', code_departement_ban: 'VARCHAR',
                identifiant_ban: 'VARCHAR', type_batiment: 'VARCHAR',
                periode_construction: 'VARCHAR', annee_construction: 'VARCHAR',
                surface_habitable_logement: 'VARCHAR', etiquette_dpe: 'VARCHAR',
                etiquette_ges: 'VARCHAR', conso_5_usages_par_m2_ep: 'VARCHAR',
                emission_ges_5_usages_par_m2: 'VARCHAR'
            }}
        )
    """)
    compter(con, "raw.dpe_logements", len(fichiers))
    return True


def charger_insee(con: duckdb.DuckDBPyConnection) -> bool:
    fichier = RAW_DIR / "insee" / "comparateur.parquet"
    if not fichier.exists():
        return False
    # Parquet : les types sont déjà définis par l'INSEE, on garde tel quel.
    con.execute(f"""
        create or replace table raw.insee_comparateur as
        select *, current_timestamp as _loaded_at
        from read_parquet('{fichier}')
    """)
    compter(con, "raw.insee_comparateur", 1)
    return True


def compter(con, table: str, nb_fichiers: int) -> None:
    n = con.execute(f"select count(*) from {table}").fetchone()[0]
    print(f"{table:<24} {n:>12,} lignes  ({nb_fichiers} fichier(s))")


def main() -> int:
    WAREHOUSE.parent.mkdir(parents=True, exist_ok=True)
    with duckdb.connect(str(WAREHOUSE)) as con:
        con.execute("create schema if not exists raw")
        charges = {
            "DVF": charger_dvf(con),
            "DPE": charger_dpe(con),
            "INSEE": charger_insee(con),
        }
    manquants = [nom for nom, ok in charges.items() if not ok]
    if manquants:
        print(f"Non chargé (fichiers absents) : {', '.join(manquants)}")
    if not any(charges.values()):
        print("Aucune donnée : lance d'abord les scripts download_*.py")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
