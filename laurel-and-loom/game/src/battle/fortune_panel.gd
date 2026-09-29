class_name FortunePanel
extends PanelContainer
## Rota Fortunae: the Fortune gauge as a six-spoked wheel, and the buttons
## for the Fate Arts and Unravel. Emits `art_pressed`; the controller decides
## whether the art is allowed.

signal art_pressed(art: String)

var _wheel: Control
var _fortune := 0
var _spin := 0.0
var _buttons := {}
var _count: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := UiTheme.panel_box(Color(Palette.LAPIS_DEEP, 0.92), Palette.GOLD, 2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	add_child(h)
	_wheel = Control.new()
	_wheel.custom_minimum_size = Vector2(80, 80)
	_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel.draw.connect(_draw_wheel)
	h.add_child(_wheel)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 2)
	h.add_child(grid)
	for spec in [["measure", "Measure", "M", 1], ["cut", "Cut", "C", 2],
			["turn", "Turn", "T", 3], ["unravel", "Unravel", "U", 0]]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(118, 36)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Palette.MARBLE)
		b.add_theme_color_override("font_hover_color", Palette.INK)
		b.add_theme_color_override("font_disabled_color", Color(Palette.MARBLE, 0.3))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(Palette.LAPIS, 0.9)
		normal.border_color = Color(Palette.GOLD, 0.6)
		normal.set_border_width_all(1)
		normal.content_margin_left = 8
		normal.content_margin_right = 8
		b.add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Palette.GOLD
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		var dis := normal.duplicate() as StyleBoxFlat
		dis.bg_color = Color(Palette.LAPIS_DEEP, 0.9)
		dis.border_color = Color(Palette.GOLD, 0.2)
		b.add_theme_stylebox_override("disabled", dis)
		b.tooltip_text = _tooltip(spec[0])
		b.pressed.connect(func() -> void: art_pressed.emit(spec[0]))
		b.set_meta("label", spec[1])
		b.set_meta("key", spec[2])
		b.set_meta("cost", spec[3])
		grid.add_child(b)
		_buttons[spec[0]] = b


static func _tooltip(art: String) -> String:
	match art:
		"measure":
			return "Lachesis — see every visible bead exactly until your phase ends."
		"cut":
			return "Atropos — discard the front bead."
		"turn":
			return "Rota Fortunae — invert the front bead (b becomes 101 − b)."
		"unravel":
			return "Undo your last action. Three times a battle."
	return ""


func sync(st: BattleState, can_unravel: bool, interactive: bool) -> void:
	_fortune = st.fortune
	for art in ["measure", "cut", "turn"]:
		var b: Button = _buttons[art]
		b.text = "%s  %d   [%s]" % [b.get_meta("label"), int(b.get_meta("cost")), b.get_meta("key")]
		b.disabled = not (interactive and st.can_use_art(art))
	var u: Button = _buttons["unravel"]
	u.text = "%s  ×%d  [U]" % [u.get_meta("label"), st.unravels_left]
	u.disabled = not (interactive and can_unravel)
	_wheel.queue_redraw()


## A quarter-turn of the wheel when Fortune rises.
func celebrate() -> void:
	_spin = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_spin = v
		_wheel.queue_redraw(), 0.0, TAU / 6.0, Game.dur(0.5)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _draw_wheel() -> void:
	var c := _wheel.size * 0.5
	var r := minf(c.x, c.y) - 3.0
	_wheel.draw_circle(c, r, Palette.LAPIS)
	for i in BattleState.FORTUNE_MAX:
		var a0 := -PI * 0.5 + TAU * float(i) / BattleState.FORTUNE_MAX + _spin
		var a1 := a0 + TAU / BattleState.FORTUNE_MAX
		if i < _fortune:
			var pts := PackedVector2Array([c])
			for k in 9:
				var a := lerpf(a0 + 0.05, a1 - 0.05, float(k) / 8.0)
				pts.append(c + Vector2(cos(a), sin(a)) * (r - 4))
			_wheel.draw_colored_polygon(pts, Palette.GOLD)
		_wheel.draw_line(c, c + Vector2(cos(a0), sin(a0)) * r, Palette.GOLD_DEEP, 2.0, true)
	_wheel.draw_arc(c, r, 0, TAU, 40, Palette.GOLD, 3.0, true)
	_wheel.draw_circle(c, r * 0.32, Palette.LAPIS_DEEP)
	_wheel.draw_arc(c, r * 0.32, 0, TAU, 24, Palette.GOLD, 2.0, true)
	var f := UiTheme.display(700)
	var txt := str(_fortune)
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	_wheel.draw_string(f, c + Vector2(-w * 0.5, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.MARBLE)
