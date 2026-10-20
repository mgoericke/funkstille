class_name Player
extends CharacterBody3D
## Ich-Perspektive: Yaw am Body, Pitch am Head, Kamera mit Taschenlampe, Schrittgeraeusche.
## Ducken ist ein Umschalter, Rennen nur gehalten und nicht geduckt.

## Nach je Tuning.STEP_DIST Bodenstrecke
signal stepped(pos: Vector3, crouching: bool)

const HEAD_STAND := 1.6
const HEAD_CROUCH := 0.95
const BODY_STAND := 1.8
const BODY_CROUCH := 1.1
const RADIUS := 0.35
const ACCEL := 30.0
const GRAVITY := 20.0
const MAX_PITCH := deg_to_rad(85.0)
const HEAD_FOLLOW := 12.0
const BOB_HEIGHT := 0.025
const BOB_PER_METER := 2.2  # Wippen pro Meter (rad/m)
const STEP_SOUNDS := 4

var crouching := false
var sprinting := false
var flashlight_on := true
var input_enabled := true
var held_bottle: Node3D = null

var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var hold_point: Node3D

var _pitch := 0.0
var _shape: CapsuleShape3D
var _col: CollisionShape3D
var _step_dist := 0.0
var _bob := 0.0
var _step_audio: AudioStreamPlayer3D
var _click_audio: AudioStreamPlayer3D
var _steps: Array[AudioStream] = []
var _last_step := -1


func _ready() -> void:
	_col = CollisionShape3D.new()
	_shape = CapsuleShape3D.new()
	_shape.radius = RADIUS
	_shape.height = BODY_STAND
	_col.shape = _shape
	_col.position.y = BODY_STAND / 2.0
	add_child(_col)

	head = Node3D.new()
	head.name = "Head"
	head.position.y = HEAD_STAND
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.near = 0.05
	head.add_child(camera)
	flashlight = Look.flashlight()
	camera.add_child(flashlight)
	hold_point = Node3D.new()
	hold_point.name = "HoldPoint"
	hold_point.position = Vector3(0.28, -0.22, -0.65)
	camera.add_child(hold_point)

	for i in STEP_SOUNDS:
		_steps.append(load("res://sounds/step_concrete_%d.wav" % (i + 1)))
	_step_audio = AudioStreamPlayer3D.new()
	_step_audio.name = "StepAudio"
	_step_audio.max_polyphony = 2
	add_child(_step_audio)
	_click_audio = AudioStreamPlayer3D.new()
	_click_audio.name = "ClickAudio"
	_click_audio.stream = load("res://sounds/click_light.wav")
	camera.add_child(_click_audio)

	floor_snap_length = 0.3
	_capture_mouse(true)


func _capture_mouse(on: bool) -> void:
	# Ohne Fenster (headless-Tests) gibt es nichts einzufangen
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and DisplayServer.get_name() != "headless":
		_capture_mouse(Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)
		return
	if event is InputEventMouseMotion and input_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(-event.relative.x * Tuning.MOUSE_SENS, -event.relative.y * Tuning.MOUSE_SENS)


func _look(d_yaw: float, d_pitch: float) -> void:
	rotation.y += d_yaw
	_pitch = clampf(_pitch + d_pitch, -MAX_PITCH, MAX_PITCH)
	head.rotation.x = _pitch


func step_noise_radius() -> float:
	if sprinting:
		return Tuning.NOISE_SPRINT
	return Tuning.NOISE_CROUCH if crouching else Tuning.NOISE_WALK


func toggle_flashlight() -> void:
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	_click_audio.play()


func reset_to(xform: Transform3D) -> void:
	var fwd := -xform.basis.z
	global_position = xform.origin
	rotation = Vector3(0.0, atan2(-fwd.x, -fwd.z), 0.0)
	_pitch = clampf(asin(clampf(fwd.normalized().y, -1.0, 1.0)), -MAX_PITCH, MAX_PITCH)
	head.rotation = Vector3(_pitch, 0.0, 0.0)
	velocity = Vector3.ZERO
	_set_crouching(false, true)
	sprinting = false
	_step_dist = 0.0
	camera.position.y = 0.0


func _set_crouching(on: bool, force := false) -> void:
	if not on and crouching and not force and _blocked_above():
		return
	crouching = on
	var h := BODY_CROUCH if on else BODY_STAND
	_shape.height = h
	_col.position.y = h / 2.0
	if force:
		head.position.y = HEAD_CROUCH if on else HEAD_STAND


## Zu wenig Platz zum Aufstehen?
func _blocked_above() -> bool:
	return test_move(global_transform, Vector3.UP * (BODY_STAND - BODY_CROUCH))


func _physics_process(delta: float) -> void:
	var move := Vector2.ZERO
	if input_enabled:
		if Input.is_action_just_pressed(&"crouch"):
			_set_crouching(not crouching)
		if Input.is_action_just_pressed(&"flashlight"):
			toggle_flashlight()
		move = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		var pad := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
		if pad != Vector2.ZERO:
			_look(-pad.x * Tuning.PAD_LOOK * delta, -pad.y * Tuning.PAD_LOOK * delta)

	sprinting = input_enabled and not crouching and move != Vector2.ZERO and Input.is_action_pressed(&"sprint")
	var speed := Tuning.CROUCH_SPEED if crouching else (Tuning.SPRINT_SPEED if sprinting else Tuning.WALK_SPEED)
	var dir := (global_transform.basis * Vector3(move.x, 0.0, move.y))
	dir.y = 0.0
	var target := dir.limit_length(1.0) * speed
	var horiz := Vector2(velocity.x, velocity.z).move_toward(Vector2(target.x, target.z), ACCEL * delta)
	velocity.x = horiz.x
	velocity.z = horiz.y
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	var before := global_position
	move_and_slide()
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()

	if is_on_floor() and moved > 0.0:
		_step_dist += moved
		_bob += moved * BOB_PER_METER
		if _step_dist >= Tuning.STEP_DIST:
			_step_dist -= Tuning.STEP_DIST
			_on_step()
	camera.position.y = lerpf(camera.position.y, sin(_bob) * BOB_HEIGHT if moved > 0.0 else 0.0, minf(1.0, 10.0 * delta))

	var h_target := HEAD_CROUCH if crouching else HEAD_STAND
	head.position.y = lerpf(head.position.y, h_target, 1.0 - exp(-HEAD_FOLLOW * delta))


func _on_step() -> void:
	stepped.emit(global_position, crouching)
	var r := step_noise_radius()
	var i := randi() % STEP_SOUNDS
	if i == _last_step:
		i = (i + 1) % STEP_SOUNDS
	_last_step = i
	_step_audio.stream = _steps[i]
	_step_audio.volume_db = -14.0 if crouching else (2.0 if sprinting else -4.0)
	_step_audio.play()
	if r > 0.0:
		# Ueber den Pfad: in --script-Tests sind Autoloads zur Kompilierzeit unbekannt
		get_node("/root/NoiseBus").emit(global_position, r, &"sprint" if sprinting else &"step")
