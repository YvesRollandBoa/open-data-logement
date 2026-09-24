"""Charge les fichiers bruts dans DuckDB (schéma `raw`), sans transformation.

Toutes les colonnes sont lues en texte : le typage se fait dans dbt (staging),
ce qui évite de perdre les zéros des codes (ex. département "02", commune "02001")
et garde la couche raw fidèle à la source.

Usage :
    python ingestion/load_raw.py
"""
import sys

import duckdb

from config import RAW_DIR, WAREHOUSE


def charger_dvf(con: duckdb.DuckDBPyConnection) -> None:
    fichiers = sorted((RAW_DIR / "dvf").glob("*/*.csv.gz"))
    if not fichiers:
        raise SystemExit("Aucun fichier DVF trouvé : lance d'abord ingestion/download_dvf.py")

    motif = str(RAW_DIR / "dvf" / "*" / "*.csv.gz")
    con.execute("create schema if not exists raw")
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
    n = con.execute("select count(*) from raw.dvf_mutations").fetchone()[0]
    print(f"raw.dvf_mutations : {n:,} lignes depuis {len(fichiers)} fichier(s)")


def main() -> int:
    WAREHOUSE.parent.mkdir(parents=True, exist_ok=True)
    with duckdb.connect(str(WAREHOUSE)) as con:
        charger_dvf(con)
    return 0


if __name__ == "__main__":
    sys.exit(main())
