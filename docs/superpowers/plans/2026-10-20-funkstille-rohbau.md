# Funkstille – Teil 1: Spielbarer Rohbau – Umsetzungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die ganze Demo ist von Anfang bis Titel spielbar – Wartungsgang, Tunnel, Bahnsteig mit Lauscher, Aufgang, Ende – in schlichter Rohbau-Geometrie mit Platzhalter-Klängen, dazu eine Look-Probe, die beweist, dass der hochwertige Look auf dem M1 Max läuft.

**Architecture:** Godot 4.7, alles per GDScript aus Code aufgebaut (wie beim Kiezkicker). Ein Autoload `Noise` verteilt Geräusch-Ereignisse; Spieler, Funkgerät, Flaschen und Scherben senden, der Lauscher hört zu. Alle Spielwerte stehen in `scripts/tuning.gd`. Tests laufen headless über `extends SceneTree`-Skripte.

**Tech Stack:** Godot 4.7.2 (Forward+), GDScript, Python 3 (nur Standardbibliothek) für Asset-Download und Platzhalter-Sounds, `gh` für GitHub.

**Spec:** `docs/superpowers/specs/2026-10-20-funkstille-design.md`

**Abgrenzung:** Teil 2 („Look & Klang“: Blender-Modelle, PBR-Materialien im ganzen Level, Lauscher-Modell aus MPFB, echte Sounds, Funkstimme) bekommt einen eigenen Plan, sobald der User den Rohbau gespielt hat. Teil 1 baut die Look-Probe (Task 2) nur, um das Grafikrisiko früh zu klären, und liefert deren Werkzeuge an Teil 2 weiter.

## Global Constraints

- Godot `/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2), Renderer **Forward+**, Physik 120 Hz, Fenster 1920×1080, `stretch/aspect="expand"`.
- Ich-Perspektive; keine sichtbare Spielfigur, kein Inventar-Menü, keine Waffen, kein Speichersystem außer dem Checkpoint.
- Steuerung: Maus+Tastatur **und** Controller, jederzeit wechselbar.
- Keine Namen, Begriffe oder Designs aus The Last of Us in Code, Texten oder Assets (kein „Clicker“, kein Klick-Geräusch, kein Pilzkopf).
- Assets: CC0 bevorzugt, CC-BY und freie Soundpakete erlaubt, nur ohne Login herunterladbar; jedes Asset mit Herkunft, Autor, Lizenz in `CREDITS.md`.
- Repo öffentlich: `github.com/mgoericke/funkstille`. Arbeit auf Branch `rohbau`, Commits mit `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, am Ende PR nach `main`.
- Leitlinie „fordernd, aber nie ausweglos“: immer zwei Wege am Lauscher vorbei, jeder Zustandswechsel hörbar, schneller Neustart kurz vor dem Bahnsteig.
- Kommentare und Texte auf Deutsch, ASCII-Umlaute in Kommentaren wie im Kiezkicker (`ue`, `ae`), echte Umlaute in Spieltexten.

## Review Focus

1. **Spieler fällt vom Bahnsteig ins Gleisbett** → er muss über Rampen zurück nach oben kommen, nie festsitzen. (Test in Task 4: `gleisbett_hat_ausgang`)
2. **Mehrfach erwischt** → jeder Neustart ist identisch: Lauscher am Start in WANDER, Flaschen wieder da, gehaltene Flasche weg, Funkgerät an, kein Rest-Lärm. (Test in Task 8: `neustart_ist_sauber`)
3. **Alle Flaschen verworfen** → der Schleichweg durchs Gleisbett bleibt ohne Flasche lösbar. (Test in Task 10: `schleichweg_ohne_flasche`)
4. **Geräte-Wechsel mitten im Spiel** → Hinweise zeigen sofort die Tasten des zuletzt benutzten Geräts. (Test in Task 8: `hinweise_folgen_geraet`)
5. **Funkgerät nahe am Lauscher wieder einschalten** → lockt ihn sofort an (das ist gewollt, darf aber nicht still bleiben). (Test in Task 6: `funk_lockt_an`)

---

## Dateistruktur

```
funkstille/
  project.godot            Forward+, Fenster, Physik, Autoload Noise
  main.tscn                Wurzel-Node3D mit scripts/main.gd
  scripts/
    tuning.gd              class_name Tuning – alle Spielwerte (Konstanten)
    controls.gd            class_name Controls – Eingabe-Aktionen fuer Tastatur/Maus und Controller
    noise.gd               Autoload "Noise" – Geraeusch-Ereignisse
    look.gd                class_name Look – Environment, PBR-Materialien (aus Task 2, Teil 2 nutzt es weiter)
    look_probe.gd          Look-Probe-Szene (Task 2)
    level.gd               class_name Level – Rohbau-Geometrie, Kollision, Navigation, Marker
    player.gd              class_name Player – Ich-Perspektive, Taschenlampe, Flasche halten/werfen
    radio.gd               class_name Radio – Funkgeraet, Signalstaerke, Rausch-Impulse
    lauscher.gd            class_name Lauscher – blinder Gegner, Zustandsautomat
    bottle.gd              class_name Bottle – werfbare Flasche
    shards.gd              class_name Shards – Scherbenfeld
    hud.gd                 class_name Hud – Abblende, Hinweise, Titel, Untertitel
    ending.gd              class_name Ending – Stimme, Blick zum Turm, Titel
    main.gd                Aufbau, Checkpoint, Neustart
  scenes/look_probe.tscn
  sounds/                  Platzhalter-WAVs aus tools/gen_sounds.py
  assets/textures/<id>/    Poly-Haven-Texturen
  tools/
    fetch_polyhaven.py     Texturen laden + CREDITS-Zeile
    gen_sounds.py          Platzhalter-Sounds synthetisieren
    screenshots.gd         Screenshots + fps-Messung (echtes Fenster)
  tests/
    run.sh, game_test.gd, test_*.gd
  CREDITS.md, README.md, .gitignore
```

