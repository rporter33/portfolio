class_name BoardView
extends Node2D
## Draws the terrain, seen straight down, per docs/ART_DIRECTION.md "Tiles".
## Static: drawn once when the map is set.

const T := 64.0

var map: BattleMap
var seize_tile := Vector2i(-1, -1)


func set_map(m: BattleMap, seize: Vector2i = Vector2i(-1, -1)) -> void:
	map = m
	seize_tile = seize
	queue_redraw()


## Deterministic per-tile noise in [0, 1).
static func noise(x: int, y: int, k: int = 0) -> float:
	var n := (x * 73856093) ^ (y * 19349663) ^ (k * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65536.0


func _draw() -> void:
	if map == null:
		return
	# A lapis margin frames the board like a mount.
	var full := Rect2(Vector2.ZERO, Vector2(map.width, map.height) * T)
	draw_rect(full.grow(10), Palette.GOLD_DEEP)
	draw_rect(full.grow(7), Palette.LAPIS_DEEP)
	for y in map.height:
		for x in map.width:
			_draw_tile(Vector2i(x, y))
	# A whisper of grid so tiles read as tiles.
	var grid := Color(Palette.INK, 0.07)
	for x in range(1, map.width):
		draw_line(Vector2(x * T, 0), Vector2(x * T, map.height * T), grid, 1.0)
	for y in range(1, map.height):
		draw_line(Vector2(0, y * T), Vector2(map.width * T, y * T), grid, 1.0)
	draw_rect(full, Palette.GOLD, false, 2.0)


func _draw_tile(c: Vector2i) -> void:
	var ch := map.char_at(c)
	var o := Vector2(c) * T
	var r := Rect2(o, Vector2(T, T))
	var h := noise(c.x, c.y)
	match ch:
		".":
			_plaza(o, c, h)
		",":
			_meadow(o, c, h)
		"_":
			_road(o, c, h)
		"t":
			_meadow(o, c, h)
			_grove(o, c)
		"|":
			_plaza(o, c, h)
			_column(o)
		"^":
			_plaza(o, c, h)
			_rubble(o, c)
		"s":
			draw_rect(r, Palette.TRAVERTINE.lerp(Palette.MARBLE, 0.3))
			for i in 5:
				var y := o.y + 6 + i * 12.0
				draw_rect(Rect2(o.x, y + 8, T, 3), Color(Palette.INK, 0.10))
				draw_line(Vector2(o.x, y), Vector2(o.x + T, y), Color(Palette.MARBLE, 0.8), 2.0)
		"A":
			_plaza(o, c, h)
			_altar(o)
		"G":
			_road(o, c, h)
			_gate(o, c == seize_tile)
		"=":
			_bridge(o, c)
		"~":
			_pool(o, c)
		"#":
			_wall(o, c)
		_:
			draw_rect(r, Palette.STONE)


func _plaza(o: Vector2, c: Vector2i, h: float) -> void:
	var base := Palette.MARBLE.lerp(Palette.MARBLE_SHADE, h * 0.7)
	draw_rect(Rect2(o, Vector2(T, T)), base)
	# Slab joints.
	draw_rect(Rect2(o + Vector2(1, 1), Vector2(T - 2, T - 2)), Color(Palette.VEIN, 0.45), false, 1.0)
	# One vein wandering across the slab.
	var a := o + Vector2(noise(c.x, c.y, 1) * T, 2)
	var m := o + Vector2(noise(c.x, c.y, 2) * T, T * 0.5)
	var b := o + Vector2(noise(c.x, c.y, 3) * T, T - 2)
	if noise(c.x, c.y, 4) > 0.45:
		draw_polyline(PackedVector2Array([a, m.lerp(a, 0.3) + Vector2(6, 0), m, b]), Color(Palette.VEIN, 0.55), 1.0, true)


func _meadow(o: Vector2, c: Vector2i, h: float) -> void:
	draw_rect(Rect2(o, Vector2(T, T)), Palette.MEADOW.lerp(Palette.LAUREL, h * 0.5))
	for i in 4:
		var p := o + Vector2(8 + noise(c.x, c.y, 10 + i) * (T - 16), 8 + noise(c.x, c.y, 20 + i) * (T - 16))
		var col := Color(Palette.LAUREL.darkened(0.2), 0.8)
		draw_line(p, p + Vector2(0, -7), col, 1.2, true)
		draw_line(p + Vector2(0, -3), p + Vector2(-3, -6), col, 1.2, true)
		draw_line(p + Vector2(0, -4), p + Vector2(3, -7), col, 1.2, true)


func _road(o: Vector2, c: Vector2i, h: float) -> void:
	draw_rect(Rect2(o, Vector2(T, T)), Palette.TRAVERTINE.lerp(Palette.MARBLE_SHADE, h * 0.4))
	for i in 6:
		var p := o + Vector2(6 + noise(c.x, c.y, 30 + i) * (T - 12), 6 + noise(c.x, c.y, 40 + i) * (T - 12))
		draw_circle(p, 2.0 + noise(c.x, c.y, 50 + i) * 2.0, Color(Palette.STONE, 0.35))


func _grove(o: Vector2, c: Vector2i) -> void:
	var canopy := Color("#8C9A6C")
	var centres := [Vector2(0.30, 0.32), Vector2(0.70, 0.40), Vector2(0.44, 0.72)]
	for p in centres:
		var q: Vector2 = o + p * T + Vector2(noise(c.x, c.y, 60) * 6 - 3, noise(c.x, c.y, 61) * 6 - 3)
		draw_circle(q + Vector2(4, 6), 13, Color(Palette.CYPRESS, 0.45))
	for p in centres:
		var q: Vector2 = o + p * T + Vector2(noise(c.x, c.y, 60) * 6 - 3, noise(c.x, c.y, 61) * 6 - 3)
		draw_circle(q, 13, canopy.darkened(0.12))
		draw_circle(q + Vector2(-2, -2), 10, canopy)
		draw_circle(q + Vector2(-4, -4), 4, canopy.lightened(0.18))


func _column(o: Vector2) -> void:
	var ctr := o + Vector2(T, T) * 0.5
	draw_circle(ctr + Vector2(6, 8), 21, Color(Palette.INK, 0.22))
	draw_circle(ctr, 22, Palette.VEIN)
	draw_circle(ctr, 20, Palette.MARBLE)
	# Fluting, seen end-on.
	for i in 16:
		var a := TAU * float(i) / 16.0
		draw_line(ctr + Vector2(cos(a), sin(a)) * 13, ctr + Vector2(cos(a), sin(a)) * 19, Color(Palette.VEIN, 0.8), 1.5, true)
	draw_circle(ctr, 12, Palette.MARBLE.lightened(0.3))
	draw_arc(ctr, 12, 0, TAU, 32, Color(Palette.VEIN, 0.8), 1.0, true)


func _rubble(o: Vector2, c: Vector2i) -> void:
	for i in 4:
		var p := o + Vector2(10 + noise(c.x, c.y, 70 + i) * (T - 24), 10 + noise(c.x, c.y, 80 + i) * (T - 24))
		var sz := Vector2(10 + noise(c.x, c.y, 90 + i) * 10, 7 + noise(c.x, c.y, 95 + i) * 6)
		var ang := noise(c.x, c.y, 99 + i) * PI
		draw_set_transform(p, ang)
		draw_rect(Rect2(-sz * 0.5 + Vector2(2, 3), sz), Color(Palette.INK, 0.2))
		draw_rect(Rect2(-sz * 0.5, sz), Palette.STONE.lightened(0.15))
		draw_rect(Rect2(-sz * 0.5, sz), Palette.STONE_DEEP, false, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0)


func _altar(o: Vector2) -> void:
	var ctr := o + Vector2(T, T) * 0.5
	draw_rect(Rect2(o + Vector2(8, 10), Vector2(T - 12, T - 12)), Color(Palette.INK, 0.2))
	draw_rect(Rect2(o + Vector2(6, 6), Vector2(T - 12, T - 12)), Palette.MARBLE.lightened(0.2))
	draw_rect(Rect2(o + Vector2(6, 6), Vector2(T - 12, T - 12)), Palette.GOLD_DEEP, false, 2.0)
	draw_arc(ctr, 16, 0, TAU, 40, Palette.GOLD, 3.0, true)
	draw_circle(ctr, 6, Palette.POMPEIAN)
	draw_circle(ctr + Vector2(0, -1), 3.5, Palette.GOLD.lightened(0.3))


func _gate(o: Vector2, is_objective: bool) -> void:
	var pylon := Palette.MARBLE.lightened(0.15)
	for x in [4.0, T - 18.0]:
		draw_rect(Rect2(o + Vector2(x + 3, 8), Vector2(14, T - 12)), Color(Palette.INK, 0.22))
		draw_rect(Rect2(o + Vector2(x, 4), Vector2(14, T - 12)), pylon)
		draw_rect(Rect2(o + Vector2(x, 4), Vector2(14, T - 12)), Palette.VEIN, false, 1.0)
	# The lintel, wreathed.
	draw_rect(Rect2(o + Vector2(2, 2), Vector2(T - 4, 9)), Palette.GOLD if is_objective else Palette.VEIN)
	for i in 7:
		var p := o + Vector2(8 + i * 8.0, 6.5)
		draw_circle(p, 3.0, Palette.LAUREL)
	if is_objective:
		draw_rect(Rect2(o + Vector2(18, 16), Vector2(T - 36, T - 24)), Color(Palette.GOLD, 0.25))


func _bridge(o: Vector2, c: Vector2i) -> void:
	_pool(o, c)
	var horizontal := map.char_at(c + Vector2i(1, 0)) != "~" or map.char_at(c + Vector2i(-1, 0)) != "~"
	var deck := Rect2(o + Vector2(0, 8), Vector2(T, T - 16)) if horizontal else Rect2(o + Vector2(8, 0), Vector2(T - 16, T))
	draw_rect(deck.grow(1), Color(Palette.INK, 0.25))
	draw_rect(deck, Palette.TRAVERTINE)
	if horizontal:
		draw_line(deck.position, deck.position + Vector2(T, 0), Palette.MARBLE, 3.0)
		draw_line(deck.end - Vector2(T, 0), deck.end, Palette.MARBLE, 3.0)
	else:
		draw_line(deck.position, deck.position + Vector2(0, T), Palette.MARBLE, 3.0)
		draw_line(deck.end - Vector2(0, T), deck.end, Palette.MARBLE, 3.0)


func _pool(o: Vector2, c: Vector2i) -> void:
	draw_rect(Rect2(o, Vector2(T, T)), Palette.LAPIS)
	for i in 3:
		var y := o.y + 14 + i * 18.0 + noise(c.x, c.y, 110 + i) * 6
		var x0 := o.x + 6 + noise(c.x, c.y, 120 + i) * 20
		draw_line(Vector2(x0, y), Vector2(x0 + 18, y), Color(Palette.JASPER, 0.7), 1.5, true)
	# Marble kerb where the water meets land.
	var kerb := Palette.MARBLE
	for d in BattleMap.DIRS:
		var n: Vector2i = c + d
		if not map.in_bounds(n):
			continue
		var nc := map.char_at(n)
		if nc == "~" or nc == "=":
			continue
		if d.x == 1:
			draw_rect(Rect2(o + Vector2(T - 5, 0), Vector2(5, T)), kerb)
		elif d.x == -1:
			draw_rect(Rect2(o, Vector2(5, T)), kerb)
		elif d.y == 1:
			draw_rect(Rect2(o + Vector2(0, T - 5), Vector2(T, 5)), kerb)
		else:
			draw_rect(Rect2(o, Vector2(T, 5)), kerb)


func _wall(o: Vector2, c: Vector2i) -> void:
	draw_rect(Rect2(o, Vector2(T, T)), Palette.STONE)
	var course := Palette.STONE_DEEP
	for row in 4:
		var y := o.y + row * 16.0
		draw_line(Vector2(o.x, y), Vector2(o.x + T, y), course, 1.0)
		var shift := 16.0 if (row + c.x + c.y) % 2 == 0 else 0.0
		for k in 3:
			var x := o.x + shift + k * 32.0
			if x > o.x and x < o.x + T:
				draw_line(Vector2(x, y), Vector2(x, y + 16), course, 1.0)
		draw_line(Vector2(o.x, y + 1), Vector2(o.x + T, y + 1), Color(Palette.MARBLE, 0.25), 1.0)
