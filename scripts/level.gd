class_name Level
extends Node3D
## Rohbau der ganzen Route (Laufrichtung -Z): Wartungsgang, Tunnel, Bahnsteig-Halle,
## Treppe, Strasse mit Fernsehturm. Alles aus Code, Kollision per StaticBody3D.
## Decken sind nur sichtbar (ohne Kollision), damit Strahlen von oben den Boden finden.

const HALL_GROUP := &"nav_hall"

var spawn := Transform3D(Basis(), Vector3(0, 0, -1))
var checkpoint := Transform3D(Basis(), Vector3(0, 0, -76))
var lauscher_start := Vector3(0, 1, -104)
var patrol := PackedVector3Array([Vector3(-1.5, 1, -96), Vector3(1.5, 1, -112), Vector3(0, 1, -120)])
var bottle_spots := PackedVector3Array([Vector3(3.4, 1.1, -88), Vector3(-3.4, 1.1, -90), Vector3(-7, 0.1, -84), Vector3(7, 0.1, -84)])
var shard_zones: Array[AABB] = [
	AABB(Vector3(0, 1, -121), Vector3(3.5, 0.5, 5)),    # Bahnsteig
	AABB(Vector3(-10, 0, -104), Vector3(3, 0.5, 4)),    # Gleisbett links
]
var voice_trigger := AABB(Vector3(-2, 1, -134), Vector3(4, 6, 4))
var exit_z := -150.0
var tower_top := Vector3(60, 156, -600)
var beacon := Vector3(60, 156, -600)

var nav_region: NavigationRegion3D

var _concrete: StandardMaterial3D
var _dark: StandardMaterial3D
var _rust: StandardMaterial3D
var _tile: StandardMaterial3D
var _asphalt: StandardMaterial3D


func build() -> void:
	_concrete = _mat(Color(0.42, 0.42, 0.40))
	_dark = _mat(Color(0.22, 0.22, 0.22))
	_rust = _mat(Color(0.36, 0.22, 0.14))
	_tile = _mat(Color(0.55, 0.56, 0.52))
	_asphalt = _mat(Color(0.16, 0.16, 0.17))
	_build_corridor_and_tunnel()
	_build_wagon()
	_build_hall()
	_build_stairs_and_street()
	_build_tower()
	_build_lights()
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	add_child(env)
	Look.apply(env)
	_bake_navigation()


# ---------- Bausteine ----------

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


## Quader von Ecke a bis Ecke b (Weltkoordinaten); solid = mit Kollision.
func _box(a: Vector3, b: Vector3, mat: Material, solid := true, group: StringName = &"") -> Node3D:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var size := (a - b).abs()
	return _box_at(lo + size / 2.0, size, Basis(), mat, solid, group)


func _box_at(center: Vector3, size: Vector3, basis: Basis, mat: Material, solid: bool, group: StringName) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	var holder: Node3D = mi
	if solid:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		body.add_child(mi)
		holder = body
		if group != &"":
			body.add_to_group(group)
	holder.transform = Transform3D(basis, center)
	add_child(holder)
	return holder


## Rampe: steigt entlang -Z von (z_from, y_from) nach (z_to, y_to), Breite x0..x1.
## Sichtbar und kollidierend dasselbe glatte Brett, damit der Spieler sie gut hochkommt.
func _ramp(x0: float, x1: float, z_from: float, y_from: float, z_to: float, y_to: float, mat: Material, thick := 0.4, group: StringName = &"") -> void:
	var run := absf(z_to - z_from)
	var rise := y_to - y_from
	var length := sqrt(run * run + rise * rise)
	var ang := atan2(rise, run)
	var basis := Basis(Vector3.RIGHT, ang)
	var top_mid := Vector3((x0 + x1) / 2.0, (y_from + y_to) / 2.0, (z_from + z_to) / 2.0)
	var normal := basis * Vector3.UP
	_box_at(top_mid - normal * thick / 2.0, Vector3(absf(x1 - x0), thick, length), basis, mat, true, group)


# ---------- Abschnitte ----------

