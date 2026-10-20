extends "res://tests/game_test.gd"
## Start: Renderer, Physik, Eingabe-Belegung, NoiseBus-Autoload, Hauptszene laedt zweimal.


func _initialize() -> void:
	print("Boot")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "Renderer Forward+")
	check(Engine.physics_ticks_per_second == 120, "Physik 120 Hz")
	await load_main()
	for a in Controls.ACTIONS:
		check(InputMap.has_action(a), "Aktion %s vorhanden" % a)
		var kbm := InputMap.action_get_events(a).any(func(e): return e is InputEventKey or e is InputEventMouseButton)
		var pad := InputMap.action_get_events(a).any(func(e): return e is InputEventJoypadButton or e is InputEventJoypadMotion)
		check(pad, "%s hat Controller-Belegung" % a)
		if not (a as String).begins_with("look_"):
			check(kbm, "%s hat Tastatur/Maus-Belegung" % a)
	var counts := {}
	for a in Controls.ACTIONS:
		counts[a] = InputMap.action_get_events(a).size()
	Controls.register()
	for a in Controls.ACTIONS:
		check(InputMap.action_get_events(a).size() == counts[a], "register() ist idempotent fuer %s" % a)
	var got := []
	var bus := noise_bus()
	bus.emitted.connect(func(p, r, s): got.append([p, r, s]))
	bus.emit(Vector3(1, 2, 3), 5.0, &"step")
	check(got.size() == 1 and got[0][1] == 5.0 and got[0][2] == &"step", "NoiseBus verteilt Ereignisse")
	var first := main
	await load_main()
	check(main != first and not is_instance_valid(first), "load_main ersetzt die alte Hauptszene")
	finish()