## Rohbau-Layout (Task 4 baut genau das)

Laufrichtung ist **−Z**. Maße in Metern, y = Boden.

| Abschnitt | Bereich | Inhalt |
|---|---|---|
| Wartungsgang | z 0 … −20, x −1 … 1, Höhe 2,4 | Spawn `(0, 0, −1)`, Blick −Z |
| Tunnel | z −20 … −80, x −8 … 8, Höhe 5, Boden y 0 | Zugwaggon x −7 … −3, z −40 … −58 (Kollision, zwei Türöffnungen) |
| Bahnsteig-Halle | z −80 … −130, x −10 … 10, Höhe 6 | Gleisbetten x −10 … −4 und 4 … 10 auf y 0; Bahnsteig x −4 … 4 auf y 1,0; Säulen 0,6×0,6 bei x ±2,5 alle 8 m ab z −86 |
| Rampen | 4 Stück, steigen entlang −Z von y 0 auf y 1 | x −6 … −4 und x 4 … 6, jeweils z −82 … −86 und z −124 … −128; oben tritt man seitlich auf den Bahnsteig |
| Checkpoint | `(0, 0, −76)`, Blick −Z | Lauscher dort außer Hörweite (≥ 26 m) |
| Lauscher | Start `(0, 1, −104)` | Patrouille `(−1.5,1,−96)`, `(1.5,1,−112)`, `(0,1,−120)` |
| Flaschen | 4 Stück | `(3.4,1.1,−88)`, `(−3.4,1.1,−90)`, `(−7,0.1,−84)`, `(7,0.1,−84)` |
| Scherben | 2 Felder (AABB, Boden) | Bahnsteig x 0 … 3,5, z −116 … −121; Gleisbett links x −10 … −7, z −100 … −104 |
| Treppe | z −130 … −142, x −2 … 2, steigt von y 1 auf y 6 | Auslöser „Stimme“: AABB x −2…2, y 1…7, z −130…−134 |
| Straße | z −142 … −175, x −15 … 15, y 6 | Auslöser „Ende“: z ≤ −150 |
| Fernsehturm | `(60, 6, −600)` | Rohbau: Zylinder 8 m × 200 m + Kugel r 16 m bei y 150, blinkendes OmniLight oben |
| Funksignal-Quelle | = Turmspitze `(60, 156, −600)` | |

Vom Tunnel (y 0) kommt man nur über die vorderen Rampen auf den Bahnsteig; die Stirnseite bei z −80 ist eine 1-m-Kante.

Schleichweg A: im linken Gleisbett bei x −8,5 bleiben (vordere Rampe links liegen lassen), am Scherbenfeld (x −10…−7, z −100…−104) bei x −5 vorbei, hintere linke Rampe hoch, seitlich auf den Bahnsteig, zur Treppe. Weg B: Flasche nach rechts/hinten werfen, auf dem Bahnsteig rechts der Säulen vorbei, Scherbenfeld rechts meiden.

---

### Task 1: Projekt-Gerüst, Eingabe, Test-Rahmen, GitHub

**Files:**
- Create: `project.godot`, `main.tscn`, `scripts/main.gd`, `scripts/tuning.gd`, `scripts/controls.gd`, `scripts/noise.gd`, `tests/run.sh`, `tests/game_test.gd`, `tests/test_boot.gd`, `.gitignore` (wie Kiezkicker), `README.md` (Kurzbeschreibung + Steuerung), `CREDITS.md` (Kopf + Tabelle Asset | Quelle | Autor | Lizenz)

**Interfaces:**
- Produces:
  - `Controls.ACTIONS: Dictionary` (Aktionsname → Array[InputEvent]); `static func register() -> void` (idempotent)
  - Aktionen: `move_forward` W/LeftStick−Y, `move_back` S/LeftStick+Y, `move_left` A/LeftStick−X, `move_right` D/LeftStick+X, `look_up/look_down/look_left/look_right` RightStick (Maus-Blick läuft in `Player._unhandled_input`), `crouch` C+Strg/JOY_BUTTON_B, `sprint` Shift/JOY_BUTTON_LEFT_STICK, `flashlight` F/JOY_BUTTON_Y, `radio` R/JOY_BUTTON_X, `interact` E/JOY_BUTTON_A, `throw` Maus links/JOY_AXIS_TRIGGER_RIGHT, `pause` Esc/JOY_BUTTON_START
  - Autoload `Noise`: `signal emitted(pos: Vector3, radius: float, source: StringName)`, `func emit(pos: Vector3, radius: float, source: StringName) -> void`. Quellen: `&"step"`, `&"sprint"`, `&"shards"`, `&"bottle"`, `&"radio"`
  - `Tuning` mit genau diesen Werten (alle späteren Tasks lesen nur von hier):
    `WALK_SPEED 2.8`, `CROUCH_SPEED 1.4`, `SPRINT_SPEED 5.5`, `STEP_DIST 0.75` (Meter pro Schritt), `NOISE_WALK 2.0`, `NOISE_CROUCH 0.0`, `NOISE_SPRINT 9.0`, `NOISE_SHARDS 10.0`, `NOISE_SHARDS_CROUCH 4.0`, `NOISE_BOTTLE 14.0`, `NOISE_RADIO 12.0`, `RADIO_PULSE 0.5`, `L_WANDER 1.0`, `L_INVESTIGATE 1.6`, `L_HUNT 4.2`, `L_ALERT_TIME 1.2`, `L_HUNT_RANGE 6.0`, `L_GIVE_UP 4.0`, `L_SEARCH_TIME 3.0`, `L_CATCH 1.1`, `THROW_SPEED 9.0`, `THROW_UP 2.0`, `MOUSE_SENS 0.0025`, `PAD_LOOK 2.6` (rad/s)
  - `game_test.gd` (wie Kiezkicker): `load_main(start_at := &"spawn") -> void`, `wait(seconds: float)`, `check(ok: bool, what: String)`, `finish()`, `hold(action: StringName, seconds: float)`; setzt `main.gd`-Static `start_at` vor dem Instanziieren
  - `main.gd`: `static var start_at: StringName = &"spawn"`

