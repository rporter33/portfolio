class_name SceneryArt
extends RefCounted
## Backdrops for dialogue scenes, drawn as faint marble line-work on lapis
## so the cameos in front of them stay the subject.

const FILL := Color(0.925, 0.906, 0.863, 0.07)
const LINE := Color(0.925, 0.906, 0.863, 0.24)


static func draw(ci: CanvasItem, kind: String, s: Vector2, t: float) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, s), Palette.LAPIS_DEEP)
	for i in 10:
		ci.draw_circle(Vector2(s.x * 0.5, s.y * 0.4), s.length() * (0.6 - i * 0.05), Color(Palette.LAPIS, 0.10))
	var horizon := s.y * 0.62
	match kind:
		"academy":
			_stars(ci, s, t)
			TempleArt.draw_facade(ci, Vector2(s.x * 0.5, horizon + 40), minf(s.x * 0.46, s.y * 0.8), FILL, LINE)
		"temple":
			TempleArt.draw_facade(ci, Vector2(s.x * 0.5, horizon + 40), minf(s.x * 0.52, s.y * 0.9), FILL, LINE)
		"night":
			_stars(ci, s, t)
			return
		"road":
			_hills(ci, s, horizon)
			_olive_trees(ci, s, horizon)
		"aqueduct":
			_stars(ci, s, t)
			_aqueduct(ci, s, horizon)
	ci.draw_line(Vector2(0, horizon + 40), Vector2(s.x, horizon + 40), LINE, 1.0)


static func _stars(ci: CanvasItem, s: Vector2, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 60:
		var p := Vector2(rng.randf() * s.x, rng.randf() * s.y * 0.45)
		var tw := 0.5 + 0.5 * sin(t * (0.8 + rng.randf()) + i)
		ci.draw_circle(p, 1.0 + rng.randf(), Color(Palette.MARBLE, 0.15 + 0.25 * tw))


static func _hills(ci: CanvasItem, s: Vector2, horizon: float) -> void:
	for layer in 2:
		var pts := PackedVector2Array([Vector2(0, s.y)])
		for k in 33:
			var x := s.x * k / 32.0
			var y := horizon - 60 + layer * 50 - sin(x * 0.006 + layer * 2.0) * 40 - sin(x * 0.017 + layer) * 14
			pts.append(Vector2(x, y))
		pts.append(Vector2(s.x, s.y))
		ci.draw_colored_polygon(pts, Color(FILL, FILL.a * (1.0 + layer)))
		var ridge := pts.slice(1, pts.size() - 1)
		ci.draw_polyline(ridge, LINE, 1.0, true)
	# The Hill Gate on the far ridge.
	var g := Vector2(s.x * 0.72, horizon - 88)
	for dx in [-22.0, 12.0]:
		ci.draw_rect(Rect2(g + Vector2(dx, 0), Vector2(10, 34)), LINE)
	ci.draw_rect(Rect2(g + Vector2(-26, -6), Vector2(52, 6)), LINE)


static func _olive_trees(ci: CanvasItem, s: Vector2, horizon: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 9:
		var x := s.x * (0.05 + 0.11 * i) + rng.randf_range(-20, 20)
		var base := Vector2(x, horizon + 30 + rng.randf_range(-10, 10))
		ci.draw_line(base, base + Vector2(4, -40), LINE, 2.0, true)
		for k in 4:
			var c := base + Vector2(rng.randf_range(-22, 26), -44 - rng.randf_range(0, 24))
			ci.draw_circle(c, rng.randf_range(12, 20), FILL)
			ci.draw_arc(c, rng.randf_range(12, 20), 0, TAU, 20, LINE, 1.0, true)


static func _aqueduct(ci: CanvasItem, s: Vector2, horizon: float) -> void:
	var top := horizon - 170
	var h := 150.0
	var span := 90.0
	var n := int(s.x / span) + 2
	ci.draw_rect(Rect2(0, top - 26, s.x, 26), FILL)
	ci.draw_rect(Rect2(0, top - 26, s.x, 26), LINE, false, 1.0)
	for i in n:
		var x := i * span - 20
		ci.draw_rect(Rect2(x, top, 22, h), FILL)
		ci.draw_rect(Rect2(x, top, 22, h), LINE, false, 1.0)
		var ctr := Vector2(x + 22 + (span - 22) * 0.5, top + 30)
		ci.draw_arc(ctr, (span - 22) * 0.5, PI, TAU, 24, LINE, 1.5, true)
