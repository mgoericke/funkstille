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


## Gegner stilllegen, damit Routentests nicht gestoert werden (Lauscher kommt in einer spaeteren Task).
func calm() -> void:
	var l = main.get("lauscher")
	if l != null:
		l.active = false


## Boden-Hoehe unter (x, z): Strahl von y 10 nach unten, NAN ohne Treffer. Der Spieler wird ausgenommen.
func floor_y(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 10, z), Vector3(x, -5, z))
	q.exclude = [main.player.get_rid()]
	var hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(q)
	return NAN if hit.is_empty() else hit.position.y


## Spieler laeuft die Punkte der Reihe nach ab (Blick auf den naechsten Punkt, move_forward gehalten).
## true, wenn jeder Punkt auf 0,5 m (horizontal) erreicht wird, in plausibler Hoehe, ohne Zeitueberschreitung.
func reachable(path: PackedVector3Array) -> bool:
	var p = main.player
	var ok := true
	Input.action_press(&"move_forward")
	for target in path:
		var d0 := Vector2(target.x - p.global_position.x, target.z - p.global_position.z).length()
		var limit := d0 / Tuning.WALK_SPEED * 2.0 + 2.0
		var t := 0.0
		while t < limit:
			var d := Vector2(target.x - p.global_position.x, target.z - p.global_position.z)
			if d.length() < 0.5:
				break
			p.rotation.y = atan2(-d.x, -d.y)
			await physics_frame
			t += 1.0 / PHYSICS_HZ
		if t >= limit or absf(p.global_position.y - target.y) > 0.6:
			print("  (reachable: Punkt ", target, " verfehlt, Spieler bei ", p.global_position, ")")
			ok = false
			break
	Input.action_release(&"move_forward")
	return ok
