"""Télécharge la base du comparateur de territoires de l'INSEE (fichier Parquet, ~9 Mo).

Format « long » : une ligne par territoire × indicateur × période
(colonnes GEO, TAB_MEASURE, TIME_PERIOD, OBS_VALUE…). Le pivot se fait dans dbt.

Usage :
    python ingestion/download_insee.py [--force]
"""
import argparse
import sys
import urllib.request

from config import INSEE_COMPARATEUR_URL, RAW_DIR

CIBLE = RAW_DIR / "insee" / "comparateur.parquet"


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--force", action="store_true")
    args = p.parse_args()

    if CIBLE.exists() and not args.force:
        print("[skip] INSEE comparateur")
        return 0
    CIBLE.parent.mkdir(parents=True, exist_ok=True)
    print("[get ] INSEE comparateur")
    tmp = CIBLE.with_suffix(".part")
    req = urllib.request.Request(INSEE_COMPARATEUR_URL, headers={"User-Agent": "open-data-logement"})
    with urllib.request.urlopen(req, timeout=120) as rep, open(tmp, "wb") as f:
        f.write(rep.read())
    tmp.rename(CIBLE)
    print(f"    {CIBLE.stat().st_size / 1e6:.1f} Mo écrits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
