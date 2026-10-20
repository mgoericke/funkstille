extends "res://tests/game_test.gd"
## Look-Probe laedt, hat Volumetric Fog und die Wand-Textur samt Normal Map.


func _initialize() -> void:
	var scene: Node3D = load("res://scenes/look_probe.tscn").instantiate()
	root.add_child(scene)
	for i in 30:
		await process_frame
	var env: Environment = scene.get_node("WorldEnvironment").environment
	check(env.volumetric_fog_enabled, "Volumetric Fog an")
	check(env.tonemap_mode == Environment.TONE_MAPPER_ACES, "Tonemap ACES")
	check(Look.pbr("long_white_tiles").normal_enabled, "Normal Map geladen")
	check(Look.pbr("long_white_tiles").normal_texture != null, "Normal-Textur vorhanden")
	var fl := Look.flashlight()
	check(fl.spot_range == 18.0 and fl.shadow_enabled and fl.light_volumetric_fog_energy > 0.0, "Taschenlampe: 18 m, Schatten, Nebel-Licht")
	check(scene.get_node("Camera3D/Flashlight") != null, "Taschenlampe haengt an der Kamera")
	finish()
