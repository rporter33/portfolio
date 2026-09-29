class_name CursorView
extends Node2D
## Gold corner brackets around the cursor tile, breathing slightly.

const T := 64.0

var tile := Vector2i.ZERO
var _time := 0.0


func move_to(t: Vector2i) -> void:
	tile = t
	position = Vector2(t) * T


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var g := 2.0 + 2.0 * sin(_time * 4.0)
	var r := Rect2(Vector2(-g, -g), Vector2(T + g * 2, T + g * 2))
	var arm := 16.0
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		var pts := PackedVector2Array([corner + Vector2(0, arm * sy), corner, corner + Vector2(arm * sx, 0)])
		draw_polyline(pts, Color(Palette.INK, 0.5), 7.0)
		draw_polyline(pts, Palette.GOLD, 4.0)