- [ ] **Step 1: Branch und Gerüst** – `git checkout -b rohbau`; `project.godot` (Name „Funkstille“, Forward+, Werte aus Global Constraints, `[autoload] Noise="*res://scripts/noise.gd"`), `main.tscn`, leeres `main.gd`, das in `_ready` `Controls.register()` aufruft.
- [ ] **Step 2: Failing Test `tests/test_boot.gd`**

```gdscript
check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "Renderer Forward+")
check(Engine.physics_ticks_per_second == 120, "Physik 120 Hz")
for a in Controls.ACTIONS:
    check(InputMap.has_action(a), "Aktion %s vorhanden" % a)
    var kbm := InputMap.action_get_events(a).any(func(e): return e is InputEventKey or e is InputEventMouseButton)
    var pad := InputMap.action_get_events(a).any(func(e): return e is InputEventJoypadButton or e is InputEventJoypadMotion)
    check(pad, "%s hat Controller-Belegung" % a)
    if not (a as String).begins_with("look_"):
        check(kbm, "%s hat Tastatur/Maus-Belegung" % a)
var got := []
Noise.emitted.connect(func(p, r, s): got.append([p, r, s]))
Noise.emit(Vector3(1, 2, 3), 5.0, &"step")
check(got.size() == 1 and got[0][1] == 5.0 and got[0][2] == &"step", "Noise verteilt Ereignisse")
```

- [ ] **Step 3: `tests/run.sh`** wie im Kiezkicker (Godot-Pfad per `GODOT`, Ausgabe filtern auf `^(  |[0-9]+/|[A-Z])`). `bash tests/run.sh` → FAIL (Controls fehlt).
- [ ] **Step 4: `tuning.gd`, `controls.gd`, `noise.gd` umsetzen.**
- [ ] **Step 5: `bash tests/run.sh`** → `N/N Pruefungen bestanden`, Exit 0.
- [ ] **Step 6: Commit + GitHub** – Commit „Projekt-Gerüst, Eingabe und Tests“. Dann `gh repo create mgoericke/funkstille --public --source . --description "Funkstille – kleine First-Person-Demo in einem überwucherten Berliner U-Bahnhof (Godot 4)"`, `git push -u origin main`, `git push -u origin rohbau`.

---

### Task 2: Look-Probe (Grafikrisiko klären)

Ein 12 m langes Tunnelstück in voller Qualität, um vor dem großen Bau zu sehen, ob der Look auf dem M1 Max hält. Ergebnis wird dem User gezeigt.

**Files:**
- Create: `tools/fetch_polyhaven.py`, `scripts/look.gd`, `scripts/look_probe.gd`, `scenes/look_probe.tscn`, `tools/screenshots.gd`, `docs/look-probe.md`
- Modify: `CREDITS.md`

**Interfaces:**
- Produces:
  - `python3 tools/fetch_polyhaven.py <asset_id> [--res 2k]` → lädt über `https://api.polyhaven.com/files/<id>` die Maps Diffuse, nor_gl, Rough, AO (jpg) nach `assets/textures/<id>/{diffuse,normal,rough,ao}.jpg`; holt Autor aus `https://api.polyhaven.com/info/<id>` und ergänzt `CREDITS.md` genau einmal (idempotent). Nur Standardbibliothek.
  - `Look.make_environment() -> Environment` – Tonemap ACES, Volumetric Fog an (Dichte ≈ 0.03, leicht grünlich-grau), Glow, SSAO, SSIL, Auto-Belichtung; GI-Variante per Parameter `gi: StringName` (`&"sdfgi"` oder `&"none"`, VoxelGI wird als Node gesetzt)
  - `Look.pbr(id: String, uv_scale: Vector3 = Vector3.ONE) -> StandardMaterial3D` – lädt die vier Maps aus `assets/textures/<id>/`
  - `Look.flashlight() -> SpotLight3D` – Reichweite 18 m, Winkel 28°, Schatten an, `light_volumetric_fog_energy` > 0
  - `tools/screenshots.gd`: Liste `SHOTS` aus `[szene, kamera-transform-name, dateiname]`, speichert nach `docs/screenshots/`; Umgebungsvariable `FPS=1` misst 5 s Durchschnitts-fps und schreibt sie in die Ausgabe

- [ ] **Step 1: Texturen wählen und laden** – passende IDs über `https://api.polyhaven.com/assets?t=textures` suchen (Kategorien tiles, concrete, dirty/rust); je eins für Kachelwand, Betonboden, Schotter/Gleis, Rost. Laden, `CREDITS.md` prüfen (4 Zeilen, CC0).
- [ ] **Step 2: Look-Probe bauen** – `look_probe.gd` baut das Tunnelstück (Kachelwände mit `Look.pbr`, Boden, zwei Schienen, ein paar Kisten-Primitive als Schutt), eine Deckenlampe aus, Taschenlampe an der Kamera, Staub-Partikel (GPUParticles3D, wenige, langsam), `WorldEnvironment` aus `Look.make_environment`.
- [ ] **Step 3: Headless-Ladetest** `tests/test_look_probe.gd`: Szene instanziieren, 30 Frames, `check(scene.get_node("WorldEnvironment").environment.volumetric_fog_enabled, "Volumetric Fog an")`, `check(Look.pbr("<wand-id>").normal_enabled, "Normal Map geladen")`. Laufen lassen → PASS.
- [ ] **Step 4: Screenshots + fps im Fenster**, je Variante SDFGI / VoxelGI / ohne GI, bei 1920×1080 mit `scaling_3d_scale` 0.75 (FSR2):
  `FPS=1 /Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script res://tools/screenshots.gd`
  Erwartet: drei PNGs in `docs/screenshots/`, fps-Werte in der Ausgabe.
