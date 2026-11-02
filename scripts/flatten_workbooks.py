"""Aplatit un classeur Excel multi-onglets en un seul fichier CSV.

Le connecteur File d'Airbyte empile les onglets d'un classeur sans conserver
leur nom. Ce script comble uniquement ce manque : il ajoute une colonne
`sheet_name` contenant le nom de l'onglet d'origine.

Aucune autre transformation : les valeurs sont lues et réécrites telles quelles
(en texte, avec leurs unités), sans nettoyage, sans conversion, sans filtre.
Toute la logique de transformation reste dans dbt.

Usage :
    python scripts/flatten_workbooks.py data/wu_ichtegem_be.xlsx data/wu_la_madeleine_fr.xlsx

Un fichier .csv du même nom est créé à côté de chaque classeur.
Dépendances : pip install pandas openpyxl
"""
import sys
from pathlib import Path

import pandas as pd


def flatten(xlsx_path: Path) -> Path:
    # sheet_name=None : tous les onglets, dans l'ordre ; dtype=str : aucune conversion
    sheets = pd.read_excel(xlsx_path, sheet_name=None, dtype=str)
    frames = []
    for name, df in sheets.items():
        print(f"  onglet {name} : {len(df)} lignes")
        frames.append(df.assign(sheet_name=name))
    out = xlsx_path.with_suffix(".csv")
    pd.concat(frames, ignore_index=True).to_csv(out, index=False, encoding="utf-8")
    return out


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for arg in sys.argv[1:]:
        path = Path(arg)
        print(path.name)
        out = flatten(path)
        print(f"  -> {out.name}")