func _build_corridor_and_tunnel() -> void:
	# Boden Wartungsgang + Tunnel (z 0 ... -80)
	_box(Vector3(-8.5, -1, 1), Vector3(8.5, 0, -80), _concrete)
	# Wartungsgang: x -1..1, Hoehe 2,4
	_box(Vector3(-1.5, 0, 1), Vector3(-1, 2.4, -20), _dark)
	_box(Vector3(1, 0, 1), Vector3(1.5, 2.4, -20), _dark)
	_box(Vector3(-1.5, 0, 1.5), Vector3(1.5, 2.4, 1), _dark)  # Rueckwand
	_box(Vector3(-1.5, 2.4, 1), Vector3(1.5, 2.8, -20), _dark, false)  # Decke
	# Stirnwand des Tunnels mit Oeffnung fuer den Gang
	_box(Vector3(-8.5, 0, -20), Vector3(-1, 5, -20.5), _concrete)
	_box(Vector3(1, 0, -20), Vector3(8.5, 0 + 5, -20.5), _concrete)
	_box(Vector3(-1, 2.4, -20), Vector3(1, 5, -20.5), _concrete)
	# Tunnel x -8..8, Hoehe 5
	_box(Vector3(-8.5, 0, -20), Vector3(-8, 5, -80), _concrete)
	_box(Vector3(8, 0, -20), Vector3(8.5, 5, -80), _concrete)
	_box(Vector3(-8.5, 5, -20), Vector3(8.5, 5.5, -80), _dark, false)
	# Tunnelende bei z -80: Aussenstuecke zur breiteren Halle, Mitte ist offen
	_box(Vector3(-10.5, 0, -80), Vector3(-8, 6, -80.5), _concrete)
	_box(Vector3(8, 0, -80), Vector3(10.5, 6, -80.5), _concrete)


func _build_wagon() -> void:
	# Zugwaggon x -7..-3, z -40..-58, innen begehbar; zwei Tueroeffnungen zur Tunnelmitte
	var h := 3.6
	_box(Vector3(-7, 0, -40), Vector3(-6.8, h, -58), _rust)      # Aussenwand
	_box(Vector3(-7, 0, -40), Vector3(-3, h, -40.2), _rust)      # Stirn vorn
	_box(Vector3(-7, 0, -57.8), Vector3(-3, h, -58), _rust)      # Stirn hinten
	_box(Vector3(-7, h, -40), Vector3(-3, h + 0.2, -58), _rust)  # Dach
	# Innenwand x -3.2..-3 mit Oeffnungen z -44..-46.5 und z -51.5..-54
	for seg in [[-40.2, -44.0], [-46.5, -51.5], [-54.0, -57.8]]:
		_box(Vector3(-3.2, 0, seg[0]), Vector3(-3, h, seg[1]), _rust)
	_box(Vector3(-3.2, 2.2, -44), Vector3(-3, h, -46.5), _rust)
	_box(Vector3(-3.2, 2.2, -51.5), Vector3(-3, h, -54), _rust)


func _build_hall() -> void:
	var g := HALL_GROUP
	# Gleisbett-Boden der Halle (y 0) und Bahnsteig (y 1)
	_box(Vector3(-10.5, -1, -80), Vector3(10.5, 0, -130.5), _dark, true, g)
	_box(Vector3(-4, 0, -80), Vector3(4, 1, -130), _tile, true, g)
	_box(Vector3(-4.05, 0.98, -80), Vector3(4.05, 1.0, -130), _concrete, false)  # Kantenband
	# Waende und Decke
	_box(Vector3(-10.5, 0, -80.5), Vector3(-10, 6, -130.5), _concrete, true, g)
	_box(Vector3(10, 0, -80.5), Vector3(10.5, 6, -130.5), _concrete, true, g)
	_box(Vector3(-10.5, 6, -80), Vector3(10.5, 6.5, -130.5), _dark, false)
	# Stirnwand hinten mit Treppenoeffnung x -2..2
	_box(Vector3(-10.5, 0, -130), Vector3(-2, 6, -130.5), _concrete, true, g)
	_box(Vector3(2, 0, -130), Vector3(10.5, 6, -130.5), _concrete, true, g)
	_box(Vector3(-2, 6, -130), Vector3(2, 7, -130.5), _concrete, false)
	# Saeulen 0,6 x 0,6 bei x +-2,5 alle 8 m ab z -86
	var z := -86.0
	while z >= -126.0:
		for x in [-2.5, 2.5]:
			_box(Vector3(x - 0.3, 0, z - 0.3), Vector3(x + 0.3, 6, z + 0.3), _concrete, true, g)
		z -= 8.0
	# Rampen: vorn z -82 -> -86, hinten z -124 -> -128, links und rechts; oben ein kurzer ebener Absatz
	for side in [[-6.0, -4.0], [4.0, 6.0]]:
		_ramp(side[0], side[1], -82, 0, -86, 1, _concrete, 0.4, g)
		_box(Vector3(side[0], 0, -86), Vector3(side[1], 1, -87.8), _concrete, true, g)
		_ramp(side[0], side[1], -124, 0, -128, 1, _concrete, 0.4, g)
		_box(Vector3(side[0], 0, -128), Vector3(side[1], 1, -129.8), _concrete, true, g)


