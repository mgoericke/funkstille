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
	check(Look.pbr("long_white_tiles").ao_enabled and Look.pbr("long_white_tiles").ao_texture != null, "AO-Map geladen")
	var we := WorldEnvironment.new()
	Look.apply(we, &"none")
	check(we.environment != null and we.camera_attributes is CameraAttributesPractical and we.camera_attributes.auto_exposure_enabled, "Look.apply setzt Environment und Auto-Belichtung")
	check(not we.environment.sdfgi_enabled, "gi none: SDFGI aus")
	we.free()
	var fl := Look.flashlight()
	check(fl.spot_range == 18.0 and fl.shadow_enabled and fl.light_volumetric_fog_energy > 0.0, "Taschenlampe: 18 m, Schatten, Nebel-Licht")
	check(scene.get_node("Camera3D/Flashlight") != null, "Taschenlampe haengt an der Kamera")
	finish()
