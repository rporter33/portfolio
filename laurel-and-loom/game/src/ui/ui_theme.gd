class_name UiTheme
extends RefCounted
## Fonts and the shared Control theme: marble panels ruled in gold, Cinzel for
## display, Cormorant Garamond for text. Built once in code and cached.

const CINZEL_PATH := "res://assets/fonts/Cinzel-Variable.ttf"
const CORMORANT_PATH := "res://assets/fonts/CormorantGaramond-Variable.ttf"

static var _theme: Theme
static var _fonts := {}


## Cinzel (display) or Cormorant (text) at a given weight.
static func font(family: String = "text", weight: int = 500) -> Font:
	var key := "%s-%d" % [family, weight]
	if _fonts.has(key):
		return _fonts[key]
	var base: FontFile = load(CINZEL_PATH if family == "display" else CORMORANT_PATH)
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {"wght": weight}
	_fonts[key] = v
	return v


static func display(weight: int = 600) -> Font:
	return font("display", weight)


static func text(weight: int = 500) -> Font:
	return font("text", weight)


static func panel_box(fill: Color = Palette.MARBLE, border: Color = Palette.GOLD, width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = text(600)
	t.default_font_size = 20

	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())

	t.set_color("font_color", "Label", Palette.INK)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(Palette.GOLD, 0.28)
	hover.border_color = Palette.GOLD_DEEP
	hover.border_width_left = 3
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(Palette.GOLD, 0.45)
	var disabled := normal.duplicate() as StyleBoxFlat
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", disabled)
	t.set_font("font", "Button", display(600))
	t.set_font_size("font_size", "Button", 19)
	t.set_color("font_color", "Button", Palette.INK)
	t.set_color("font_hover_color", "Button", Palette.INK)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_focus_color", "Button", Palette.INK)
	t.set_color("font_hover_pressed_color", "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", Color(Palette.INK, 0.35))
	_theme = t
	return t


## A Label with the given family, size and colour.
static func label(txt: String, size: int = 20, family: String = "text", color: Color = Palette.INK, weight: int = 600) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font(family, weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func roman(n: int) -> String:
	if n <= 0:
		return str(n)
	var vals := [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var syms := ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var out := ""
	for i in vals.size():
		while n >= vals[i]:
			out += syms[i]
			n -= vals[i]
	return out
