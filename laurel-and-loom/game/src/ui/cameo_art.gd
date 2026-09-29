class_name CameoArt
extends RefCounted
## Draws a unit as a cameo medallion (docs/ART_DIRECTION.md, "Units: cameos"):
## a rim, a team-coloured field, and a relief bust in profile with a class
## mark. Static so the board, the info panel and dialogue portraits share it.

## A classical profile bust facing right, in a unit box (radius-relative).
const BUST := [
	Vector2(-0.58, 0.92), Vector2(-0.47, 0.50), Vector2(-0.40, 0.24), Vector2(-0.50, 0.04),
	Vector2(-0.53, -0.26), Vector2(-0.43, -0.54), Vector2(-0.16, -0.70), Vector2(0.14, -0.66),
	Vector2(0.30, -0.48), Vector2(0.34, -0.30), Vector2(0.49, -0.06), Vector2(0.37, -0.02),
	Vector2(0.39, 0.07), Vector2(0.34, 0.12), Vector2(0.37, 0.18), Vector2(0.31, 0.27),
	Vector2(0.17, 0.35), Vector2(0.09, 0.44), Vector2(0.14, 0.62), Vector2(0.44, 0.80),
	Vector2(0.56, 0.92),
]

## A helmet cap that sits over the bust's skull.
const HELMET := [
	Vector2(-0.56, 0.10), Vector2(-0.58, -0.28), Vector2(-0.46, -0.60), Vector2(-0.16, -0.78),
	Vector2(0.16, -0.72), Vector2(0.36, -0.50), Vector2(0.38, -0.36), Vector2(0.20, -0.38),
	Vector2(0.10, -0.30), Vector2(0.04, 0.06), Vector2(-0.24, 0.12),
]

## A veil falling from the crown down the back.
const VEIL := [
	Vector2(0.30, -0.50), Vector2(0.12, -0.74), Vector2(-0.20, -0.80), Vector2(-0.52, -0.62),
	Vector2(-0.64, -0.24), Vector2(-0.66, 0.30), Vector2(-0.70, 0.92), Vector2(-0.40, 0.92),
	Vector2(-0.44, 0.40), Vector2(-0.36, -0.10), Vector2(-0.20, -0.46), Vector2(0.10, -0.60),
]

## A horse's head in profile, facing right.
const HORSE := [
	Vector2(-0.30, 0.60), Vector2(-0.22, 0.10), Vector2(-0.10, -0.25), Vector2(-0.14, -0.45),
	Vector2(-0.02, -0.34), Vector2(0.14, -0.22), Vector2(0.42, 0.02), Vector2(0.46, 0.14),
	Vector2(0.36, 0.20), Vector2(0.14, 0.12), Vector2(0.06, 0.30), Vector2(0.10, 0.60),
]


