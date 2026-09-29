class_name DustEffect
extends Node2D
## A fallen unit cracks and falls away as marble dust.

var _parts: Array = []
var _cracks: Array = []
var _t := 0.0
var _dur := 0.9
var _color := Palette.MARBLE


func setup(at: Vector2, relief: Color, field: Color) -> void:
	position = at
	_color = relief
	var rnd := RandomNumberGenerator.new()
	rnd.seed = int(at.x * 31 + at.y * 17)
	for i in 26:
		var a := rnd.randf() * TAU
		var r := rnd.randf() * 20.0
		_parts.append({
			"p": Vector2(cos(a), sin(a)) * r,
			"v": Vector2(cos(a), sin(a)) * rnd.randf_range(20, 90) + Vector2(0, -40),
			"s": rnd.randf_range(2.0, 5.0),
			"c": relief if i % 3 else field,
		})
	for i in 4:
		var a := rnd.randf() * TAU
		var pts := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		for k in 3:
			a += rnd.randf_range(-0.6, 0.6)
			p += Vector2(cos(a), sin(a)) * rnd.randf_range(6, 10)
			pts.append(p)
		_cracks.append(pts)


func _process(delta: float) -> void:
	_t += delta / Game.dur(1.0)
	for p in _parts:
		p["v"] += Vector2(0, 160) * delta / Game.dur(1.0)
		p["p"] += p["v"] * delta / Game.dur(1.0)
	queue_redraw()
	if _t >= _dur:
		queue_free()


func _draw() -> void:
	var k := clampf(_t / _dur, 0.0, 1.0)
	if k < 0.35:
		for c in _cracks:
			draw_polyline(c, Color(Palette.INK, 0.8 * (1.0 - k / 0.35)), 1.5, true)
	for p in _parts:
		var col: Color = p["c"]
		draw_rect(Rect2(p["p"] - Vector2.ONE * p["s"] * 0.5, Vector2.ONE * p["s"]), Color(col, 1.0 - k))
