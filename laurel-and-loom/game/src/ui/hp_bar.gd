class_name HpBar
extends Control
## A slim HP bar ruled in gold.

var value := 1.0
var max_value := 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 10)


func set_hp(v: float, m: float) -> void:
	value = v
	max_value = maxf(m, 1.0)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(Palette.INK, 0.75))
	var frac := clampf(value / max_value, 0.0, 1.0)
	var col := Palette.VERDIGRIS if frac > 0.5 else (Palette.GOLD if frac > 0.25 else Palette.POMPEIAN)
	draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * frac, size.y - 2)), col)
	draw_rect(r, Palette.GOLD_DEEP, false, 1.0)
