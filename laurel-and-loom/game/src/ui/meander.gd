class_name Meander
extends Control
## A Greek-key band: two rules with a running key between them.

@export var color := Palette.GOLD
@export var line_width := 2.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var h := size.y
	if h <= 2.0:
		return
	var w := size.x
	var pad := line_width
	var inner := h - pad * 2
	draw_line(Vector2(0, pad * 0.5), Vector2(w, pad * 0.5), color, line_width)
	draw_line(Vector2(0, h - pad * 0.5), Vector2(w, h - pad * 0.5), color, line_width)
	var unit := inner
	var count := int(w / unit)
	var x0 := (w - count * unit) * 0.5
	for i in count:
		var o := Vector2(x0 + i * unit, pad)
		var pts := PackedVector2Array()
		for p in [Vector2(0.10, 1.0), Vector2(0.10, 0.12), Vector2(0.82, 0.12), Vector2(0.82, 0.78),
				Vector2(0.36, 0.78), Vector2(0.36, 0.42), Vector2(0.60, 0.42)]:
			pts.append(o + p * unit)
		draw_polyline(pts, color, line_width)
