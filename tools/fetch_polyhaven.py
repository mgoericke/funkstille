#!/usr/bin/env python3
"""Laedt eine Poly-Haven-Textur (CC0) nach assets/textures/<id>/ und ergaenzt CREDITS.md.

Aufruf: python3 tools/fetch_polyhaven.py <asset_id> [--res 2k]
Nur Standardbibliothek. Mehrfacher Aufruf ist idempotent (CREDITS-Zeile genau einmal).
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

API = "https://api.polyhaven.com"
HEADERS = {"User-Agent": "Funkstille/0.1"}
# Poly-Haven-Map-Name -> Dateiname im Projekt
MAPS = {"Diffuse": "diffuse", "nor_gl": "normal", "Rough": "rough", "AO": "ao"}
# Pflicht-Maps: ohne sie bricht der Download ab
REQUIRED = ("Diffuse", "nor_gl")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def write_import(dest: str, normal: bool) -> None:
    """Schreibt die .import-Datei mit 3D-Einstellungen (VRAM-Kompression, Mipmaps).

    Der headless-Import erkennt sonst nicht, dass die Textur im 3D-Material landet, und
    importiert verlustfrei ohne Mipmaps (Flimmern, 2k unkomprimiert).
    """
    text = (
        '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n'
        "compress/mode=2\ncompress/high_quality=false\ncompress/lossy_quality=0.7\n"
        f"compress/normal_map={1 if normal else 0}\n"
        "mipmaps/generate=true\nmipmaps/limit=-1\n"
        "process/fix_alpha_border=true\ndetect_3d/compress_to=1\n"
    )
    open(dest + ".import", "w").write(text)


def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=120) as r:
        return r.read()


def add_credit(asset_id: str) -> None:
    info = json.loads(get(f"{API}/info/{asset_id}"))
    authors = ", ".join(info.get("authors", {}).keys()) or "Poly Haven"
    url = f"https://polyhaven.com/a/{asset_id}"
    path = os.path.join(ROOT, "CREDITS.md")
    text = open(path, encoding="utf-8").read()
    if url + " |" in text:
        return
    if not text.endswith("\n"):
        text += "\n"
    text += f"| Textur `{asset_id}` ({info.get('name', asset_id)}) | {url} | {authors} | CC0 |\n"
    open(path, "w", encoding="utf-8").write(text)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("asset_id")
    ap.add_argument("--res", default="2k")
    a = ap.parse_args()
    try:
        files = json.loads(get(f"{API}/files/{a.asset_id}"))
        out = os.path.join(ROOT, "assets", "textures", a.asset_id)
        os.makedirs(out, exist_ok=True)
        for key, name in MAPS.items():
            try:
                url = files[key][a.res]["jpg"]["url"]
            except (KeyError, TypeError):
                if key in REQUIRED:
                    sys.exit(f"Fehler: {a.asset_id} hat keine Map {key} in {a.res}/jpg")
                print(f"  {key}: nicht in {a.res}/jpg vorhanden, uebersprungen")
                continue
            dest = os.path.join(out, name + ".jpg")
            if not os.path.exists(dest):
                open(dest, "wb").write(get(url))
            write_import(dest, name == "normal")
            print(f"  {dest}")
        add_credit(a.asset_id)
    except (urllib.error.HTTPError, urllib.error.URLError) as e:
        sys.exit(f"Fehler beim Laden von {a.asset_id}: {e}")


if __name__ == "__main__":
    main()
