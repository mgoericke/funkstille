# Funkstille – Design

Stand: 2026-10-20 · Arbeitsname: **Funkstille**

## Worum es geht

Eine kleine, spielbare Demo (5–10 Minuten), die die *Atmosphäre* von The Last of Us aufgreift – Verfall, zurückeroberte Natur, Stille, die bedrohlich wird, ein Funken Hoffnung – ohne Figuren, Szenen, Namen, Kreaturen-Design oder Musik daraus zu übernehmen.

Der User ist großer TLOU-Fan und will etwas Eigenes in diesem Geist: **grafisch hochwertig, mit immersiver Tiefe.** Lieber ein kleiner, dicht gestalteter Ort als eine große, leere Welt.

## Die Erfahrung

Berlin, rund 20 Jahre nach dem Zusammenbruch. Ein überwucherter U-Bahnhof. Der Spieler sieht durch die Augen der Figur (Ich-Perspektive), hat eine Taschenlampe und ein Funkgerät, das einem schwachen Signal folgt.

### Ablauf (vier Abschnitte)

1. **Einstieg – Wartungsgang.** Dunkel, eng. Der Spieler lernt nebenbei Gehen, Schleichen, Taschenlampe, Funkgerät. Das Funkgerät rauscht; je näher man dem Signal kommt, desto klarer wird es – es *führt*.
2. **Tunnel.** Entlang der Gleise, an einem verlassenen Zug vorbei (evtl. hindurch). Wurzeln brechen durch Kacheln, Wasser tropft, Lichtkegel im Staub. Die Bedrohung wird angedeutet: ferne Geräusche, Spuren, etwas bewegt sich außer Sicht. Noch keine echte Gefahr.
3. **Bahnsteig – Höhepunkt.** Der **Lauscher** steht zwischen Spieler und Ausgangstreppe. Das Rauschen des Funkgeräts lockt ihn an – das Werkzeug, das bisher geführt hat, wird zum Risiko. Der Spieler muss es ausschalten und ohne Führung weiter.
4. **Aufgang und Ende.** Treppe hoch; das Funkgerät empfängt zum ersten Mal klar – eine echte Stimme: *„…hört mich jemand? Wir sind am Turm. Wir haben Licht.“* Der Spieler tritt auf die zugewachsene Straße, in der Ferne der überwucherte Fernsehturm, oben blinkt ein einzelnes Licht. Abblende, Titel **FUNKSTILLE**.

### Der Lauscher

Ein blinder Infizierter, der nur auf Geräusche reagiert. Eigenes Design – kein Pilzkopf, kein Klick-Geräusch (beides zu nah an TLOU). Richtung: ausgezehrt, milchige Augen, Kopf schief und lauschend, langsam; erkennbar an einem rasselnden Atem, der sich mit seinem Zustand verändert.

- Er hört: Funkgerät-Rauschen, Rennen, Tritte auf Scherben, Flaschenwürfe (am Aufprallort).
- Er hört nicht: Licht (er ist blind), langsames Gehen, Schleichen auf sauberem Boden.
- Zustände, jeweils **hörbar** angekündigt: ruhig umherschlurfen → aufmerksam (stoppt, dreht den Kopf) → nachsehen (geht zur Geräuschquelle) → Jagd.
- Erwischt er den Spieler: kurze Abblende, Neustart **kurz vor dem Bahnsteig**, ohne lange Laufwege.
- *(Claudes Entscheidung)* **Die Jagd ist abschüttelbar:** Wer still wird, sich hinter Deckung zurückzieht oder ein lauteres Geräusch woanders erzeugt, kann ihn verlieren; nach einiger Zeit ohne Geräusch gibt er auf und kehrt zum Umherschlurfen zurück. Er ist in der Jagd schneller als Gehen, aber nicht schneller als Rennen – Rennen ist also eine laute, riskante Rettung, keine Sackgasse.
- *(Claudes Entscheidung)* **Modell:** Realistische Basis aus MPFB/MakeHuman (Blender-Add-on, Ausgabe CC0, mit Rig), in Blender verformt und gealtert; Animationen selbst in Blender erstellt bzw. prozedural in Godot ergänzt. Quaternius-Figuren sind zu stilisiert für den Look.

## Schwierigkeit: fordernd, aber nie ausweglos

Das ist die wichtigste Leitlinie des Users. Daraus folgt:

- Es gibt immer **mindestens zwei Wege** an der Gefahr vorbei – z. B. am Bahnsteigrand im Schutz von Säulen/Zug schleichen *oder* mit einer Flasche weglocken.
- Der Lauscher **verrät durch Geräusche**, was er gerade tut; ein Fehler fühlt sich nie unfair an.
- Scherben sind sichtbar, wenn man mit der Taschenlampe hinschaut (die Lampe hat dadurch auch am Höhepunkt einen Zweck).
- Flaschen liegen in Reichweite des Bahnsteigs; man kann nicht „ohne Munition“ festhängen.
- Neustarts sind schnell.

