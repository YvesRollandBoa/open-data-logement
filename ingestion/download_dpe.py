"""Télécharge les DPE des logements existants (ADEME) par département via l'API data-fair.

L'API renvoie les lignes par pages ; on suit le lien `next` jusqu'au bout.
Chaque département est écrit dans data/raw/dpe/<dep>.ndjson.gz (une ligne JSON par DPE).

Reprise sur incident : après chaque page, l'URL de la page suivante est sauvegardée
dans <dep>.next. Si le script est interrompu (coupure réseau, Ctrl+C), il suffit de
le relancer : il repart de la dernière page téléchargée au lieu de tout refaire.

Usage :
    python ingestion/download_dpe.py
    python ingestion/download_dpe.py --deps 59 --force

Compter quelques minutes par département (le Nord seul dépasse 600 000 DPE).
"""
import argparse
import gzip
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

from config import DEPARTEMENTS, DPE_API, DPE_CHAMPS, RAW_DIR

DEST = RAW_DIR / "dpe"
TAILLE_PAGE = 5_000  # pages plus petites = moins de timeouts côté API


def get_json(url: str, tentatives: int = 6) -> dict:
    for essai in range(1, tentatives + 1):
        try:
            with urllib.request.urlopen(url, timeout=180) as rep:
                return json.load(rep)
        except urllib.error.HTTPError as e:
            # 429 = trop de requêtes : on attend plus longtemps
            attente = 30 if e.code == 429 else 5 * essai
            print(f"\n    HTTP {e.code}, nouvel essai dans {attente}s ({essai}/{tentatives})")
            time.sleep(attente)
        except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
            print(f"\n    erreur réseau ({e}), essai {essai}/{tentatives}")
            time.sleep(5 * essai)
    raise RuntimeError(f"Échec après {tentatives} essais — relancer le script pour reprendre.")


def telecharger_departement(dep: str) -> int:
    cible = DEST / f"{dep}.ndjson.gz"
    partiel = DEST / f"{dep}.ndjson.gz.part"
    reprise = DEST / f"{dep}.next"

    if partiel.exists() and reprise.exists():
        url = reprise.read_text().strip()
        with gzip.open(partiel, "rt", encoding="utf-8") as f:
            n = sum(1 for _ in f)
        print(f"    reprise après {n:,} lignes")
    else:
        params = {
            "qs": f"code_departement_ban:{dep}",
            "select": ",".join(DPE_CHAMPS),
            "size": TAILLE_PAGE,
        }
        url = f"{DPE_API}?{urllib.parse.urlencode(params)}"
        partiel.unlink(missing_ok=True)
        n = 0

    while url:
        page = get_json(url)
        if n == 0 and isinstance(page.get("total"), int):
            print(f"    {page['total']:,} DPE annoncés")
        # Mode "a" : chaque page devient un membre gzip distinct, relu sans problème.
        with gzip.open(partiel, "at", encoding="utf-8") as f:
            for ligne in page.get("results", []):
                ligne.pop("_score", None)
                f.write(json.dumps(ligne, ensure_ascii=False) + "\n")
                n += 1
        url = page.get("next")
        if url:
            reprise.write_text(url)
        print(f"    {n:,} lignes", end="\r")

    partiel.rename(cible)
    reprise.unlink(missing_ok=True)
    print(f"    {n:,} lignes écrites")
    return n


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--deps", nargs="+", default=DEPARTEMENTS)
    p.add_argument("--force", action="store_true")
    args = p.parse_args()

    DEST.mkdir(parents=True, exist_ok=True)
    echecs = []
    for dep in args.deps:
        if args.force:
            for suffixe in (".ndjson.gz", ".ndjson.gz.part", ".next"):
                (DEST / f"{dep}{suffixe}").unlink(missing_ok=True)
        if (DEST / f"{dep}.ndjson.gz").exists():
            print(f"[skip] DPE {dep}")
            continue
        print(f"[get ] DPE {dep}")
        try:
            telecharger_departement(dep)
        except RuntimeError as e:
            print(f"\n    {e}")
            echecs.append(dep)

    if echecs:
        print(f"\nDépartements incomplets : {', '.join(echecs)} — relancer le script pour reprendre.")
        return 1
    print("\nTéléchargement DPE terminé.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