- [ ] **Step 5: Ergebnis festhalten** – `docs/look-probe.md`: fps je Variante, gewählte GI-Technik (Kriterium: schönstes Bild mit ≥ 60 fps), Auffälligkeiten. Screenshots dem User zeigen.
- [ ] **Step 6: Commit** „Look-Probe: Tunnelstück mit PBR, Volumetric Fog, GI-Vergleich“.

---

### Task 3: Spieler in der Ich-Perspektive

**Files:**
- Create: `scripts/player.gd`, `tools/gen_sounds.py`, `tests/test_player.gd`
- Modify: `scripts/main.gd` (Spieler + flacher Testboden, solange kein Level existiert)

**Interfaces:**
- Consumes: `Tuning.*`, `Noise.emit`, Aktionen aus Task 1
- Produces: `class_name Player extends CharacterBody3D`
  - Kinder: `Head` (Node3D, Höhe 1,6 m, geduckt 0,95 m) → `Camera3D` → `Flashlight` (`Look.flashlight()`), `HoldPoint` (Node3D vor der Kamera)
  - `var crouching: bool`, `var sprinting: bool`, `var flashlight_on: bool = true`, `var input_enabled := true`, `var held_bottle: Node3D = null`
  - `signal stepped(pos: Vector3, crouching: bool)` – nach je `Tuning.STEP_DIST` zurückgelegter Bodenstrecke
  - `func step_noise_radius() -> float` – `NOISE_CROUCH` / `NOISE_WALK` / `NOISE_SPRINT`
  - `func toggle_flashlight() -> void`
  - `func reset_to(xform: Transform3D) -> void` – Position, Blickrichtung aus `-xform.basis.z` (Yaw auf den Body, Pitch auf `Head`), Geschwindigkeit 0, nicht geduckt
  - Ducken ist ein Umschalter (Taste drücken), Rennen nur solange gehalten und nicht geduckt
  - bei `stepped` sendet der Spieler selbst `Noise.emit(pos, step_noise_radius(), &"sprint" if sprinting else &"step")`, wenn der Radius > 0
- `gen_sounds.py` (Stil wie Kiezkicker, `random.seed(2026)`): in diesem Task `step_concrete_1..4.wav`, `click_light.wav`

- [ ] **Step 1: Failing Tests `tests/test_player.gd`**

```gdscript
# Gehen: 2 s nach vorn
await load_main()
var p: Player = main.player
var z0 := p.global_position.z
await hold(&"move_forward", 2.0)
check(absf((z0 - p.global_position.z) / 2.0 - Tuning.WALK_SPEED) < 0.4, "Gehen ~2,8 m/s nach -Z")
# Rennen ist schneller, Ducken langsamer
# (analog mit sprint gehalten bzw. crouch getippt) -> ~5,5 bzw. ~1,4 m/s
# Geraeusche
var radii := []
Noise.emitted.connect(func(_p, r, s): radii.append([r, s]))
await hold(&"move_forward", 1.5)
check(radii.size() >= 3 and radii.all(func(x): return x[0] == Tuning.NOISE_WALK), "Gehen macht leise Schritte (2 m)")
radii.clear(); p.crouching = true
await hold(&"move_forward", 1.5)
check(radii.is_empty(), "Geduckt ist lautlos")
# Rennen -> Radius 9, Quelle sprint
# Taschenlampe
var was := p.flashlight_on
await tap(&"flashlight")
check(p.flashlight_on != was and p.get_node("Head/Camera3D/Flashlight").visible == p.flashlight_on, "F schaltet Taschenlampe")
# Kopfhoehe geduckt
check(absf(p.get_node("Head").position.y - 0.95) < 0.05, "Kopf geduckt auf 0,95 m")
# reset_to
p.reset_to(Transform3D(Basis(), Vector3(5, 0, 5)))
check(p.global_position.distance_to(Vector3(5, 0, 5)) < 0.01 and not p.crouching, "reset_to setzt Position und hebt Ducken auf")
```
  (`tap(action)` in `game_test.gd` ergänzen: press, 2 physics frames, release.)
- [ ] **Step 2: `bash tests/run.sh`** → test_player FAIL.
- [ ] **Step 3: `player.gd` umsetzen** – Bewegung relativ zur Blickrichtung (Yaw am Body, Pitch am Head, Pitch ±85°), Maus über `_unhandled_input` (`MOUSE_SENS`, Maus eingefangen; `pause` gibt sie frei), Stick-Blick über `look_*` × `PAD_LOOK`, Schwerkraft, Kopf-Höhe weich nachführen, leichtes Kopfwippen beim Gehen. Schritt-Sounds auf Beton.
- [ ] **Step 4: `python3 tools/gen_sounds.py` und `bash tests/run.sh`** → alle PASS.
- [ ] **Step 5: Commit** „Spieler in Ich-Perspektive mit Taschenlampe und Schrittgeräuschen“.

---

### Task 4: Level-Rohbau mit Navigation

**Files:**
- Create: `scripts/level.gd`, `tests/test_level.gd`
- Modify: `scripts/main.gd` (Testboden durch Level ersetzen, Spieler an `level.spawn` bzw. `level.checkpoint` je nach `start_at`)

**Interfaces:**
- Consumes: `Look.make_environment()` (GI nach Ergebnis aus Task 2), schlichte Materialien (`StandardMaterial3D` grau/braun – PBR kommt in Teil 2)
- Produces: `class_name Level extends Node3D`
  - `func build() -> void` – Geometrie exakt nach Tabelle „Rohbau-Layout“, StaticBody3D-Kollision, Deckenlampen-Reste (wenige, schwache OmniLights), WorldEnvironment
  - Marker (nach `build()` gesetzt): `var spawn: Transform3D`, `var checkpoint: Transform3D`, `var lauscher_start: Vector3`, `var patrol: PackedVector3Array`, `var bottle_spots: PackedVector3Array`, `var shard_zones: Array[AABB]`, `var voice_trigger: AABB`, `var exit_z: float = -150.0`, `var tower_top: Vector3`, `var beacon: Vector3`
  - `var nav_region: NavigationRegion3D` – nur Bahnsteig-Halle inkl. Gleisbetten und Rampen, zur Laufzeit gebacken (`bake_navigation_mesh(false)`), Agent-Radius 0,4, Höhe 1,8, max. Steigung 30°

