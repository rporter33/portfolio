extends Control
## A dialogue scene staged as a frieze: two cameos on a marble band, the
## speaker lit and the listener in shadow, and the line beneath in a panel.
## Z / Enter / click: finish the line, then advance. X / Esc: skip the scene.

signal finished

const CHARS_PER_SEC := 55.0

var scene_id := ""
var _scene := {}
var _lines: Array = []
var _index := -1
var _shown := 0.0
var _time := 0.0
var _left := ""
var _right := ""

var _backdrop: Control
var _left_cameo: CameoPortrait
var _right_cameo: CameoPortrait
var _name: Label
var _text: Label
var _place: Label
var _hint: Label
var _box: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	_scene = Story.scene(scene_id)
	_lines = _scene.get("lines", [])

	_backdrop = Control.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.draw.connect(func() -> void:
		SceneryArt.draw(_backdrop, str(_scene.get("scenery", "academy")), _backdrop.size, _time)
		_draw_frieze())
	add_child(_backdrop)

	_place = UiTheme.label("", 20, "display", Palette.GOLD, 600)
	_place.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_place.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place.position.y = 28
	add_child(_place)

	_left_cameo = CameoPortrait.new()
	_right_cameo = CameoPortrait.new()
	for c in [_left_cameo, _right_cameo]:
		c.custom_minimum_size = Vector2(190, 190)
		c.size = Vector2(190, 190)
		add_child(c)

	_box = PanelContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_stylebox_override("panel", UiTheme.panel_box(Palette.MARBLE, Palette.GOLD, 2))
	add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_box.add_child(v)
	_name = UiTheme.label("", 24, "display", Palette.INK, 700)
	_text = UiTheme.label("", 27, "text", Palette.INK, 600)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(880, 96)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(_name)
	v.add_child(_text)
	_hint = UiTheme.label("Z  continue    ·    X  skip", 16, "text", Palette.INK_SOFT, 600)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_hint)

	resized.connect(_layout)
	_layout.call_deferred()
	var place := "%s  ·  %s" % [str(_scene.get("place", "")), str(_scene.get("time", ""))]
	_place.text = place.to_upper()
	_advance()


func _layout() -> void:
	var s := size
	var band_y := s.y * 0.30
	_left_cameo.position = Vector2(s.x * 0.24 - 95, band_y - 10)
	_right_cameo.position = Vector2(s.x * 0.76 - 95, band_y - 10)
	_box.custom_minimum_size = Vector2(minf(s.x - 120, 960), 0)
	_box.reset_size()
	_box.position = Vector2((s.x - _box.size.x) * 0.5, s.y - _box.size.y - 36)


func _draw_frieze() -> void:
	var s := _backdrop.size
	var band := Rect2(0, s.y * 0.30 + 40, s.x, 110)
	_backdrop.draw_rect(band, Color(Palette.MARBLE, 0.10))
	_backdrop.draw_line(band.position, band.position + Vector2(s.x, 0), Color(Palette.GOLD, 0.6), 2.0)
	_backdrop.draw_line(band.end - Vector2(s.x, 0), band.end, Color(Palette.GOLD, 0.6), 2.0)


func _process(delta: float) -> void:
	_time += delta
	if _index >= 0 and _index < _lines.size():
		var full := str(_lines[_index][1])
		if _shown < full.length():
			_shown = minf(full.length(), _shown + delta * CHARS_PER_SEC * maxf(Game.anim_speed, 1.0))
			_text.visible_characters = int(_shown)
	_backdrop.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") and not event is InputEventMouseButton:
		Sound.play("cancel")
		finished.emit()
	elif event.is_action_pressed("confirm"):
		var full := str(_lines[_index][1]) if _index < _lines.size() else ""
		if _shown < full.length():
			_shown = full.length()
			_text.visible_characters = -1
		else:
			Sound.play("menu")
			_advance()
	else:
		return
	get_viewport().set_input_as_handled()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		finished.emit()
		return
	var speaker := str(_lines[_index][0])
	_name.text = Story.speaker_name(speaker).to_upper()
	_text.text = str(_lines[_index][1])
	_text.visible_characters = 0
	_shown = 0.0
	if speaker == "narrator":
		_text.add_theme_color_override("font_color", Palette.INK_SOFT)
		_left_cameo.modulate = Color(1, 1, 1, 0.35)
		_right_cameo.modulate = Color(1, 1, 1, 0.35)
		return
	_text.add_theme_color_override("font_color", Palette.INK)
	# Speakers take the side they first appear on; a new third speaker
	# replaces whoever spoke least recently.
	if speaker != _left and speaker != _right:
		if _left == "":
			_left = speaker
		elif _right == "":
			_right = speaker
		elif _index > 0 and str(_lines[_index - 1][0]) == _left:
			_right = speaker
		else:
			_left = speaker
	_set_cameo(_left_cameo, _left, 1.0)
	_set_cameo(_right_cameo, _right, -1.0)
	var lit := Color(1, 1, 1, 1)
	var dim := Color(0.55, 0.55, 0.6, 0.75)
	_left_cameo.modulate = lit if speaker == _left else dim
	_right_cameo.modulate = lit if speaker == _right else dim
	_name.add_theme_color_override("font_color", Palette.TERRACOTTA_DEEP if speaker in Story.ENEMY_SPEAKERS else Palette.INK)


func _set_cameo(c: CameoPortrait, speaker: String, facing: float) -> void:
	if speaker == "":
		c.opts = {}
		c.queue_redraw()
		return
	var team := 1 if speaker in Story.ENEMY_SPEAKERS else 0
	c.show_character(speaker, team)
	c.opts["facing"] = facing
	c.queue_redraw()
