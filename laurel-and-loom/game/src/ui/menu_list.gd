class_name MenuList
extends PanelContainer
## A small command menu driven by both keyboard (the controller calls move()
## and activate()) and mouse. Items: [{"id": String, "label": String,
## "enabled": bool, "hint": String}].

signal chosen(id: String)

var items: Array = []
var index := 0
var _box := VBoxContainer.new()
var _buttons: Array[Button] = []
var _highlight: StyleBoxFlat


func _init() -> void:
	theme = UiTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := UiTheme.panel_box()
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)
	_box.add_theme_constant_override("separation", 2)
	add_child(_box)
	_highlight = StyleBoxFlat.new()
	_highlight.bg_color = Color(Palette.GOLD, 0.38)
	_highlight.border_color = Palette.GOLD_DEEP
	_highlight.border_width_left = 4
	_highlight.content_margin_left = 12
	_highlight.content_margin_right = 12
	_highlight.content_margin_top = 4
	_highlight.content_margin_bottom = 4
	visible = false


func open(new_items: Array, at: Vector2) -> void:
	items = new_items
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for i in items.size():
		var it: Dictionary = items[i]
		var b := Button.new()
		b.text = str(it["label"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not it.get("enabled", true)
		b.custom_minimum_size = Vector2(170, 34)
		b.pressed.connect(_on_pressed.bind(i))
		b.mouse_entered.connect(_on_hover.bind(i))
		_box.add_child(b)
		_buttons.append(b)
	index = 0
	while index < items.size() - 1 and not items[index].get("enabled", true):
		index += 1
	_restyle()
	visible = true
	reset_size()
	var vp := get_viewport_rect().size
	position = Vector2(clampf(at.x, 8, vp.x - size.x - 8), clampf(at.y, 8, vp.y - size.y - 8))


func close() -> void:
	visible = false
	items = []


func move(delta: int) -> void:
	if items.is_empty():
		return
	for _i in items.size():
		index = posmod(index + delta, items.size())
		if items[index].get("enabled", true):
			break
	_restyle()


func activate() -> void:
	if visible and index < items.size() and items[index].get("enabled", true):
		chosen.emit(str(items[index]["id"]))


func current_id() -> String:
	return str(items[index]["id"]) if index < items.size() else ""


func _on_pressed(i: int) -> void:
	index = i
	activate()


func _on_hover(i: int) -> void:
	if items[i].get("enabled", true) and index != i:
		index = i
		_restyle()
		Sound.play("menu", 1.0, -6.0)


func _restyle() -> void:
	for i in _buttons.size():
		if i == index:
			_buttons[i].add_theme_stylebox_override("normal", _highlight)
			_buttons[i].add_theme_stylebox_override("hover", _highlight)
		else:
			_buttons[i].remove_theme_stylebox_override("normal")
			_buttons[i].remove_theme_stylebox_override("hover")
