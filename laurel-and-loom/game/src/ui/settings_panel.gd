extends PanelContainer
## Settings overlay: display mode, music and effects volume, animation speed.
## ↑↓ choose · ←→ change · Z change / close · X close. Clicking a row steps it.

signal closed

const ROWS := ["display", "music", "sfx", "speed", "done"]

var index := 0
var _buttons := {}
var _highlight: StyleBoxFlat


func _ready() -> void:
	theme = UiTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UiTheme.panel_box(Palette.MARBLE, Palette.GOLD, 3))
	_highlight = StyleBoxFlat.new()
	_highlight.bg_color = Color(Palette.GOLD, 0.38)
	_highlight.border_color = Palette.GOLD_DEEP
	_highlight.border_width_left = 4
	_highlight.content_margin_left = 12
	_highlight.content_margin_right = 12
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	var head := UiTheme.label("SETTINGS", 28, "display", Palette.INK, 700)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var m := Meander.new()
	m.custom_minimum_size = Vector2(0, 14)
	v.add_child(m)
	for i in ROWS.size():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(440, 40)
		b.pressed.connect(func() -> void:
			index = i
			_activate(1))
		b.mouse_entered.connect(func() -> void:
			index = i
			_refresh())
		v.add_child(b)
		_buttons[ROWS[i]] = b
	var hint := UiTheme.label("↑↓ choose  ·  ←→ change  ·  X close", 16, "text", Palette.INK_SOFT, 600)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	_refresh()
	reset_size()
	var vp := get_viewport_rect().size
	position = (vp - size) * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cursor_up", true):
		index = posmod(index - 1, ROWS.size())
		Sound.play("menu")
	elif event.is_action_pressed("cursor_down", true):
		index = posmod(index + 1, ROWS.size())
		Sound.play("menu")
	elif event.is_action_pressed("cursor_left", true):
		_activate(-1)
	elif event.is_action_pressed("cursor_right", true):
		_activate(1)
	elif event.is_action_pressed("confirm") and not event is InputEventMouseButton:
		_activate(1)
	elif event.is_action_pressed("cancel"):
		_close()
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()


func _activate(dir: int) -> void:
	match ROWS[index]:
		"display":
			Game.set_fullscreen(not Game.fullscreen)
		"music":
			Sound.music_volume = clampf(snappedf(Sound.music_volume + 0.1 * dir, 0.1), 0.0, 1.0)
			Sound.apply_volumes()
		"sfx":
			Sound.sfx_volume = clampf(snappedf(Sound.sfx_volume + 0.1 * dir, 0.1), 0.0, 1.0)
			Sound.play("select")
		"speed":
			var i := Game.SPEEDS.find(Game.anim_speed)
			Game.anim_speed = Game.SPEEDS[posmod(i + dir, Game.SPEEDS.size())]
		"done":
			_close()
			return
	Sound.play("menu")
	_refresh()


func _refresh() -> void:
	var labels := {
		"display": "Display          %s" % ("Fullscreen" if Game.fullscreen else "Windowed"),
		"music": "Music            %d%%" % int(round(Sound.music_volume * 100)),
		"sfx": "Effects          %d%%" % int(round(Sound.sfx_volume * 100)),
		"speed": "Animation      %s×" % str(Game.anim_speed).trim_suffix(".0"),
		"done": "Done",
	}
	for i in ROWS.size():
		var b: Button = _buttons[ROWS[i]]
		b.text = labels[ROWS[i]]
		if i == index:
			b.add_theme_stylebox_override("normal", _highlight)
			b.add_theme_stylebox_override("hover", _highlight)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")


func _close() -> void:
	Game.save_settings()
	Sound.play("cancel")
	closed.emit()
	queue_free()