- [ ] **Step 1: Failing Tests `tests/test_level.gd`** – Hilfsfunktion `floor_y(x, z) -> float` (Strahl von y 10 nach unten, `NAN` ohne Treffer) und `reachable(path: PackedVector3Array) -> bool`, die den Spieler per `hold(&"move_forward")` mit Blick auf den jeweils nächsten Punkt laufen lässt und prüft, dass er ihn auf 0,5 m erreicht.

```gdscript
await load_main()
var L: Level = main.level
check(absf(floor_y(0, -1)) < 0.05, "Spawn steht auf Boden")
check(absf(floor_y(0, -100) - 1.0) < 0.05, "Bahnsteig auf 1 m")
check(absf(floor_y(-7, -100)) < 0.05, "Gleisbett links auf 0 m")
check(absf(floor_y(0, -160) - 6.0) < 0.05, "Strasse auf 6 m")
check(L.shard_zones.size() == 2 and L.bottle_spots.size() == 4, "Marker vollstaendig")
check(L.checkpoint.origin.distance_to(L.lauscher_start) >= 26.0, "Checkpoint ausser Hoerweite")
check(await reachable([Vector3(0,0,-20), Vector3(0,0,-79), Vector3(-5,0,-81), Vector3(-5,1,-86.2), Vector3(0,1,-90), Vector3(0,1,-128), Vector3(0,6,-145), Vector3(0,6,-152)]), "Weg Spawn bis Strasse begehbar")
# gleisbett_hat_ausgang (Review Focus 1)
main.player.reset_to(Transform3D(Basis(), Vector3(-6, 0.2, -110)))
check(await reachable([Vector3(-5,0,-123), Vector3(-5,1,-127.8), Vector3(-3,1,-127.8)]), "Aus dem Gleisbett links wieder hoch")
# analog rechts
var nav_path := NavigationServer3D.map_get_path(L.nav_region.get_navigation_map(), L.lauscher_start, Vector3(-7, 0, -100), true)
check(nav_path.size() > 1, "Navigation verbindet Bahnsteig und Gleisbett")
```
- [ ] **Step 2: Tests laufen lassen** → FAIL.
- [ ] **Step 3: `level.gd` umsetzen.**
- [ ] **Step 4: Tests** → PASS. Ein Screenshot vom Tunnel und vom Bahnsteig über `tools/screenshots.gd` (neue SHOTS-Einträge) zur Sichtprüfung.
- [ ] **Step 5: Commit** „Rohbau-Level: Wartungsgang, Tunnel, Bahnsteig, Treppe, Straße“.

---

### Task 5: Funkgerät

**Files:**
- Create: `scripts/radio.gd`, `tests/test_radio.gd`
- Modify: `scripts/player.gd` (Radio als Kind von `Head`, Aktion `radio`), `tools/gen_sounds.py` (`radio_static.wav` Loop, `radio_tone.wav` Loop, `radio_switch.wav`)

**Interfaces:**
- Consumes: `Noise.emit`, `Level.beacon`
- Produces: `class_name Radio extends Node3D`
  - `var on := true`, `var beacon: Vector3`
  - `func toggle() -> void`
  - `func strength(from: Vector3) -> float` – misst den **Fortschritt entlang der Route**, nicht den Abstand zur Quelle (die ist 600 m weit weg; der Spieler soll aber Fortschritt hören): `t = clamp(-from.z / 150.0, 0, 1)`, `strength = 0.15 + 0.85 * t`. `beacon` dient nur der Richtung (Teil 2: leichtes Richtungs-Panning).
  - `var clear_voice := false` – setzt das Ende auf true: Rauschen aus, nur Ton/Stimme
  - solange `on`: alle `Tuning.RADIO_PULSE` s `Noise.emit(global_position, Tuning.NOISE_RADIO, &"radio")`
  - Klang: Rauschen-Lautstärke `lerp(-6, -22, s)` dB, Ton-Lautstärke `lerp(-40, -8, s)` dB

- [ ] **Step 1: Failing Tests**

```gdscript
await load_main()
var r: Radio = main.player.get_node("Head/Radio")
check(r.on, "Funkgeraet startet eingeschaltet")
check(r.strength(Vector3(0,0,-1)) < r.strength(Vector3(0,1,-100)), "Signal wird zum Ausgang hin staerker")
check(is_equal_approx(r.strength(Vector3(0,6,-160)), 1.0), "Am Ausgang volles Signal")
var pulses := 0
Noise.emitted.connect(func(_p, rad, s): if s == &"radio": pulses += 1)
await wait(2.0)
check(pulses >= 3 and pulses <= 5, "Rauscht alle 0,5 s (Radius 12 m)")
await tap(&"radio")
pulses = 0
await wait(2.0)
check(not r.on and pulses == 0, "R schaltet aus, danach still")
```
- [ ] **Step 2: Tests** → FAIL. **Step 3:** `radio.gd` umsetzen, Sounds erzeugen. **Step 4:** Tests → PASS.
- [ ] **Step 5: Commit** „Funkgerät: Signal wird stärker, Rauschen ist hörbar“.

---

### Task 6: Der Lauscher

**Files:**
- Create: `scripts/lauscher.gd`, `tests/test_lauscher.gd`
- Modify: `scripts/main.gd` (Lauscher an `level.lauscher_start`, verbunden mit `Noise.emitted`), `tools/gen_sounds.py` (`breath_calm.wav`, `breath_alert.wav`, `hunt_rasp.wav`, `step_drag_1..3.wav`)

