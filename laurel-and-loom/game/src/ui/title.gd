extends Control
## The title screen: a temple front in faint marble, the Measured Thread
## swaying across it, and the menu.

signal chosen(id: String)

var menu: MenuList
var _time := 0.0
var _beads: Array[int] = []
var _backdrop: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1017
	for i in 11:
		_beads.append(rng.randi_range(1, 100))
	_backdrop = Control.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.draw.connect(_draw_backdrop)
	add_child(_backdrop)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.position.y = 70
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 6)
	add_child(col)
	var over := UiTheme.label("A TACTICAL TALE OF THE MEASURED THREAD", 18, "display", Palette.GOLD, 600)
	over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(over)
	var title := UiTheme.label("LAUREL & LOOM", 92, "display", Palette.MARBLE, 700)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(Palette.INK, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 4)
	col.add_child(title)
	var rule := Meander.new()
	rule.custom_minimum_size = Vector2(560, 18)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(rule)
	var tag := UiTheme.label("Fortune is a thread. Read it, cut it, turn it.", 28, "text", Palette.MARBLE, 500)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tag)

	var v := Engine.get_version_info()
	var foot := UiTheme.label("v%s  ·  Godot %d.%d.%d" % [ProjectSettings.get_setting("application/config/version", "0"),
		v["major"], v["minor"], v["patch"]], 16, "text", Color(Palette.MARBLE, 0.5), 500)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	foot.position = Vector2(-16, -30)
	foot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(foot)

	menu = MenuList.new()
	add_child(menu)
	menu.chosen.connect(func(id: String) -> void:
		Sound.play("confirm")
		chosen.emit(id))


func open_menu(items: Array) -> void:
	await get_tree().process_frame
	menu.open(items, Vector2(size.x * 0.5 - 95, size.y * 0.5 + 150))


func _process(delta: float) -> void:
	_time += delta
	_backdrop.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not menu.visible:
		return
	if event.is_action_pressed("cursor_up", true):
		menu.move(-1)
		Sound.play("menu")
	elif event.is_action_pressed("cursor_down", true):
		menu.move(1)
		Sound.play("menu")
	elif event.is_action_pressed("confirm") and not event is InputEventMouseButton:
		menu.activate()
	else:
		return
	get_viewport().set_input_as_handled()


func _draw_backdrop() -> void:
	var s := size
	if s.x < 2.0 or s.y < 2.0:
		return
	var ci := _backdrop
	# A lapis field, deeper at the edges.
	ci.draw_rect(Rect2(Vector2.ZERO, s), Palette.LAPIS_DEEP)
	for i in 12:
		var r := s.length() * (0.62 - i * 0.04)
		ci.draw_circle(Vector2(s.x * 0.5, s.y * 0.62), r, Color(Palette.LAPIS, 0.10))
	TempleArt.draw_facade(ci, Vector2(s.x * 0.5, s.y + 6), minf(s.x * 0.58, 760.0),
		Color(Palette.MARBLE, 0.08), Color(Palette.MARBLE, 0.24))
	# The thread: a slack gold line with beads hanging from it.
	var y0 := s.y * 0.63
	var pts := PackedVector2Array()
	for k in 64:
		var x := lerpf(-20, s.x + 20, float(k) / 63.0)
		var u := (x / s.x) - 0.5
		pts.append(Vector2(x, y0 + 60.0 * (u * u * 4.0 - 1.0) * 0.5 + sin(_time * 0.9 + x * 0.01) * 3.0))
	ci.draw_polyline(pts, Color(Palette.GOLD, 0.8), 2.0, true)
	for i in _beads.size():
		var fx := (float(i) + 0.5) / _beads.size()
		if absf(fx - 0.5) < 0.16:
			continue  # leave the middle clear for the menu
		var x := fx * s.x
		var u := fx - 0.5
		var ty := y0 + 60.0 * (u * u * 4.0 - 1.0) * 0.5 + sin(_time * 0.9 + x * 0.01) * 3.0
		var sway := sin(_time * 1.4 + i) * 4.0
		var c := Vector2(x + sway, ty + 44)
		ci.draw_line(Vector2(x, ty), c - Vector2(0, 16), Color(Palette.GOLD, 0.7), 1.2, true)
		var vis := "exact" if i % 3 != 2 else "omen"
		BeadArt.draw(ci, c, 16.0, _beads[i], vis, 0.85)
