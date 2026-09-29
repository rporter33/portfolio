class_name TempleArt
extends RefCounted
## A hexastyle Ionic temple front, drawn in outline and low-contrast fills:
## the backdrop for the title and for dialogue scenes.


## `base` is the bottom-centre of the lowest step; `w` the stylobate width.
static func draw_facade(ci: CanvasItem, base: Vector2, w: float, fill: Color, line: Color) -> void:
	var step_h := w * 0.018
	# Three steps.
	for i in 3:
		var sw := w * (1.0 - 0.025 * i)
		var r := Rect2(base.x - sw * 0.5, base.y - step_h * (i + 1), sw, step_h)
		ci.draw_rect(r, fill)
		ci.draw_rect(r, line, false, 1.0)
	var floor_y := base.y - step_h * 3
	var colonnade_w := w * 0.9
	var col_h := w * 0.36
	var col_w := w * 0.052
	var n := 6
	var gap := (colonnade_w - col_w) / float(n - 1)
	var left := base.x - colonnade_w * 0.5
	for i in n:
		var x := left + gap * i
		_column(ci, Vector2(x + col_w * 0.5, floor_y), col_w, col_h, fill, line)
	# Entablature: architrave, frieze (with a meander), cornice.
	var top := floor_y - col_h
	var ent_w := colonnade_w + col_w * 0.6
	var arch := Rect2(base.x - ent_w * 0.5, top - w * 0.03, ent_w, w * 0.03)
	var frieze := Rect2(arch.position.x, arch.position.y - w * 0.04, ent_w, w * 0.04)
	var cornice := Rect2(arch.position.x - w * 0.012, frieze.position.y - w * 0.014, ent_w + w * 0.024, w * 0.014)
	for r in [arch, frieze, cornice]:
		ci.draw_rect(r, fill)
		ci.draw_rect(r, line, false, 1.0)
	_meander(ci, frieze.grow(-frieze.size.y * 0.18), line)
	# Pediment, with a laurel cameo in the tympanum.
	var pb := cornice.position.y
	var pw := cornice.size.x
	var ph := w * 0.13
	var tri := PackedVector2Array([Vector2(base.x - pw * 0.5, pb), Vector2(base.x, pb - ph), Vector2(base.x + pw * 0.5, pb)])
	ci.draw_colored_polygon(tri, fill)
	ci.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), line, 1.5, true)
	var inner := PackedVector2Array([
		tri[0].lerp(tri[1], 0.12) + Vector2(pw * 0.05, 0), tri[1] + Vector2(0, ph * 0.2), tri[2].lerp(tri[1], 0.12) - Vector2(pw * 0.05, 0)])
	inner[0].y = pb - ph * 0.08
	inner[2].y = pb - ph * 0.08
	ci.draw_polyline(PackedVector2Array([inner[0], inner[1], inner[2], inner[0]]), Color(line, line.a * 0.7), 1.0, true)
	var cameo_c := Vector2(base.x, pb - ph * 0.36)
	CameoArt.draw(ci, cameo_c, ph * 0.28, {"team": 0, "mark": "laurel", "lord": true})


static func _column(ci: CanvasItem, foot: Vector2, cw: float, ch: float, fill: Color, line: Color) -> void:
	var base_h := cw * 0.35
	ci.draw_rect(Rect2(foot.x - cw * 0.62, foot.y - base_h, cw * 1.24, base_h), fill)
	ci.draw_rect(Rect2(foot.x - cw * 0.62, foot.y - base_h, cw * 1.24, base_h), line, false, 1.0)
	var shaft_top := foot.y - ch + cw * 0.5
	var shaft := PackedVector2Array([
		Vector2(foot.x - cw * 0.5, foot.y - base_h), Vector2(foot.x - cw * 0.42, shaft_top),
		Vector2(foot.x + cw * 0.42, shaft_top), Vector2(foot.x + cw * 0.5, foot.y - base_h)])
	ci.draw_colored_polygon(shaft, fill)
	for k in 5:
		var t := float(k + 1) / 6.0
		var x0 := lerpf(foot.x - cw * 0.5, foot.x + cw * 0.5, t)
		var x1 := lerpf(foot.x - cw * 0.42, foot.x + cw * 0.42, t)
		ci.draw_line(Vector2(x0, foot.y - base_h), Vector2(x1, shaft_top), Color(line, line.a * 0.6), 1.0, true)
	ci.draw_polyline(shaft, line, 1.0, true)
	# Ionic capital: an abacus and two volutes.
	var cap := Rect2(foot.x - cw * 0.75, shaft_top - cw * 0.3, cw * 1.5, cw * 0.3)
	ci.draw_rect(cap, fill)
	ci.draw_rect(cap, line, false, 1.0)
	for side in [-1.0, 1.0]:
		var vc := Vector2(foot.x + side * cw * 0.62, shaft_top - cw * 0.02)
		ci.draw_arc(vc, cw * 0.2, 0, TAU, 16, line, 1.0, true)
		ci.draw_arc(vc, cw * 0.08, 0, TAU, 10, line, 1.0, true)


static func _meander(ci: CanvasItem, r: Rect2, col: Color) -> void:
	var unit := r.size.y
	var count := int(r.size.x / unit)
	var x0 := r.position.x + (r.size.x - count * unit) * 0.5
	for i in count:
		var o := Vector2(x0 + i * unit, r.position.y)
		var pts := PackedVector2Array()
		for p in [Vector2(0.10, 1.0), Vector2(0.10, 0.12), Vector2(0.82, 0.12), Vector2(0.82, 0.78),
				Vector2(0.36, 0.78), Vector2(0.36, 0.42), Vector2(0.60, 0.42)]:
			pts.append(o + p * unit)
		ci.draw_polyline(pts, col, 1.0)
