class_name UnitView
extends Node2D
## One unit on the board: its cameo, an HP arc, and the animation state the
## battle controller tweens (lunge offset, hit flash, displayed HP).

const T := 64.0
const R := 26.0

var uid: int = 0
var team: int = 0
var mark: String = ""
var lord: bool = false
var boss: bool = false
var spent: bool = false
var max_hp: int = 1
## HP as drawn; tweened towards the real value during combat.
var shown_hp: float = 1.0
## Lunge / shake offset in pixels.
var offset := Vector2.ZERO:
	set(v):
		offset = v
		queue_redraw()
var flash: float = 0.0:
	set(v):
		flash = v
		queue_redraw()


func setup(u: Unit) -> void:
	uid = u.uid
	team = u.team
	mark = str(UnitClasses.info(u.class_id).get("mark", ""))
	lord = u.is_lord
	boss = u.is_boss
	refresh(u)
	shown_hp = u.hp
	position = tile_center(u.pos)


func refresh(u: Unit) -> void:
	max_hp = u.max_hp()
	spent = u.acted and u.team == Unit.Team.PLAYER
	queue_redraw()


func set_shown_hp(v: float) -> void:
	shown_hp = v
	queue_redraw()


static func tile_center(c: Vector2i) -> Vector2:
	return Vector2(c) * T + Vector2(T, T) * 0.5


func _draw() -> void:
	var c := offset
	CameoArt.draw(self, c, R, {
		"team": team, "mark": mark, "lord": lord, "boss": boss,
		"spent": spent, "flash": flash,
	})
	# HP arc along the lower rim, left to right.
	var frac := clampf(shown_hp / float(max_hp), 0.0, 1.0)
	var a0 := PI * 0.80
	var span := PI * 0.60
	draw_arc(c, R + 3.5, a0, a0 - span, 20, Color(Palette.INK, 0.55), 4.0, true)
	if frac > 0.0:
		var col := Palette.VERDIGRIS if frac > 0.5 else (Palette.GOLD if frac > 0.25 else Palette.POMPEIAN)
		draw_arc(c, R + 3.5, a0, a0 - span * frac, 20, col, 2.5, true)
