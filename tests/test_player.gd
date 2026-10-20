extends "res://tests/game_test.gd"
## Spieler: Bewegung relativ zur Blickrichtung, Tempo, Ducken, Schrittgeraeusche, Taschenlampe, reset_to.


func _initialize() -> void:
	print("Spieler")
	await load_main()
	var p: Player = main.player
	check(p != null and p.get_node_or_null("Head/Camera3D/Flashlight") != null, "Spieler mit Head/Camera3D/Flashlight")
	check(p.get_node_or_null("Head/Camera3D/HoldPoint") != null, "HoldPoint vor der Kamera")
	check(absf(p.get_node("Head").position.y - 1.6) < 0.05, "Kopf stehend auf 1,6 m")

	# Geraeusche nur von Schritten/Sprint zaehlen (Funkgeraet sendet spaeter &"radio")
	var events := []
	noise_bus().emitted.connect(func(_pos, r, s):
		if s == &"step" or s == &"sprint":
			events.append([r, s]))

	# Gehen
	var z0 := p.global_position.z
	await hold(&"move_forward", 2.0)
	check(absf((z0 - p.global_position.z) / 2.0 - Tuning.WALK_SPEED) < 0.4, "Gehen ~2,8 m/s nach -Z")
	check(events.size() >= 3 and events.all(func(x): return x[0] == Tuning.NOISE_WALK and x[1] == &"step"), "Gehen macht leise Schritte (2 m, Quelle step)")
	check(p.step_noise_radius() == Tuning.NOISE_WALK, "step_noise_radius Gehen")

	# Rennen
	p.reset_to(Transform3D(Basis(), Vector3.ZERO))
	events.clear()
	Input.action_press(&"sprint")
	z0 = p.global_position.z
	await hold(&"move_forward", 1.5)
	check(absf((z0 - p.global_position.z) / 1.5 - Tuning.SPRINT_SPEED) < 0.7, "Rennen ~5,5 m/s")
	check(events.size() >= 3 and events.all(func(x): return x[0] == Tuning.NOISE_SPRINT and x[1] == &"sprint"), "Rennen: Radius 9, Quelle sprint")
	Input.action_release(&"sprint")

	# Ducken per Taste (Umschalter)
	p.reset_to(Transform3D(Basis(), Vector3.ZERO))
	events.clear()
	await tap(&"crouch")
	check(p.crouching, "Taste crouch schaltet Ducken ein")
	await wait(0.6)
	check(absf(p.get_node("Head").position.y - 0.95) < 0.05, "Kopf geduckt auf 0,95 m")
	z0 = p.global_position.z
	await hold(&"move_forward", 2.0)
	check(absf((z0 - p.global_position.z) / 2.0 - Tuning.CROUCH_SPEED) < 0.4, "Geduckt ~1,4 m/s")
	check(events.is_empty(), "Geduckt ist lautlos")
	# Rennen bei gehaltener Taste, aber geduckt: bleibt langsam
	Input.action_press(&"sprint")
	z0 = p.global_position.z
	await hold(&"move_forward", 1.0)
	Input.action_release(&"sprint")
	check(absf(z0 - p.global_position.z) < Tuning.CROUCH_SPEED + 0.4, "Geduckt kein Rennen")
	await tap(&"crouch")
	check(not p.crouching, "zweites Antippen hebt Ducken auf")

	# Taschenlampe
	var was := p.flashlight_on
	await tap(&"flashlight")
	check(p.flashlight_on != was and p.get_node("Head/Camera3D/Flashlight").visible == p.flashlight_on, "F schaltet Taschenlampe")

	# Blickrichtung: Bewegung relativ zum Yaw
	p.reset_to(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0, 0, -30)))
	var x0 := p.global_position.x
	await hold(&"move_forward", 1.0)
	check(p.global_position.x < x0 - 2.0, "Bewegung folgt der Blickrichtung (Yaw 90 Grad -> -X)")

	# reset_to
	p.crouching = true
	p.reset_to(Transform3D(Basis(), Vector3(5, 0, 5)))
	check(p.global_position.distance_to(Vector3(5, 0, 5)) < 0.01 and not p.crouching, "reset_to setzt Position und hebt Ducken auf")
	check(p.velocity.length() < 0.01, "reset_to setzt Geschwindigkeit 0")
	finish()