## Draw a cameo on `ci` centred at `c` with outer radius `r`.
## opts: team (int), mark (String), lord (bool), boss (bool), spent (bool),
##       facing (1 right / -1 left), flash (0..1)
static func draw(ci: CanvasItem, c: Vector2, r: float, opts: Dictionary) -> void:
	var team: int = opts.get("team", 0)
	var spent: bool = opts.get("spent", false)
	var facing: float = opts.get("facing", 1.0 if team == 0 else -1.0)
	var mark: String = opts.get("mark", "")
	var lordly: bool = opts.get("lord", false) or opts.get("boss", false)

	var field: Color = Palette.TEAM_FIELD[team]
	var field_deep: Color = Palette.TEAM_FIELD_DEEP[team]
	var relief: Color = Palette.TEAM_RELIEF[team]
	var rim := Palette.GOLD if lordly else Palette.BRONZE
	if spent:
		field = Palette.grey_marble(field)
		field_deep = Palette.grey_marble(field_deep)
		relief = Palette.grey_marble(relief).lerp(Palette.MARBLE, 0.4) if team == 0 else Palette.STONE_DEEP
		rim = Palette.STONE

	# Shadow, rim, field.
	ci.draw_circle(c + Vector2(0, r * 0.12), r * 1.02, Color(0, 0, 0, 0.28))
	ci.draw_circle(c, r, rim)
	ci.draw_circle(c, r * 0.97, rim.lightened(0.18))
	ci.draw_circle(c, r * 0.88, field_deep)
	ci.draw_circle(c + Vector2(0, -r * 0.03), r * 0.85, field)
	ci.draw_arc(c, r * 0.80, 0, TAU, 48, Color(relief, 0.28), maxf(1.0, r * 0.03), true)
	if opts.get("boss", false):
		ci.draw_arc(c, r * 0.93, 0, TAU, 48, Palette.POMPEIAN if not spent else Palette.STONE, maxf(1.5, r * 0.05), true)

	var s := r * 0.72
	var bust_off := Vector2(-0.06 * facing, 0.06) * r
	if mark == "horse":
		_poly(ci, HORSE, c + Vector2(0.30 * facing, 0.10) * r, s * 0.9, facing, Color(relief, 0.85))
		bust_off = Vector2(-0.20 * facing, 0.10) * r
		s *= 0.86
	if mark == "bow":
		var bc := c + bust_off + Vector2(-0.34 * facing, 0.20) * s
		ci.draw_arc(bc, s * 0.62, PI * 0.5 + 0.9 * facing, PI * 0.5 + (PI - 0.9) * facing, 16, relief, maxf(1.5, r * 0.06), true)
		ci.draw_line(bc + Vector2(-0.24 * facing, -0.50) * s, bc + Vector2(-0.24 * facing, 0.62) * s, Color(relief, 0.7), 1.0, true)
	if mark == "fasces":
		var fc := c + bust_off + Vector2(-0.50 * facing, 0.05) * s
		for i in 4:
			var dx := (float(i) - 1.5) * 0.07 * s
			ci.draw_line(fc + Vector2(dx, -0.62 * s), fc + Vector2(dx, 0.85 * s), relief, maxf(1.2, r * 0.05), true)
		var blade := [Vector2(0.0, -0.62), Vector2(-0.34, -0.80), Vector2(-0.36, -0.40), Vector2(0.0, -0.46)]
		_poly(ci, blade, fc, s, facing, relief)
	if mark == "veil":
		_poly(ci, VEIL, c + bust_off, s, facing, relief.darkened(0.08) if team == 0 else relief)

	_poly(ci, BUST, c + bust_off, s, facing, relief)
	# The eye and the line of the brow, cut into the relief.
	var cut := field_deep if team == 0 else Color(field, 0.9)
	var eye := c + bust_off + Vector2(0.20 * facing, -0.26) * s
	ci.draw_line(eye, eye + Vector2(0.08 * facing, 0.0) * s, cut, maxf(1.0, r * 0.045), true)
	ci.draw_line(eye + Vector2(-0.04 * facing, -0.07) * s, eye + Vector2(0.12 * facing, -0.08) * s, Color(cut, 0.6), maxf(1.0, r * 0.03), true)

	match mark:
		"laurel":
			_laurel(ci, c + bust_off, s, facing, Palette.GOLD if not spent else Palette.STONE_DEEP)
		"crest":
			_poly(ci, HELMET, c + bust_off, s, facing, relief.darkened(0.12) if team == 0 else relief)
			_crest(ci, c + bust_off, s, facing, relief, false)
		"helm":
			_poly(ci, HELMET, c + bust_off, s * 1.04, facing, relief.darkened(0.12) if team == 0 else relief)
			_crest(ci, c + bust_off, s, facing, relief, opts.get("boss", false))
		"scroll":
			var sc := c + bust_off + Vector2(0.30 * facing, 0.62) * s
			ci.draw_rect(Rect2(sc - Vector2(0.22, 0.10) * s, Vector2(0.44, 0.20) * s), relief)
			ci.draw_circle(sc - Vector2(0.22 * s, 0), 0.11 * s, relief.darkened(0.15))
			ci.draw_circle(sc + Vector2(0.22 * s, 0), 0.11 * s, relief.darkened(0.15))

	if opts.get("flash", 0.0) > 0.0:
		ci.draw_circle(c, r, Color(1, 0.97, 0.88, float(opts["flash"]) * 0.8))


static func _poly(ci: CanvasItem, pts: Array, origin: Vector2, s: float, facing: float, col: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(origin + Vector2(p.x * facing, p.y) * s)
	ci.draw_colored_polygon(out, col)


static func _laurel(ci: CanvasItem, origin: Vector2, s: float, facing: float, col: Color) -> void:
	# Leaves along the crown, from the nape over to the brow.
	var centre := origin + Vector2(-0.10 * facing, -0.20) * s
	for i in 7:
		var a := lerpf(PI * 0.95, PI * 0.30, float(i) / 6.0)
		var ang := a if facing > 0 else PI - a
		var p := centre + Vector2(cos(ang), -sin(ang)) * s * 0.56
		var leaf := PackedVector2Array()
		var dir := Vector2(cos(ang + PI * 0.5 * facing), -sin(ang + PI * 0.5 * facing)) * s * 0.13
		var side := Vector2(-dir.y, dir.x) * 0.45
		leaf.append(p - dir)
		leaf.append(p + side)
		leaf.append(p + dir)
		leaf.append(p - side)
		ci.draw_colored_polygon(leaf, col)


static func _crest(ci: CanvasItem, origin: Vector2, s: float, facing: float, col: Color, transverse: bool) -> void:
	var base := origin + Vector2(-0.12 * facing, -0.70) * s
	if transverse:
		# A centurion's crest runs ear to ear: seen in profile, a tall fan.
		for i in 9:
			var t := float(i) / 8.0
			var x := lerpf(-0.30, 0.20, t) * facing
			ci.draw_line(base + Vector2(x, 0.02) * s, base + Vector2(x * 1.2, -0.30 - 0.06 * sin(t * PI)) * s, col, maxf(1.0, s * 0.05), true)
		return
	for i in 9:
		var t := float(i) / 8.0
		var ang := lerpf(PI * 0.95, PI * 0.25, t)
		var a2 := ang if facing > 0 else PI - ang
		var root := origin + Vector2(-0.08 * facing, -0.28) * s + Vector2(cos(a2), -sin(a2)) * s * 0.48
		var tip := origin + Vector2(-0.08 * facing, -0.28) * s + Vector2(cos(a2), -sin(a2)) * s * 0.72
		ci.draw_line(root, tip, col, maxf(1.0, s * 0.06), true)
