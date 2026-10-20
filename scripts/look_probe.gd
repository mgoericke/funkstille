extends Node3D
## Look-Probe: 12 m Tunnelstueck (z 0 ... -12) in voller Qualitaet.
## gi vor add_child setzen: &"sdfgi", &"voxelgi" oder &"none".

const WALL_ID := "long_white_tiles"
const FLOOR_ID := "concrete_floor_worn_001"
const GRAVEL_ID := "rocky_gravel"
const RUST_ID := "rust_coarse_01"

const LEN := 12.0
const HALF_W := 3.0
const HEIGHT := 4.2

var gi: StringName = &"sdfgi"


func _ready() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = Look.make_environment(gi)
	we.camera_attributes = Look.make_camera_attributes()
	add_child(we)

	_build_tunnel()
	_build_track()
	_build_debris()
	_build_lights()
	_build_dust()

	var cam := get_node_or_null("Camera3D") as Camera3D
	if cam == null:
		cam = Camera3D.new()
		cam.name = "Camera3D"
		cam.position = Vector3(0.6, 1.65, 0.0)
		add_child(cam)
	cam.add_child(Look.flashlight())

	if gi == &"voxelgi":
		# Erst nach dem Aufbau backen, damit die Geometrie schon steht
		Look.add_voxel_gi(self, Vector3(HALF_W * 2 + 2, HEIGHT + 2, LEN + 2), Vector3(0, HEIGHT / 2, -LEN / 2))


