"""Télécharge les fichiers DVF géolocalisés (geo-dvf, Etalab) par année et département.

Usage :
    python ingestion/download_dvf.py                      # config par défaut
    python ingestion/download_dvf.py --deps 59 62 --annees 2024 2025
    python ingestion/download_dvf.py --force              # re-télécharge tout

Les fichiers déjà présents sont ignorés (téléchargement idempotent).
"""
import argparse
import sys
import time
import urllib.error
import urllib.request

from config import ANNEES_DVF, DEPARTEMENTS, DVF_URL, RAW_DIR

DEST = RAW_DIR / "dvf"


def telecharger(url: str, cible, tentatives: int = 3) -> bool:
    tmp = cible.with_suffix(cible.suffix + ".part")
    for essai in range(1, tentatives + 1):
        try:
            with urllib.request.urlopen(url, timeout=120) as rep, open(tmp, "wb") as f:
                while bloc := rep.read(1 << 20):
                    f.write(bloc)
            tmp.rename(cible)
            return True
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"  absent (404) : {url}")
                return False
            print(f"  HTTP {e.code}, essai {essai}/{tentatives}")
        except (urllib.error.URLError, TimeoutError) as e:
            print(f"  erreur réseau ({e}), essai {essai}/{tentatives}")
        time.sleep(2 * essai)
    tmp.unlink(missing_ok=True)
    return False


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--deps", nargs="+", default=DEPARTEMENTS)
    p.add_argument("--annees", nargs="+", type=int, default=ANNEES_DVF)
    p.add_argument("--force", action="store_true")
    args = p.parse_args()

    echecs = []
    for annee in args.annees:
        for dep in args.deps:
            cible = DEST / str(annee) / f"{dep}.csv.gz"
            cible.parent.mkdir(parents=True, exist_ok=True)
            if cible.exists() and not args.force:
                print(f"[skip] {annee}/{dep}")
                continue
            print(f"[get ] {annee}/{dep}")
            if not telecharger(DVF_URL.format(annee=annee, dep=dep), cible):
                echecs.append(f"{annee}/{dep}")

    if echecs:
        print(f"\n{len(echecs)} fichier(s) non récupéré(s) : {', '.join(echecs)}")
        return 1
    print("\nTéléchargement DVF terminé.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
