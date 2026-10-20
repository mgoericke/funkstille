extends SceneTree
## Screenshots + fps-Messung nach docs/screenshots/. Braucht ein echtes Fenster (nicht --headless):
##   FPS=1 godot --path . --resolution 1920x1080 --script res://tools/screenshots.gd
## Umgebung: FPS=1 misst 5 s Durchschnitts-fps je Bild, ONLY=<Teilstring> filtert nach Dateiname.
##
## Eintrag: {"scene", "eye", "look_at", "file"} und optional "gi" (StringName fuer die Look-Probe).
## Szenen mit eigener Camera3D: die Kamera wird auf eye gesetzt und blickt nach look_at.
## Spaeter fuer main.tscn: Eintrag mit "player": true, dann wird statt der Kamera der Spieler
## positioniert (hier noch nicht noetig, _place_view ist die einzige Stelle dafuer).

const SHOTS := [
	{"scene": "res://scenes/look_probe.tscn", "eye": Vector3(0.6, 1.65, 0.0), "look_at": Vector3(-0.2, 1.45, -12.0), "file": "look-sdfgi", "gi": &"sdfgi"},
	{"scene": "res://scenes/look_probe.tscn", "eye": Vector3(0.6, 1.65, 0.0), "look_at": Vector3(-0.2, 1.45, -12.0), "file": "look-voxelgi", "gi": &"voxelgi"},
	{"scene": "res://scenes/look_probe.tscn", "eye": Vector3(0.6, 1.65, 0.0), "look_at": Vector3(-0.2, 1.45, -12.0), "file": "look-none", "gi": &"none"},
]

const WARMUP_FRAMES := 120
const FPS_SECONDS := 5.0

var current: Node


func _initialize() -> void:
	# FSR2 bei 75 % Renderaufloesung, wie fuer die fps-Messung vorgegeben
	# Fenstergroesse auch bei --script setzen (--resolution greift dort nicht fuer root);
	# V-Sync aus, sonst misst man nur die Bildwiederholrate des Displays.
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await process_frame
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	root.scaling_3d_scale = 0.75
	var out := ProjectSettings.globalize_path("res://docs/screenshots")
	DirAccess.make_dir_recursive_absolute(out)
	var only := OS.get_environment("ONLY")
	var measure := OS.get_environment("FPS") == "1"
	print("Fenster: ", root.size, " (3D-Skalierung ", root.scaling_3d_scale, ")")
	for shot in SHOTS:
		if only != "" and not (shot["file"] as String).contains(only):
			continue
		if current != null:
			current.free()
			current = null
			await process_frame
		var packed: PackedScene = load(shot["scene"])
		current = packed.instantiate()
		if shot.has("gi"):
			current.set("gi", shot["gi"])
		root.add_child(current)
		await process_frame
		_place_view(shot)
		for i in WARMUP_FRAMES:
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s/%s.png" % [out, shot["file"]])
		var line := "  docs/screenshots/%s.png" % shot["file"]
		if measure:
			var frames := 0
			var t0 := Time.get_ticks_usec()
			while (Time.get_ticks_usec() - t0) / 1e6 < FPS_SECONDS:
				await process_frame
				frames += 1
			var secs := (Time.get_ticks_usec() - t0) / 1e6
			line += "  %.1f fps" % (frames / secs)
		print(line)
	quit()


## Kamera (oder spaeter Spieler) auf den Blickpunkt setzen
func _place_view(shot: Dictionary) -> void:
	var cam := current.get_node_or_null("Camera3D") as Camera3D
	if cam == null:
		cam = current.find_child("Camera3D", true, false) as Camera3D
	if cam != null:
		cam.global_position = shot["eye"]
		cam.look_at(shot["look_at"])
