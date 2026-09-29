class_name OverlayView
extends Node2D
## Range highlights, the path preview, the danger zone and target markers.
## Tile sets are Dictionaries used as sets (Vector2i → true).

const T := 64.0

var move_tiles := {}
var attack_tiles := {}
var heal_tiles := {}
var danger_tiles := {}
var marked_tiles := {}
var path: Array[Vector2i] = []
var targets: Array[Vector2i] = []
var seize_tile := Vector2i(-1, -1)
var _time := 0.0


func clear_ranges() -> void:
	move_tiles = {}
	attack_tiles = {}
	heal_tiles = {}
	path = []
	targets = []
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if not targets.is_empty() or seize_tile.x >= 0:
		queue_redraw()


func _draw() -> void:
	for t in danger_tiles:
		_fill(t, Palette.DANGER_FILL)
	_edges(danger_tiles, Palette.DANGER_EDGE, 2.0)
	for t in marked_tiles:
		_fill(t, Color(Palette.TERRACOTTA, 0.22))
	_edges(marked_tiles, Color(Palette.TERRACOTTA_DEEP, 0.9), 2.0)
	for t in move_tiles:
		_fill(t, Palette.MOVE_FILL)
	for t in attack_tiles:
		if not move_tiles.has(t):
			_fill(t, Palette.ATTACK_FILL)
	for t in heal_tiles:
		if not move_tiles.has(t):
			_fill(t, Palette.HEAL_FILL)
	_edges(move_tiles, Color(Palette.MARBLE, 0.7), 1.5)
	if seize_tile.x >= 0:
		var pulse := 0.5 + 0.5 * sin(_time * 3.0)
		draw_rect(Rect2(Vector2(seize_tile) * T, Vector2(T, T)).grow(-3), Color(Palette.GOLD, 0.5 + 0.4 * pulse), false, 3.0)
	_draw_path()
	for t in targets:
		var ctr := Vector2(t) * T + Vector2(T, T) * 0.5
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		draw_arc(ctr, 30 + pulse * 3, 0, TAU, 40, Palette.POMPEIAN, 3.0, true)


func _fill(t: Vector2i, col: Color) -> void:
	draw_rect(Rect2(Vector2(t) * T, Vector2(T, T)).grow(-1), col)


## Outline the boundary of a tile set.
func _edges(tiles: Dictionary, col: Color, width: float) -> void:
	for t in tiles:
		var o := Vector2(t) * T
		if not tiles.has(t + Vector2i(0, -1)):
			draw_line(o, o + Vector2(T, 0), col, width)
		if not tiles.has(t + Vector2i(0, 1)):
			draw_line(o + Vector2(0, T), o + Vector2(T, T), col, width)
		if not tiles.has(t + Vector2i(-1, 0)):
			draw_line(o, o + Vector2(0, T), col, width)
		if not tiles.has(t + Vector2i(1, 0)):
			draw_line(o + Vector2(T, 0), o + Vector2(T, T), col, width)


## A gold thread from the unit to the destination, ending in an arrowhead.
func _draw_path() -> void:
	if path.size() < 2:
		return
	var pts := PackedVector2Array()
	for t in path:
		pts.append(Vector2(t) * T + Vector2(T, T) * 0.5)
	draw_polyline(pts, Color(Palette.INK, 0.35), 9.0, true)
	draw_polyline(pts, Palette.GOLD, 5.0, true)
	var tip := pts[pts.size() - 1]
	var dir := (tip - pts[pts.size() - 2]).normalized()
	var side := Vector2(-dir.y, dir.x)
	var head := PackedVector2Array([tip + dir * 12, tip - dir * 4 + side * 11, tip - dir * 4 - side * 11])
	draw_colored_polygon(head, Palette.GOLD)
	draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]), Palette.GOLD_DEEP, 1.5, true)