func _build_stairs_and_street() -> void:
	# Treppenschacht z -130 .. -142, x -2..2, y 1 -> 6 (glatte Kollisionsrampe, sichtbare Stufen)
	_box(Vector3(-2.5, 0, -130), Vector3(-2, 12, -142), _concrete)
	_box(Vector3(2, 0, -130), Vector3(2.5, 12, -142), _concrete)
	_ramp(-2, 2, -130, 1, -142, 6, _concrete, 0.5)
	var steps := 25
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var top := 1.0 + 5.0 * (t0 + t1) / 2.0 - 0.02
		var z0 := -130.0 - 12.0 * t0
		var z1 := -130.0 - 12.0 * t1
		_box(Vector3(-2, top - 0.25, z0), Vector3(2, top, z1), _tile, false)
	# Strasse y 6, z -142 .. -175, x -15..15, mit niedriger Bruestung
	_box(Vector3(-15, 5, -142), Vector3(15, 6, -175), _asphalt)
	_box(Vector3(-15.3, 6, -142), Vector3(-15, 7.2, -175.3), _concrete)
	_box(Vector3(15, 6, -142), Vector3(15.3, 7.2, -175.3), _concrete)
	_box(Vector3(-15.3, 6, -175), Vector3(15.3, 7.2, -175.3), _concrete)
	_box(Vector3(-15.3, 6, -142), Vector3(-2.5, 7.2, -142.3), _concrete)
	_box(Vector3(2.5, 6, -142), Vector3(15.3, 7.2, -142.3), _concrete)


func _build_tower() -> void:
	# Fernsehturm-Silhouette weit hinten
	var tower_mat := StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.03, 0.035, 0.04)
	tower_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shaft := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.0
	cm.bottom_radius = 4.0
	cm.height = 200.0
	shaft.mesh = cm
	shaft.material_override = tower_mat
	shaft.position = Vector3(60, 6 + 100, -600)
	shaft.name = "TowerShaft"
	add_child(shaft)
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 16.0
	sm.height = 32.0
	ball.mesh = sm
	ball.material_override = tower_mat
	ball.position = Vector3(60, 150, -600)
	ball.name = "TowerBall"
	add_child(ball)
	var blink := OmniLight3D.new()
	blink.name = "TowerBeacon"
	blink.position = Vector3(60, 208, -600)
	blink.light_color = Color(1.0, 0.15, 0.1)
	blink.light_energy = 3.0
	blink.omni_range = 40.0
	add_child(blink)
	var tw := create_tween().set_loops()
	tw.tween_property(blink, "light_energy", 0.0, 0.05).set_delay(1.2)
	tw.tween_property(blink, "light_energy", 3.0, 0.05).set_delay(0.6)


func _build_lights() -> void:
	# Wenige, schwache Deckenlampen-Reste
	var spots := [
		Vector3(0, 2.1, -8), Vector3(0, 2.1, -16), Vector3(0, 4.6, -32), Vector3(0, 4.6, -52),
		Vector3(0, 4.6, -70), Vector3(0, 5.6, -90), Vector3(-6, 5.6, -112), Vector3(5, 5.6, -122),
		Vector3(0, 5.6, -127),
	]
	for p in spots:
		var l := OmniLight3D.new()
		l.position = p
		l.light_color = Color(1.0, 0.85, 0.6)
		l.light_energy = 0.5
		l.omni_range = 9.0
		add_child(l)
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.rotation_degrees = Vector3(-50, 20, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.25
	moon.shadow_enabled = true
	add_child(moon)


## Navigation nur fuer die Halle (Gleisbetten, Bahnsteig, Rampen), zur Laufzeit gebacken.
func _bake_navigation() -> void:
	# Karte und Mesh muessen dieselbe Zellgroesse haben, sonst Rasterfehler und Warnungen
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, 0.2)
	NavigationServer3D.map_set_cell_height(map, 0.1)
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.4
	nm.agent_height = 1.8
	nm.agent_max_slope = 30.0
	nm.agent_max_climb = 0.3
	nm.cell_size = 0.2
	nm.cell_height = 0.1
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = HALL_GROUP
	nav_region = NavigationRegion3D.new()
	nav_region.name = "NavRegion"
	nav_region.navigation_mesh = nm
	add_child(nav_region)
	nav_region.bake_navigation_mesh(false)