## Steuerung

Maus + Tastatur **und** Controller, Wechsel jederzeit im Spiel, Belegung je Gerät. Aktionen: Gehen, Umsehen, Schleichen (ducken), Rennen (laut), Taschenlampe an/aus, Funkgerät an/aus, Flasche aufheben/werfen, Interagieren.

## Grafik und Klang

Ziel ist „grafisch hochwertig“ im Rahmen von Godot. Ausgeschöpft wird u. a.: Forward+-Renderer, globale Beleuchtung (SDFGI, VoxelGI oder gebackene Lightmaps – Wahl beim Builder, nach Qualität in dieser engen Innenszene), Volumetric Fog für Lichtkegel und Staub, PBR-Materialien, Decals für Schmutz/Wasserflecken, Post-Processing (Filmkorn, dezente Vignette, Tiefenunschärfe, automatische Belichtung – v. a. beim Schritt ins Tageslicht).

Klang trägt die Immersion mindestens zur Hälfte: positionaler 3D-Sound, Hall im Tunnel, Tropfen, entfernte Geräusche, Atem des Lauschers, Funkrauschen, das sich mit der Signalnähe verändert, die Stimme am Ende.

**Hardware des Users:** MacBook Pro M1 Max (24-Kern-GPU, 64 GB RAM), Retina 3024×1964. Ziel: flüssig (~60 fps) bei interner Auflösung 1080p–1440p mit Hochskalierung.

## Ziele, Nicht-Ziele, Anti-Ziele

**Ziele**
- Ein Ort, der so dicht und glaubwürdig wirkt, dass man stehen bleibt und sich umsieht.
- Ein echter Spannungs-Höhepunkt am Bahnsteig.
- Ein Ende, das nach der Dunkelheit Hoffnung gibt.

**Nicht-Ziele**
- Kein Kampf, keine Waffen. Überleben nur durch Vorsicht.
- Keine sichtbare Spielfigur, kein Inventar-Menü, keine offene Welt, kein Speichersystem außer dem Checkpoint.

**Anti-Ziele** – würde als Fehlschlag zählen, auch wenn es technisch läuft:
- Die Gefahr wirkt unfair oder ausweglos.
- Es sieht nach „Programmierer-Grafik“ aus (klobige Primitive, flache Beleuchtung, leere Flächen).
- Es wirkt wie eine Kopie von TLOU.

## Rahmenbedingungen

- **Software:** nur frei und lokal, vollständig von Claude per Kommandozeile steuerbar.
  - Godot 4.7.2 (`/Applications/Godot.app`, headless lauffähig)
  - Blender 5.2.2 LTS (`/Applications/Blender.app`, per Python `-b` steuerbar) – für eigene Modelle, Anpassung des Lauschers, Konvertierung, LODs, Backen
- **Assets:** CC0 bevorzugt; **CC-BY und freie Soundpakete sind erlaubt** (Entscheidung des Users), solange sie ohne Login herunterladbar sind. Quellen u. a.: Poly Haven, ambientCG, MPFB/MakeHuman (Grafik); OpenGameArt, Sonniss-GDC-Bundles (Sound); fehlende Klänge werden synthetisiert. Jedes Asset mit Herkunft, Autor und Lizenz in einer **`CREDITS.md`**.
- **Veröffentlichung:** Funkstille kommt **öffentlich auf GitHub**, wie der Kiezkicker (Entscheidung des Users). Daher: nur Assets, deren Lizenz öffentliche Weitergabe erlaubt; keine Namen, Begriffe oder Designs aus TLOU in Code, Texten oder Assets.
- **Ort:** `/Users/mark/Projekte/games/funkstille`, eigenes Git-Repo, getrennt vom Kiezkicker (an dem der User parallel arbeitet).
- **Arbeitsweise wie beim Kiezkicker:** Claude prüft selbst mit Headless-Tests und echten Screenshots; der User spielt im Godot-Editor mit F5 und muss nach Änderungen neu starten.

## Dem Builder überlassen

- Genaue Raumaufteilung und Maße der vier Abschnitte, Platzierung von Säulen, Zug, Flaschen, Scherben.
- Wahl der GI-Technik und Qualitätsstufen im Rahmen der Performance-Vorgabe.
- Konkrete Asset-Auswahl und wie viel in Blender selbst modelliert wird.
- Projekt- und Skriptstruktur.
- Die Stimme am Ende (Aufnahme, Synthese oder bearbeitetes CC0-Material) – sie muss glaubwürdig klingen und durch Funk gefiltert sein.