**Interfaces:**
- Consumes: `Noise.emitted`, `Level.patrol`, `Level.nav_region`, `Player`
- Produces: `class_name Lauscher extends CharacterBody3D`
  - `enum State { WANDER, ALERT, INVESTIGATE, HUNT }`
  - `var state: State`, `var target: Vector3`, `var active := true`, `var player: Player`, `var patrol: PackedVector3Array`
  - `signal caught_player`, `signal state_changed(state: State)`
  - `func hear(pos: Vector3, radius: float, source: StringName) -> void`
  - `func reset_to(pos: Vector3) -> void` – Position, WANDER, Timer zurück, `active = true`
  - Rohbau-Körper: Kapsel 1,75 m, dunkelgrau, Kopf-Kugel leicht schief (echtes Modell in Teil 2)

Regeln (die Tests prüfen genau diese):
- Gehört wird nur, wenn `pos.distance_to(global_position) <= radius`. Licht spielt keine Rolle.
- Spieler-Quellen sind `step`, `sprint`, `shards`, `radio`; `bottle` ist keine Spieler-Quelle.
- Spieler-Quelle mit Abstand ≤ `L_HUNT_RANGE` → sofort HUNT, `target = pos`.
- Sonst aus WANDER/INVESTIGATE/ALERT → ALERT (bleibt stehen, dreht sich zur Quelle, `breath_alert`) für `L_ALERT_TIME`, `target = pos`, danach INVESTIGATE.
- INVESTIGATE: Navigation zu `target` mit `L_INVESTIGATE`; angekommen (< 0,8 m) `L_SEARCH_TIME` lauschen, dann WANDER.
- HUNT: Navigation zu `target` mit `L_HUNT`; jede gehörte Spieler-Quelle aktualisiert `target`; ohne Spieler-Geräusch für `L_GIVE_UP` s → INVESTIGATE (letztes `target`).
- WANDER: Patrouille reihum mit `L_WANDER`, `breath_calm`.
- In jedem Zustand: horizontaler Abstand zum Spieler ≤ `L_CATCH` und |Δy| < 1,2 → `caught_player`, `active = false`.
- Jeder Zustandswechsel spielt seinen Klang sofort (Leitlinie: hörbar, nie unfair) und sendet `state_changed`.

- [ ] **Step 1: Failing Tests** (Spieler per `reset_to` weit weg geparkt, wenn nicht gebraucht)

```gdscript
await load_main(&"checkpoint")
var l: Lauscher = main.lauscher
var at := l.global_position
check(l.state == Lauscher.State.WANDER, "Startet umherschlurfend")
l.hear(at + Vector3(0, 0, 8), 2.0, &"step")
check(l.state == Lauscher.State.WANDER, "Leise Schritte in 8 m: hoert nichts")
l.hear(at + Vector3(0, 0, 10), 14.0, &"bottle")
check(l.state == Lauscher.State.ALERT, "Flasche in 10 m: aufmerksam")
await wait(Tuning.L_ALERT_TIME + 0.2)
check(l.state == Lauscher.State.INVESTIGATE, "Danach nachsehen")
await wait(10.0)
check(l.global_position.distance_to(at + Vector3(0, 0, 10)) < 1.5 or l.state == Lauscher.State.WANDER, "Geht zur Geraeuschquelle")
l.reset_to(at)
l.hear(at + Vector3(4, 0, 0), 9.0, &"sprint")
check(l.state == Lauscher.State.HUNT, "Rennen in 4 m: Jagd")
# jagd_abschuettelbar
main.player.reset_to(Transform3D(Basis(), at + Vector3(0, 0, -20)))
await wait(Tuning.L_GIVE_UP + 0.3)
check(l.state == Lauscher.State.INVESTIGATE, "Ohne Geraeusch gibt er die Jagd auf")
# fangen
var caught := [false]
l.caught_player.connect(func(): caught[0] = true)
l.reset_to(at)
main.player.reset_to(Transform3D(Basis(), at + Vector3(0.8, 0, 0)))
await wait(0.2)
check(caught[0] and not l.active, "Beruehrung = erwischt")
# funk_lockt_an (Review Focus 5)
l.reset_to(at)
main.player.reset_to(Transform3D(Basis(), at + Vector3(0, 0, 9)))
var r: Radio = main.player.get_node("Head/Radio")
r.on = false; await wait(0.6); r.toggle()
await wait(0.6)
check(l.state != Lauscher.State.WANDER, "Funk in 9 m einschalten lockt an")
```
- [ ] **Step 2: Tests** → FAIL. **Step 3:** `lauscher.gd` umsetzen (NavigationAgent3D, `path_desired_distance` 0,5). **Step 4:** Tests → PASS.
- [ ] **Step 5: Commit** „Lauscher: blinder Gegner, der auf Geräusche reagiert“.

---

### Task 7: Flaschen und Scherben

**Files:**
- Create: `scripts/bottle.gd`, `scripts/shards.gd`, `tests/test_props.gd`
- Modify: `scripts/player.gd` (aufheben/werfen), `scripts/main.gd` (Flaschen an `bottle_spots`, Scherbenfelder aus `shard_zones`), `tools/gen_sounds.py` (`glass_shatter.wav`, `glass_crunch_1..3.wav`, `pickup.wav`)

**Interfaces:**
- Consumes: `Player.stepped`, `Player.held_bottle`, `Level.bottle_spots`, `Level.shard_zones`, `Noise.emit`
- Produces:
  - `class_name Bottle extends RigidBody3D` – in Gruppe `"bottles"`; `signal shattered(pos: Vector3)`; nach dem Wurf beim ersten Aufprall mit Geschwindigkeit > 2 m/s: `Noise.emit(pos, Tuning.NOISE_BOTTLE, &"bottle")`, Klang, Splitter-Effekt, `queue_free()`. Liegend ist sie `freeze`d, bis sie aufgehoben wird.
  - `Player.try_pickup() -> bool` (Aktion `interact`; nächste Flasche ≤ 2 m im Blickkegel 35°), `Player.throw_bottle() -> void` (Aktion `throw`; Geschwindigkeit = Blickrichtung × `THROW_SPEED` + Up × `THROW_UP`). Höchstens eine Flasche in der Hand.
  - `class_name Shards extends Node3D` – `func setup(zone: AABB, player: Player) -> void`; baut sichtbare Scherben (viele kleine, glänzende Plättchen, nur im Lichtkegel gut zu sehen: hohe Spekularität, kein Eigenleuchten); bei `player.stepped` innerhalb der Zone: `Noise.emit(pos, NOISE_SHARDS_CROUCH if crouching else NOISE_SHARDS, &"shards")` + Knirschen

