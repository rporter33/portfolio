extends Node
## Autoload. Registers input actions in code (readable, and no hand-written
## InputEvent blobs in project.godot) and holds the player's settings.

const SETTINGS_PATH := "user://settings.cfg"
const SPEEDS := [1.0, 1.5, 2.0, 3.0]

## Animation speed multiplier; every tween duration goes through dur().
var anim_speed: float = 1.0
var fullscreen := false


func _ready() -> void:
	_register_inputs()
	load_settings()


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
	_bind("toggle_fullscreen", [KEY_F11])
	var undo := InputEventKey.new()
	undo.keycode = KEY_Z
	undo.ctrl_pressed = true
	InputMap.action_add_event("unravel", undo)
	var alt_enter := InputEventKey.new()
	alt_enter.keycode = KEY_ENTER
	alt_enter.alt_pressed = true
	InputMap.action_add_event("toggle_fullscreen", alt_enter)
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(not fullscreen)
		save_settings()
		get_viewport().set_input_as_handled()


## Duration helper so every animation honours the speed setting.
func dur(seconds: float) -> float:
	return seconds / maxf(anim_speed, 0.01)


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	anim_speed = float(cfg.get_value("game", "anim_speed", 1.0))
	Sound.music_volume = float(cfg.get_value("audio", "music", Sound.music_volume))
	Sound.sfx_volume = float(cfg.get_value("audio", "sfx", Sound.sfx_volume))
	set_fullscreen(bool(cfg.get_value("display", "fullscreen", false)))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "anim_speed", anim_speed)
	cfg.set_value("audio", "music", Sound.music_volume)
	cfg.set_value("audio", "sfx", Sound.sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)
