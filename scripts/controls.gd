class_name Controls
## Eingabe-Aktionen fuer Tastatur/Maus und Controller. Beides gleichzeitig nutzbar.
## Maus-Blick laeuft in Player._unhandled_input, nicht ueber Aktionen.

const DEADZONE := 0.2

static var ACTIONS: Dictionary = _build()


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


static func _btn(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e


static func _axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	return e


static func _mouse(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	return e


static func _build() -> Dictionary:
	return {
		&"move_forward": [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		&"move_back": [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)],
		&"move_left": [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)],
		&"move_right": [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)],
		&"look_up": [_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		&"look_down": [_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		&"look_left": [_axis(JOY_AXIS_RIGHT_X, -1.0)],
		&"look_right": [_axis(JOY_AXIS_RIGHT_X, 1.0)],
		&"crouch": [_key(KEY_C), _key(KEY_CTRL), _btn(JOY_BUTTON_B)],
		&"sprint": [_key(KEY_SHIFT), _btn(JOY_BUTTON_LEFT_STICK)],
		&"flashlight": [_key(KEY_F), _btn(JOY_BUTTON_Y)],
		&"radio": [_key(KEY_R), _btn(JOY_BUTTON_X)],
		&"interact": [_key(KEY_E), _btn(JOY_BUTTON_A)],
		&"throw": [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		&"pause": [_key(KEY_ESCAPE), _btn(JOY_BUTTON_START)],
	}


## Legt alle Aktionen in der InputMap an. Mehrfaches Aufrufen schadet nicht.
static func register() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEADZONE)
		for ev in ACTIONS[action]:
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)
