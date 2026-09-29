extends Node
## Autoload. Registers input actions in code (readable, and no hand-written
## InputEvent blobs in project.godot) and holds settings shared across scenes.

## Seconds per tile when a unit walks; scaled by the animation-speed setting.
var anim_speed: float = 1.0


func _ready() -> void:
	_register_inputs()


func _register_inputs() -> void:
	_bind("cursor_up", [KEY_UP, KEY_W])
	_bind("cursor_down", [KEY_DOWN, KEY_S])
	_bind("cursor_left", [KEY_LEFT, KEY_A])
	_bind("cursor_right", [KEY_RIGHT, KEY_D])
	_bind("confirm", [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_bind("cancel", [KEY_X, KEY_ESCAPE, KEY_BACKSPACE])
	_bind("next_unit", [KEY_TAB])
	_bind("toggle_danger", [KEY_R])
	_bind("end_turn", [KEY_E])
	_bind("art_measure", [KEY_M])
	_bind("art_cut", [KEY_C])
	_bind("art_turn", [KEY_T])
	_bind("unravel", [KEY_U])
	var undo := InputEventKey.new()
	undo.keycode = KEY_Z
	undo.ctrl_pressed = true
	InputMap.action_add_event("unravel", undo)
	_bind_mouse("confirm", MOUSE_BUTTON_LEFT)
	_bind_mouse("cancel", MOUSE_BUTTON_RIGHT)


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(action, ev)


func _bind_mouse(action: String, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


## Duration helper so every animation honours the speed setting.
func dur(seconds: float) -> float:
	return seconds / maxf(anim_speed, 0.01)
