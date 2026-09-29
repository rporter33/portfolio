extends Control
## End of the First Act: the companions who made it, stood in a frieze with
## their levels; the fallen named beneath; the turns each chapter took.

signal done

var campaign: Campaign
var _time := 0.0
var _backdrop: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	_backdrop = Control.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.draw.connect(func() -> void: SceneryArt.draw(_backdrop, "night", _backdrop.size, _time))
	add_child(_backdrop)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var over := UiTheme.label("HERE ENDS", 22, "display", Palette.GOLD, 600)
	over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(over)
	var title := UiTheme.label("THE FIRST ACT", 64, "display", Palette.MARBLE, 700)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var m := Meander.new()
	m.custom_minimum_size = Vector2(520, 16)
	m.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(m)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)
	for d in campaign.living_companions():
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var cam := CameoPortrait.new()
		cam.custom_minimum_size = Vector2(96, 96)
		cam.show_character(str(d["id"]))
		cell.add_child(cam)
		var n := UiTheme.label(str(d["name"]).get_slice(" ", 0).to_upper(), 16, "display", Palette.MARBLE, 700)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(n)
		var lv := UiTheme.label("Level %s" % UiTheme.roman(int(d["level"])), 18, "text", Palette.GOLD, 600)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(lv)
		row.add_child(cell)

	var fallen := campaign.fallen_companions()
	if not fallen.is_empty():
		var names: Array[String] = []
		for d in fallen:
			names.append(str(d["name"]))
		var f := UiTheme.label("Remembered: " + ", ".join(names), 22, "text", Palette.MARBLE, 500)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(f)

	var parts: Array[String] = []
	for id in Chapters.ORDER:
		if campaign.turns.has(id):
			parts.append("%s — %s turns" % [Chapters.data(id)["numeral"], UiTheme.roman(int(campaign.turns[id]))])
	var t := UiTheme.label("   ·   ".join(parts), 20, "text", Color(Palette.MARBLE, 0.8), 500)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var mode := UiTheme.label("%s campaign" % campaign.mode.capitalize(), 18, "text", Color(Palette.MARBLE, 0.6), 500)
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(mode)
	var cont := UiTheme.label("Z  return to the title", 18, "display", Palette.GOLD, 600)
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cont)


func _process(delta: float) -> void:
	_time += delta
	_backdrop.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Sound.play("confirm")
		done.emit()
