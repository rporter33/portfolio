class_name BattleMap
extends RefCounted
## A rectangular grid of terrain characters, read from ASCII rows.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var width: int = 0
var height: int = 0
var _rows: PackedStringArray = PackedStringArray()


func _init(rows: PackedStringArray = PackedStringArray()) -> void:
	_rows = rows
	height = rows.size()
	width = rows[0].length() if height > 0 else 0
	for r in rows:
		assert(r.length() == width, "BattleMap rows must all be the same width")


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func char_at(c: Vector2i) -> String:
	if not in_bounds(c):
		return "#"
	return _rows[c.y][c.x]


func terrain(c: Vector2i) -> Dictionary:
	return Terrain.info(char_at(c))


func move_cost(c: Vector2i, move_type: String) -> int:
	return Terrain.move_cost(char_at(c), move_type)


func neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		var n := c + d
		if in_bounds(n):
			out.append(n)
	return out


func find_all(ch: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in height:
		for x in width:
			if _rows[y][x] == ch:
				out.append(Vector2i(x, y))
	return out


func rows() -> PackedStringArray:
	return _rows


static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Every in-bounds tile whose Manhattan distance from `from` is in [lo, hi].
func tiles_in_range(from: Vector2i, lo: int, hi: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-hi, hi + 1):
		for dx in range(-hi, hi + 1):
			var d := absi(dx) + absi(dy)
			if d < lo or d > hi:
				continue
			var t := from + Vector2i(dx, dy)
			if in_bounds(t):
				out.append(t)
	return out
