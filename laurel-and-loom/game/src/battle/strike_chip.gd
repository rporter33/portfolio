class_name StrikeChip
extends Control
## One strike in the combat forecast: who swings, the bead it will draw, and
## what that bead does — or what it might do, if the bead isn't visible yet.

var strike := {}
var team := 0
var striker := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(76, 92)


func setup(s: Dictionary, striker_team: int, striker_name: String) -> void:
	strike = s
	team = striker_team
	striker = striker_name
	queue_redraw()


func _draw() -> void:
	if strike.is_empty():
		return
	var w := size.x
	var col: Color = Palette.TEAM_FIELD_DEEP[team]
	draw_rect(Rect2(4, 0, w - 8, 4), col)
	var small := UiTheme.display(700)
	var name_w := small.get_string_size(striker, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(small, Vector2((w - name_w) * 0.5, 18), striker, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	var c := Vector2(w * 0.5, 40)
	var vis := "hidden"
	var value := 50
	if int(strike["bead"]) >= 0:
		vis = "exact"
		value = int(strike["bead"])
	elif int(strike["omen"]) >= 0:
		vis = "omen"
		value = [15, 50, 85][int(strike["omen"])]
	BeadArt.draw(self, c, 16.0, value, vis)
	var outcome := str(strike["outcome"])
	var text := ""
	var tcol := Palette.INK
	match outcome:
		"hit":
			text = "HIT %d" % int(strike.get("dealt", strike["dmg"]))
		"crit":
			text = "CRIT %d" % int(strike.get("dealt", strike["dmg"]))
			tcol = Palette.GOLD_DEEP
		"miss":
			text = "MISS"
			tcol = Palette.STONE_DEEP
		_:
			text = "? %d%%" % int(strike["hit"])
			tcol = Palette.INK_SOFT
	var f := UiTheme.display(700)
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(f, Vector2((w - tw) * 0.5, 80), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tcol)