## Quader mit Material; pos ist die Mitte
func _box(size: Vector3, pos: Vector3, mat: Material, node_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if node_name != "":
		mi.name = node_name
	add_child(mi)
	return mi


func _build_tunnel() -> void:
	var tiles := Look.pbr(WALL_ID, Vector3(0.55, 0.55, 0.55))
	var concrete := Look.pbr(FLOOR_ID, Vector3(0.4, 0.4, 0.4))
	concrete.roughness = 0.7
	var t := 0.4
	var tile_h := 2.6
	# Kachelwaende bis 2,6 m, darueber Beton
	for side in [-1.0, 1.0]:
		var x: float = side * (HALF_W + t / 2)
		_box(Vector3(t, tile_h, LEN), Vector3(x, tile_h / 2, -LEN / 2), tiles, "WandKachel")
		_box(Vector3(t, HEIGHT - tile_h, LEN), Vector3(x, tile_h + (HEIGHT - tile_h) / 2, -LEN / 2), concrete)
	# Boden
	_box(Vector3(HALF_W * 2 + 2 * t, t, LEN), Vector3(0, -t / 2, -LEN / 2), concrete, "Boden")
	# Stirnwaende, damit das Licht nicht entweicht (hinten mit Oeffnung nicht noetig, nur Abschluss)
	_box(Vector3(HALF_W * 2 + 2 * t, HEIGHT + t, t), Vector3(0, HEIGHT / 2 - t / 2, -LEN - t / 2), concrete, "Abschluss")
	# Decke mit Spalt bei z -6.4 ... -7.6 (Lichtschacht)
	var gap_a := 6.4
	var gap_b := 7.6
	_box(Vector3(HALF_W * 2 + 2 * t, t, gap_a), Vector3(0, HEIGHT + t / 2, -gap_a / 2), concrete, "DeckeA")
	_box(Vector3(HALF_W * 2 + 2 * t, t, LEN - gap_b), Vector3(0, HEIGHT + t / 2, -(gap_b + LEN) / 2), concrete, "DeckeB")
	# Schacht nach oben, damit der Spalt nicht nach draussen offen ist
	_box(Vector3(HALF_W * 2 + 2 * t, 3.0, t), Vector3(0, HEIGHT + t + 1.5, -gap_a), concrete)
	_box(Vector3(HALF_W * 2 + 2 * t, 3.0, t), Vector3(0, HEIGHT + t + 1.5, -gap_b), concrete)
	# Pfeilerband an der Wand zur Tiefenstaffelung
	for z in [-2.0, -6.0, -10.0]:
		for side in [-1.0, 1.0]:
			_box(Vector3(0.5, HEIGHT, 0.7), Vector3(side * (HALF_W - 0.25), HEIGHT / 2, z), concrete, "Pfeiler")


func _build_track() -> void:
	var gravel := Look.pbr(GRAVEL_ID, Vector3(0.5, 0.5, 0.5))
	var rust := Look.pbr(RUST_ID, Vector3(0.8, 0.8, 0.8))
	# Schotterbett
	_box(Vector3(2.6, 0.14, LEN), Vector3(0, 0.07, -LEN / 2), gravel, "Schotter")
	# Schwellen
	var z := -0.4
	while z > -LEN:
		_box(Vector3(2.2, 0.12, 0.26), Vector3(0, 0.19, z), rust)
		z -= 0.7
	# Schienen
	for side in [-1.0, 1.0]:
		_box(Vector3(0.1, 0.18, LEN), Vector3(side * 0.72, 0.31, -LEN / 2), rust, "Schiene")


func _build_debris() -> void:
	var rust := Look.pbr(RUST_ID, Vector3(1.2, 1.2, 1.2))
	var concrete := Look.pbr(FLOOR_ID, Vector3(1.0, 1.0, 1.0))
	var spots := [
		[Vector3(2.0, 0.3, -2.4), Vector3(0.8, 0.6, 0.8), 12.0, true],
		[Vector3(2.3, 0.2, -3.1), Vector3(0.5, 0.4, 0.6), -30.0, false],
		[Vector3(-2.1, 0.35, -5.0), Vector3(1.0, 0.7, 0.9), 25.0, true],
		[Vector3(-1.8, 0.2, -9.0), Vector3(0.6, 0.4, 0.5), 50.0, false],
		[Vector3(2.0, 0.25, -9.6), Vector3(0.9, 0.5, 1.2), -8.0, true],
		[Vector3(-2.4, 0.15, -3.2), Vector3(0.4, 0.3, 1.4), 70.0, false],
	]
	for s in spots:
		var mi := _box(s[1], s[0], rust if s[3] else concrete, "Schutt")
		mi.rotation_degrees.y = s[2]
	# Ein Rohr als Silhouette quer ueber dem Gleis, tief im Raum
	var pipe := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.12
	cm.height = HALF_W * 2
	pipe.mesh = cm
	pipe.material_override = rust
	pipe.rotation_degrees.z = 90
	pipe.position = Vector3(0, 3.4, -9.0)
	add_child(pipe)


func _build_lights() -> void:
	# Ausgeschaltete Deckenlampe: Gehaeuse + toter Leuchtkoerper
	var housing := StandardMaterial3D.new()
	housing.albedo_color = Color(0.12, 0.12, 0.12)
	housing.metallic = 0.7
	housing.roughness = 0.5
	_box(Vector3(0.3, 0.1, 1.4), Vector3(0, HEIGHT - 0.05, -3.5), housing, "Deckenlampe")
	var tube := StandardMaterial3D.new()
	tube.albedo_color = Color(0.5, 0.52, 0.5)
	tube.roughness = 0.3
	_box(Vector3(0.12, 0.05, 1.2), Vector3(0, HEIGHT - 0.12, -3.5), tube, "Leuchtroehre")

	# Schwache Notlichter (gruenlich) als Grundhelligkeit, damit nichts im Schwarz absaeuft
	for z in [-1.5, -10.5]:
		var fill := OmniLight3D.new()
		fill.name = "Notlicht"
		fill.position = Vector3(-2.2, 3.4, z)
		fill.omni_range = 7.0
		fill.light_energy = 0.6
		fill.light_color = Color(0.75, 0.88, 0.8)
		fill.light_volumetric_fog_energy = 1.0
		add_child(fill)

	# Tageslicht durch den Deckenspalt: kalter Kegel, der im Nebel sichtbar wird
	var shaft := SpotLight3D.new()
	shaft.name = "Lichtschacht"
	shaft.position = Vector3(0, HEIGHT + 3.2, -7.0)
	shaft.rotation_degrees = Vector3(-90, 0, 0)
	shaft.spot_range = 16.0
	shaft.spot_angle = 14.0
	shaft.spot_angle_attenuation = 0.5
	shaft.light_energy = 60.0
	shaft.light_color = Color(0.8, 0.9, 1.0)
	shaft.shadow_enabled = true
	shaft.light_volumetric_fog_energy = 4.0
	add_child(shaft)


func _build_dust() -> void:
	var p := GPUParticles3D.new()
	p.name = "Staub"
	p.amount = 160
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.visibility_aabb = AABB(Vector3(-4, -1, -14), Vector3(8, 6, 16))
	p.position = Vector3(0, HEIGHT / 2, -LEN / 2)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(HALF_W, HEIGHT / 2, LEN / 2)
	pm.gravity = Vector3(0, -0.01, 0)
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.08
	pm.direction = Vector3(0.3, 0.1, -1.0)
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.15
	pm.turbulence_noise_scale = 2.0
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.012, 0.012)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.9, 0.92, 0.85, 0.8)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = dm
	p.draw_pass_1 = quad
	add_child(p)
