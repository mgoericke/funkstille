#!/usr/bin/env python3
"""Laedt eine Poly-Haven-Textur (CC0) nach assets/textures/<id>/ und ergaenzt CREDITS.md.

Aufruf: python3 tools/fetch_polyhaven.py <asset_id> [--res 2k]
Nur Standardbibliothek. Mehrfacher Aufruf ist idempotent (CREDITS-Zeile genau einmal).
"""
import argparse
import json
import os
import urllib.request

API = "https://api.polyhaven.com"
HEADERS = {"User-Agent": "Funkstille/0.1"}
# Poly-Haven-Map-Name -> Dateiname im Projekt
MAPS = {"Diffuse": "diffuse", "nor_gl": "normal", "Rough": "rough", "AO": "ao"}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=120) as r:
        return r.read()


def add_credit(asset_id: str) -> None:
    info = json.loads(get(f"{API}/info/{asset_id}"))
    authors = ", ".join(info.get("authors", {}).keys()) or "Poly Haven"
    url = f"https://polyhaven.com/a/{asset_id}"
    path = os.path.join(ROOT, "CREDITS.md")
    text = open(path, encoding="utf-8").read()
    if url in text:
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
    files = json.loads(get(f"{API}/files/{a.asset_id}"))
    out = os.path.join(ROOT, "assets", "textures", a.asset_id)
    os.makedirs(out, exist_ok=True)
    for key, name in MAPS.items():
        try:
            url = files[key][a.res]["jpg"]["url"]
        except KeyError:
            print(f"  {key}: nicht in {a.res}/jpg vorhanden, uebersprungen")
            continue
        dest = os.path.join(out, name + ".jpg")
        if not os.path.exists(dest):
            open(dest, "wb").write(get(url))
        print(f"  {dest}")
    add_credit(a.asset_id)


if __name__ == "__main__":
    main()