- [ ] **Step 1: Failing Tests**

```gdscript
await load_main(&"checkpoint")
var p: Player = main.player
var spot: Vector3 = main.level.bottle_spots[0]
p.reset_to(Transform3D(Basis.looking_at(spot - (spot + Vector3(0, 0.5, 1.5))), spot + Vector3(0, -0.1, 1.5)))
await tap(&"interact")
check(p.held_bottle != null, "Flasche in Reichweite aufgehoben")
var heard := []
Noise.emitted.connect(func(pos, r, s): heard.append([pos, r, s]))
await tap(&"throw")
await wait(2.0)
var b := heard.filter(func(x): return x[2] == &"bottle")
check(b.size() == 1 and b[0][1] == Tuning.NOISE_BOTTLE, "Flasche zerspringt einmal mit 14 m Radius")
check(b.size() == 1 and b[0][0].distance_to(p.global_position) > 4.0, "Geraeusch entsteht am Aufprallort, nicht beim Spieler")
check(p.held_bottle == null, "Hand ist danach leer")
# Scherben
var zone: AABB = main.level.shard_zones[0]
heard.clear()
p.reset_to(Transform3D(Basis(), zone.get_center() + Vector3(0, 0, zone.size.z / 2 + 1.0)))
await hold(&"move_forward", 1.5)
check(heard.any(func(x): return x[2] == &"shards" and x[1] == Tuning.NOISE_SHARDS), "Schritte auf Scherben sind laut")
# geduckt: Radius 4
```
- [ ] **Step 2–4:** Tests FAIL → umsetzen → PASS.
- [ ] **Step 5: Commit** „Flaschen werfen, Scherben verraten den Spieler“.

---

### Task 8: Checkpoint, Neustart und Hinweise

**Files:**
- Create: `scripts/hud.gd`, `tests/test_flow.gd`
- Modify: `scripts/main.gd`

**Interfaces:**
- Consumes: `Lauscher.caught_player`, `Lauscher.reset_to`, `Player.reset_to`, `Radio`, `Level.*`
- Produces:
  - `main.gd`: `var level: Level`, `var player: Player`, `var lauscher: Lauscher`, `var hud: Hud`, `var restarts := 0`, `signal restarted`, `func reset_to_checkpoint() -> void` – Abblende 0,6 s → Spieler an `checkpoint`, Funk an, Lauscher `reset_to(lauscher_start)`, alle Flaschen gelöscht und an `bottle_spots` neu, `held_bottle = null` → Aufblende 0,6 s. Während der Abblende ist `player.input_enabled = false`.
  - `class_name Hud extends CanvasLayer` – `var device: StringName` (`&"kbm"`/`&"pad"`, aus dem letzten Eingabe-Ereignis in `_input`), `func hint_text(action: StringName) -> String` (z. B. „[F] Taschenlampe“ / „[Y] Taschenlampe“), `func show_hint(action: StringName, seconds := 4.0)`, `func fade(alpha: float, seconds: float) -> void` (awaitbar), `func show_title(text: String)`, `func show_subtitle(text: String, seconds: float)`
  - Hinweise: beim Start „Gehen/Umsehen“, nach 3 s Taschenlampe, nach 8 s Funkgerät; beim Blick auf eine Flasche ≤ 2 m `interact`; mit Flasche in der Hand `throw`; geduckt-Hinweis beim ersten Betreten der Bahnsteig-Halle (z < −80).
  - `pause`: Maus freigeben; erneut → einfangen. Kein Menü.

- [ ] **Step 1: Failing Tests**

```gdscript
await load_main(&"checkpoint")
main.lauscher.caught_player.emit()
await wait(2.0)
check(main.restarts == 1, "Erwischt -> Neustart")
# neustart_ist_sauber (Review Focus 2) – zweimal hintereinander
for i in 2:
    main.player.held_bottle = Node3D.new()
    main.lauscher.state = Lauscher.State.HUNT
    main.player.get_node("Head/Radio").on = false
    main.lauscher.caught_player.emit()
    await wait(2.0)
    check(main.player.global_position.distance_to(main.level.checkpoint.origin) < 0.3, "Spieler am Checkpoint (%d)" % i)
    check(main.lauscher.state == Lauscher.State.WANDER and main.lauscher.global_position.distance_to(main.level.lauscher_start) < 0.3, "Lauscher am Start (%d)" % i)
    check(main.get_tree().get_nodes_in_group("bottles").size() == 4 and main.player.held_bottle == null, "Flaschen zurueckgesetzt (%d)" % i)
    check(main.player.get_node("Head/Radio").on, "Funk wieder an (%d)" % i)
# hinweise_folgen_geraet (Review Focus 4)
var key := InputEventKey.new(); key.keycode = KEY_W; key.pressed = true
Input.parse_input_event(key); await wait(0.1)
check(main.hud.hint_text(&"flashlight").contains("F"), "Tastatur-Hinweis nach Tastendruck")
var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_A; pad.pressed = true
Input.parse_input_event(pad); await wait(0.1)
check(main.hud.hint_text(&"flashlight").contains("Y"), "Controller-Hinweis nach Knopfdruck")
```
- [ ] **Step 2–4:** FAIL → umsetzen → PASS.
- [ ] **Step 5: Commit** „Checkpoint, schneller Neustart und geräteabhängige Hinweise“.

