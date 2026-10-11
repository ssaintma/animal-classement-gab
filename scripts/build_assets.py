#!/usr/bin/env python3
"""Régénère sheet.webp et la constante DATA de index.html à partir de la liste publique des villageois.

Les classements enregistrés pointent vers la position de chaque villageois dans DATA.
Ce script ne réordonne donc jamais l'existant: les villageois déjà présents gardent leur index,
les nouveaux sont ajoutés à la fin (triés par nom). Il refuse de continuer si un villageois
présent dans index.html a disparu de la source.

Usage (depuis la racine du dépôt):
    python3 -m venv .venv && .venv/bin/pip install pillow
    .venv/bin/python scripts/build_assets.py

Puis relire `git diff`, ouvrir la page en local, et seulement ensuite pousser.
"""
import concurrent.futures
import json
import math
import re
import sys
import urllib.request
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = "https://raw.githubusercontent.com/Norviah/animal-crossing/master/json/data/Villagers.json"
COLS, SIZE = 21, 64  # colonnes de la planche, côté d'une icône en pixels
DISPLAY_SIZES = (56, 48)  # tailles d'affichage (.h56 et .h48 dans le CSS)


def get(url):
    with urllib.request.urlopen(url, timeout=30) as r:
        return r.read()


def main():
    index = ROOT / "index.html"
    html = index.read_text(encoding="utf-8")
    m = re.search(r"var DATA = '([^']*)';", html)
    if not m:
        sys.exit("Constante DATA introuvable dans index.html")
    current = [e.split("|") for e in m.group(1).split(";")]  # [[nom, espèce], ...]

    source = [v for v in json.loads(get(SRC)) if v.get("iconImage")]
    by_name = {v["translations"]["eUfr"]: v for v in source}
    if len(by_name) != len(source):
        sys.exit("Deux villageois ont le même nom français: l'identification par nom n'est plus sûre.")

    missing = [name for name, _ in current if name not in by_name]
    if missing:
        sys.exit("Villageois présents dans index.html mais absents de la source: %s" % ", ".join(missing))

    known = {name for name, _ in current}
    added = sorted(
        (v for name, v in by_name.items() if name not in known),
        key=lambda v: v["translations"]["eUfr"].lower(),
    )
    order = [by_name[name] for name, _ in current] + added
    entries = [e[0] + "|" + e[1] for e in current] + [
        v["translations"]["eUfr"] + "|" + v["species"] for v in added
    ]
    print("%d villageois, dont %d nouveaux" % (len(order), len(added)))

    def icon(v):
        return Image.open(BytesIO(get(v["iconImage"]))).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        icons = list(pool.map(icon, order))

    rows = math.ceil(len(order) / COLS)
    sheet = Image.new("RGBA", (COLS * SIZE, rows * SIZE), (0, 0, 0, 0))
    for i, im in enumerate(icons):
        sheet.paste(im, ((i % COLS) * SIZE, (i // COLS) * SIZE))
    sheet.save(ROOT / "sheet.webp", quality=85)

    html = html.replace(m.group(0), "var DATA = '" + ";".join(entries) + "';")
    for d in DISPLAY_SIZES:
        html = re.sub(
            r"(\.h%d\{[^}]*background-size:)[^;}]*" % d,
            lambda mm, d=d: "%s%dpx %dpx" % (mm.group(1), COLS * d, rows * d),
            html,
        )
    index.write_text(html, encoding="utf-8")
    print("sheet.webp et index.html mis à jour (%d lignes dans la planche)" % rows)


if __name__ == "__main__":
    main()
