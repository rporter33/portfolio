class_name CameoPortrait
extends Control
## A Control that shows a unit's cameo, for panels and dialogue.

var opts := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_unit(u: Unit) -> void:
	if u == null:
		opts = {}
	else:
		opts = {
			"team": u.team, "mark": str(UnitClasses.info(u.class_id).get("mark", "")),
			"lord": u.is_lord, "boss": u.is_boss,
		}
	queue_redraw()


func show_character(char_id: String, team: int = 0) -> void:
	var d := Characters.info(char_id)
	opts = {
		"team": team, "mark": str(UnitClasses.info(str(d.get("class", ""))).get("mark", "")),
		"lord": d.get("lord", false), "boss": d.get("boss", false),
	}
	queue_redraw()


func _draw() -> void:
	if opts.is_empty():
		return
	var r := minf(size.x, size.y) * 0.5 - 4.0
	CameoArt.draw(self, size * 0.5, r, opts)
