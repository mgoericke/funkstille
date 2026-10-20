extends SceneTree
## Basis fuer Spieltests: laedt die Hauptszene, steuert per Eingabe-Aktionen und prueft Ergebnisse.
## Aufruf ueber tests/run.sh oder direkt:
##   godot --headless --path . --script res://tests/test_boot.gd

const PHYSICS_HZ := 120.0

var main: Node3D
var failures := 0
var checks := 0


## Hauptszene frisch laden; eine vorherige wird zuerst freigegeben.
func load_main(start_at := &"spawn") -> void:
	var main_script = load("res://scripts/main.gd")
	main_script.start_at = start_at
	if main != null:
		main.free()
		main = null
		await process_frame
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await wait(0.3)


## Autoload NoiseBus in Testskripten: --script kompiliert vor den Autoloads,
## der Bezeichner ist dort unbekannt, daher ueber den Pfad holen.
func noise_bus() -> Node:
	return root.get_node("NoiseBus")


func wait(seconds: float) -> void:
	for i in int(seconds * PHYSICS_HZ):
		await physics_frame


func check(ok: bool, what: String) -> void:
	checks += 1
	if ok:
		print("  OK    ", what)
	else:
		failures += 1
		print("  FEHLER ", what)


func finish() -> void:
	print("%d/%d Pruefungen bestanden" % [checks - failures, checks])
	quit(1 if failures > 0 else 0)


## Aktion seconds Sekunden halten und wieder loslassen
func hold(action: StringName, seconds: float) -> void:
	Input.action_press(action)
	await wait(seconds)
	Input.action_release(action)


## Aktion kurz antippen: druecken, zwei Physik-Frames, loslassen
func tap(action: StringName) -> void:
	Input.action_press(action)
	await wait(2.0 / PHYSICS_HZ)
	Input.action_release(action)
	await wait(2.0 / PHYSICS_HZ)