---

### Task 9: Das Ende

**Files:**
- Create: `scripts/ending.gd`, `tests/test_ending.gd`
- Modify: `scripts/main.gd` (`var ending: Ending`), `scripts/level.gd` (Turm-Rohbau mit blinkendem Licht, Periode 2 s), `tools/gen_sounds.py` (`radio_clear.wav`: Rauschen klingt aus, Funk-Piepser)

**Interfaces:**
- Consumes: `Level.voice_trigger`, `Level.exit_z`, `Level.tower_top`, `Radio.clear_voice`, `Hud.show_subtitle/fade/show_title`, `Lauscher.active`
- Produces: `class_name Ending extends Node`
  - `var voice_done := false`, `var finished := false`
  - Spieler in `voice_trigger` → `lauscher.active = false`, `radio.on = true`, `radio.clear_voice = true`, Untertitel nacheinander: „…hört mich jemand?“ (2,5 s), „Wir sind am Turm.“ (2 s), „Wir haben Licht.“ (2,5 s). Die gesprochene Stimme kommt in Teil 2; im Rohbau trägt der Untertitel sie.
  - Spieler bei `z <= exit_z` → `player.input_enabled = false`, Kamera dreht in 3 s weich zur `tower_top`, 2 s halten, `hud.fade(1.0, 1.5)`, `hud.show_title("FUNKSTILLE")`, nach 2 s „Danke fürs Spielen“ + Hinweis „beliebige Taste: neu starten“, dann beliebige Eingabe → `get_tree().reload_current_scene()` mit `start_at = &"spawn"`; `finished = true` sobald der Titel steht.

- [ ] **Step 1: Failing Tests**

```gdscript
await load_main(&"checkpoint")
var e: Ending = main.ending
main.player.reset_to(Transform3D(Basis(), Vector3(0, 1.8, -131)))  # knapp ueber der untersten Stufe
await wait(0.5)
check(not main.lauscher.active, "Auf der Treppe ist der Lauscher aus dem Spiel")
check(main.player.get_node("Head/Radio").clear_voice, "Funk wird klar")
main.player.reset_to(Transform3D(Basis(), Vector3(0, 6.1, main.level.exit_z - 1.0)))
await wait(8.0)
check(not main.player.input_enabled, "Am Ende keine Steuerung mehr")
var fwd := -main.player.get_node("Head/Camera3D").global_basis.z
var to_tower := (main.level.tower_top - main.player.get_node("Head/Camera3D").global_position).normalized()
check(fwd.dot(to_tower) > 0.97, "Blick zum Turm")
check(e.finished, "Titel steht")
```
- [ ] **Step 2–4:** FAIL → umsetzen → PASS.
- [ ] **Step 5: Commit** „Ende: klare Stimme, Blick zum Turm, Titel“.

---

### Task 10: Durchspiel-Tests, Screenshots, Pull Request

**Files:**
- Create: `tests/test_playthrough.gd`
- Modify: `tools/screenshots.gd` (Einträge: Wartungsgang, Tunnel am Zug, Bahnsteig mit Lauscher, Treppe, Straße mit Turm), `README.md` (Steuerung beider Geräte, Screenshots, Tests, Hinweis „Rohbau – Look & Klang folgen“), `CREDITS.md`

**Interfaces:**
- Consumes: alles Vorherige. Hilfsfunktion `follow(points: PackedVector3Array, crouch: bool) -> bool` in `game_test.gd` (wie `reachable`, optional geduckt).

- [ ] **Step 1: Durchspiel-Tests**

```gdscript
# schleichweg_ohne_flasche (Review Focus 3): Weg A geduckt, Funk aus
await load_main(&"checkpoint")
await tap(&"radio"); await tap(&"crouch")
var ok := await follow([Vector3(-8.5,0,-80), Vector3(-8.5,0,-97), Vector3(-5,0,-99), Vector3(-5,0,-123), Vector3(-5,1,-127.8), Vector3(-3,1,-127.8), Vector3(0,1,-131), Vector3(0,6,-145), Vector3(0,6,-152)], true)
check(ok and main.restarts == 0, "Schleichweg durchs Gleisbett ohne Flasche")
await wait(9.0)
check(main.ending.finished, "Ende erreicht")
# Weg B: Flasche nach hinten-rechts werfen, rechts an den Saeulen vorbei
# Wer mit Funk an ueber den Bahnsteig geht, wird erwischt
await load_main(&"checkpoint")
await follow([Vector3(-5,0,-81), Vector3(-5,1,-86.2), Vector3(0,1,-90), Vector3(0,1,-104)], false)
await wait(3.0)
check(main.restarts >= 1, "Mit Funk an quer ueber den Bahnsteig: erwischt")
# Rennen direkt zum Ausgang: Lauscher jagt (Leitlinie: riskant, aber Rennen ist schneller)
```
- [ ] **Step 2: `bash tests/run.sh`** → alle PASS. Fehler hier sind Abstimmungsfehler in `tuning.gd` oder im Layout; dort beheben, nicht im Test.
- [ ] **Step 3: Screenshots** – `/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1600x900 --script res://tools/screenshots.gd`; Bilder ansehen (Lesbarkeit: Lauscher im Taschenlampenlicht erkennbar, Scherben im Lichtkegel sichtbar).
- [ ] **Step 4: Selbst spielen lassen** – User bitten, im Godot-Editor F5 zu drücken (nach Änderungen: Editor fokussieren, „Neu laden“, F5 neu) und mit Maus+Tastatur und Controller durchzuspielen.
- [ ] **Step 5: Commit, Push, PR** – Commit „Durchspiel-Tests, Screenshots, README“; `git push`; `gh pr create --base main --head rohbau --title "Funkstille: spielbarer Rohbau" --body "<Zusammenfassung, Screenshots, Teststand> … 🤖 Generated with [Claude Code](https://claude.com/claude-code)"`.
