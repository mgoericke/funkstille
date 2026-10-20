class_name Radio
extends Node3D
## Funkgeraet: Signal wird zum Ausgang hin klarer, das Rauschen ist aber auch fuer den Lauscher hoerbar.
## Solange es an ist, sendet es alle Tuning.RADIO_PULSE s einen Geraeusch-Impuls.

const STATIC_DB := Vector2(-6.0, -22.0)  # Rauschen bei Staerke 0 / 1
const TONE_DB := Vector2(-40.0, -8.0)  # Ton bei Staerke 0 / 1
const MUTED_DB := -80.0
const ROUTE_LENGTH := 150.0  # Meter bis zum vollen Signal (Fortschritt entlang -Z)

var on := true
## Quelle des Signals (nur die Richtung zaehlt, fuer spaeteres Panning)
var beacon := Vector3.ZERO
## Das Ende setzt dies: Rauschen aus, nur Ton/Stimme
var clear_voice := false

var static_player: AudioStreamPlayer
var tone_player: AudioStreamPlayer
var _switch_player: AudioStreamPlayer
var _pulse := 0.0
var _bus: Node


func _ready() -> void:
	name = "Radio"
	_bus = get_node("/root/NoiseBus")
	static_player = _loop_player("RadioStatic", "res://sounds/radio_static.wav")
	tone_player = _loop_player("RadioTone", "res://sounds/radio_tone.wav")
	_switch_player = AudioStreamPlayer.new()
	_switch_player.name = "SwitchAudio"
	_switch_player.stream = load("res://sounds/radio_switch.wav")
	_switch_player.volume_db = -10.0
	add_child(_switch_player)
	update_sound(strength(global_position))
	_apply_play_state()


func _loop_player(node_name: String, path: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	p.stream = load(path)  # Schleife ueber die .import-Einstellung (loop_mode)
	add_child(p)
	return p


## Fortschritt entlang der Route (nicht Abstand zur 600 m entfernten Quelle).
func strength(from: Vector3) -> float:
	return 0.15 + 0.85 * clampf(-from.z / ROUTE_LENGTH, 0.0, 1.0)


func toggle() -> void:
	on = not on
	_pulse = 0.0
	_switch_player.play()
	_apply_play_state()
	# Einschalten ist selbst laut: sofort ein Impuls, nicht erst nach RADIO_PULSE
	if on and not clear_voice:
		_bus.emit(global_position, Tuning.NOISE_RADIO, &"radio")


func update_sound(s: float) -> void:
	if clear_voice:
		static_player.volume_db = MUTED_DB
		tone_player.volume_db = 0.0
	else:
		static_player.volume_db = lerpf(STATIC_DB.x, STATIC_DB.y, s)
		tone_player.volume_db = lerpf(TONE_DB.x, TONE_DB.y, s)


func _apply_play_state() -> void:
	for p in [static_player, tone_player]:
		if on and not p.playing:
			p.play()
		elif not on and p.playing:
			p.stop()


func _process(delta: float) -> void:
	if not on:
		return
	update_sound(strength(global_position))
	# Klare Stimme (Ende) ist kein Rauschen: nichts, was der Lauscher hoeren koennte
	if clear_voice:
		_pulse = 0.0  # kein aufgestauter Impuls, wenn die Stimme wieder endet
		return
	_pulse += delta
	if _pulse >= Tuning.RADIO_PULSE:
		_pulse -= Tuning.RADIO_PULSE
		_bus.emit(global_position, Tuning.NOISE_RADIO, &"radio")
