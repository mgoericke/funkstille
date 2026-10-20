class_name Look
extends RefCounted
## Gemeinsamer Look: Environment, PBR-Materialien, Taschenlampe.
## Wird von der Look-Probe und spaeter vom Level benutzt.

const TEX_DIR := "res://assets/textures/"


## Environment mit ACES, Volumetric Fog, Glow, SSAO, SSIL.
## gi: &"sdfgi" schaltet SDFGI ein; &"voxelgi" und &"none" lassen es aus
## (VoxelGI ist ein Node, siehe add_voxel_gi).
static func make_environment(gi: StringName = &"sdfgi") -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.5)
	env.ambient_light_energy = 0.1
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0

	# Nebel mit leicht gruenlich-grauem Ton; Lichter duerfen ihn per Energie anleuchten
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.03
	env.volumetric_fog_albedo = Color(0.68, 0.76, 0.70)
	env.volumetric_fog_emission = Color(0.02, 0.03, 0.03)
	env.volumetric_fog_emission_energy = 0.4
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 24.0
	env.volumetric_fog_gi_inject = 1.0

	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1

	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.0
	env.ssil_enabled = true
	env.ssil_intensity = 1.0

	env.sdfgi_enabled = gi == &"sdfgi"
	if env.sdfgi_enabled:
		env.sdfgi_use_occlusion = true
		env.sdfgi_cascades = 4
		env.sdfgi_min_cell_size = 0.2
		env.sdfgi_energy = 1.0
	return env


## Auto-Belichtung (liegt in Godot nicht im Environment, sondern in den Kamera-Attributen)
static func make_camera_attributes() -> CameraAttributesPractical:
	var attr := CameraAttributesPractical.new()
	attr.auto_exposure_enabled = true
	attr.auto_exposure_scale = 0.4
	attr.auto_exposure_min_sensitivity = 40.0
	attr.auto_exposure_max_sensitivity = 800.0
	return attr


## VoxelGI-Node fuer den Bereich size um den Ursprung des Parents; wird sofort gebacken.
static func add_voxel_gi(parent: Node3D, size: Vector3, center: Vector3) -> VoxelGI:
	var vgi := VoxelGI.new()
	vgi.size = size
	vgi.position = center
	vgi.subdiv = VoxelGI.SUBDIV_128
	parent.add_child(vgi)
	vgi.bake()
	return vgi


## PBR-Material aus assets/textures/<id>/{diffuse,normal,rough,ao}.jpg.
## uv_scale: Kacheln pro Meter (Triplanar in Weltkoordinaten), damit Boxen beliebiger Groesse passen.
static func pbr(id: String, uv_scale: Vector3 = Vector3.ONE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var dir := TEX_DIR + id + "/"
	m.albedo_texture = load(dir + "diffuse.jpg")
	m.normal_enabled = true
	m.normal_texture = load(dir + "normal.jpg")
	m.normal_scale = 1.0
	m.roughness = 1.0
	m.roughness_texture = load(dir + "rough.jpg")
	if ResourceLoader.exists(dir + "ao.jpg"):
		m.ao_enabled = true
		m.ao_texture = load(dir + "ao.jpg")
		m.ao_light_affect = 0.6
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = uv_scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## Taschenlampe: engerer Kegel, harter Schatten, leuchtet den Nebel an
static func flashlight() -> SpotLight3D:
	var l := SpotLight3D.new()
	l.name = "Flashlight"
	l.spot_range = 18.0
	l.spot_angle = 28.0
	l.spot_angle_attenuation = 2.2
	l.spot_attenuation = 1.0
	l.light_energy = 3.5
	l.light_color = Color(1.0, 0.93, 0.8)
	l.light_indirect_energy = 1.0
	l.shadow_enabled = true
	l.light_volumetric_fog_energy = 2.0
	return l
