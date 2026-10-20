# Look-Probe: Ergebnis

Ein 12 m langes Tunnelstück (`scenes/look_probe.tscn`) mit PBR-Kacheln, Beton, Schotter, Rost,
Volumetric Fog, Taschenlampe, Lichtschacht in der Decke und Staub. Gemessen auf MacBook Pro
M1 Max, Fenster 1920×1080, `scaling_3d_mode` FSR2 bei 0,75, V-Sync aus, 5 s Durchschnitt:

| GI-Variante | fps | Bild |
|---|---|---|
| SDFGI | 106,8 | `docs/screenshots/look-sdfgi.png` |
| VoxelGI (128er Unterteilung, zur Laufzeit gebacken) | 106,3 | `docs/screenshots/look-voxelgi.png` |
| ohne GI | 149,1 | `docs/screenshots/look-none.png` |

Korrektur: Die ersten Messungen (SDFGI ca. 72, VoxelGI ca. 75, ohne GI ca. 106 fps) liefen mit
falsch importierten Texturen (unkomprimiert, ohne Mipmaps). Die Werte oben sind mit VRAM-Kompression
und Mipmaps gemessen; die .import-Dateien schreibt jetzt `tools/fetch_polyhaven.py`.

## Entscheidung: SDFGI

Alle drei Varianten erreichen ≥ 60 fps. SDFGI ist dem VoxelGI visuell mindestens ebenbürtig
(sanfte Rost-Streuung an der rechten Wand, weiche Schattenränder), braucht aber kein Backen
und deckt das ganze Level automatisch ab. VoxelGI müsste pro Bereich gebacken werden. Mit
Notlichtern und einem Umgebungsanteil sind die Unterschiede zwischen den Varianten im Tunnel
klein; „ohne GI" sieht nur dank des Ambient-Anteils fast gleich gut aus, hat aber keine
Farbstreuung vom Rost und keine Lichtübernahme vom Lichtschacht.

## Auffälligkeiten

- Das Bild trägt: Kachelfugen, Kratzer im Beton, Schotter und Rost lesen sich im Taschenlampenlicht
  als echte PBR-Oberflächen; der Kegel im Nebel und der Lichtschacht stehen sichtbar im Raum.
- Der Raum ist schnell zu hell: Ambient 0,1 plus zwei schwache Notlichter reichen. Mehr Ambient
  macht ihn grün und flach, weniger lässt die Ecken im Schwarz absaufen (erste Fassung).
- Auto-Belichtung liegt in Godot in `CameraAttributesPractical`, nicht im `Environment`;
  `Look.make_camera_attributes()` liefert sie.
- SDFGI und der Nebel kosten etwa 40 fps gegenüber „ohne GI"; bei dem 175 m langen
  Level bleibt trotzdem eine Reserve von rund 45 fps über 60. Zuerst kürzen: SDFGI-Kaskaden 4 → 3, Nebel-Länge,
  SSIL aus, FSR2-Skalierung auf 0,67.
- Taschenlampenkegel hat noch einen sichtbar harten Fleck auf dem Boden (Nebel-Fleck am Kegelrand
  bei z -9); beim Level feintunen.
- Texturen: `long_white_tiles`, `concrete_floor_worn_001`, `rocky_gravel`, `rust_coarse_01` (alle 2k).
- Staub ist klein, gedämpft und gelit (nicht selbstleuchtend), nur im Lichtkegel sichtbar.
