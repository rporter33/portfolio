class_name ThreadBar
extends Control
## The Measured Thread across the top of the screen: a gold thread with beads
## hanging from it like loom weights, the front bead on the left.
##
## Normally mirrors state.thread (sync). During a fight the controller holds
## the display and pops a bead per strike, so the player watches the thread
## being spent; then syncs again.

const SPACING := 58.0
const R := 20.0
const HIDDEN_SHOWN := 2
const LEFT := 96.0

var _items: Array = []       ## [{"value": int, "vis": String}]
var _marks: Array = []       ## [{"index": int, "team": int}]
var _slide := 0.0            ## 1 → 0 as beads glide left after a pop.
var _falling: Array = []     ## [{"value", "vis", "x", "t", "outcome"}]
var _flip := 1.0             ## 1 → -1 while the front bead turns over.
var _flip_to := -1
var _measured := false
var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(LEFT + SPACING * 8 + 24, 96)


func sync(st: BattleState) -> void:
	_items.clear()
	var t := st.thread
	for i in t.visible_count() + HIDDEN_SHOWN:
		var vis := "exact" if t.is_exact(i) else ("omen" if t.is_visible(i) else "hidden")
		_items.append({"value": t.peek(i), "vis": vis})
	_measured = t.measured
	_slide = 0.0
	_flip = 1.0
	_flip_to = -1
	queue_redraw()


func set_marks(marks: Array) -> void:
	_marks = marks
	queue_redraw()


## Animate the front bead leaving the thread, coloured by what it did.
func pop_front(outcome: String) -> void:
	if _items.is_empty():
		return
	var it: Dictionary = _items.pop_front()
	# A bead that was only an omen shows its number as it's drawn.
	_falling.append({"value": it["value"], "vis": "exact", "x": _bead_x(0), "t": 0.0, "outcome": outcome})
	_slide = 1.0
	var tw := create_tween()
	tw.tween_property(self, "_slide", 0.0, Game.dur(0.25)).set_ease(Tween.EASE_OUT)


## Animate the front bead turning over to `new_value`.
func flip_front(new_value: int) -> void:
	if _items.is_empty():
		return
	_flip_to = new_value
	_flip = 1.0
	var tw := create_tween()
	tw.tween_property(self, "_flip", -1.0, Game.dur(0.35))
	tw.tween_callback(func() -> void:
		_items[0]["value"] = _flip_to
		_flip = 1.0
		_flip_to = -1)


func _process(delta: float) -> void:
	_time += delta
	for f in _falling:
		f["t"] += delta / Game.dur(0.7)
	_falling = _falling.filter(func(f: Dictionary) -> bool: return f["t"] < 1.0)
	queue_redraw()


func _bead_x(i: float) -> float:
	return LEFT + 26.0 + i * SPACING


func _draw() -> void:
	var h := size.y
	var thread_y := 16.0
	var bead_y := 50.0
	# Panel.
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, Color(Palette.LAPIS_DEEP, 0.92))
	draw_rect(box, Palette.GOLD, false, 2.0)
	var f := UiTheme.display(700)
	draw_string(f, Vector2(12, 34), "THE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.GOLD)
	draw_string(f, Vector2(12, 52), "THREAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.GOLD)
	if _measured:
		draw_string(UiTheme.text(700), Vector2(12, 74), "measured", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.VERDIGRIS.lightened(0.3))
	# The thread, with a little sway.
	var pts := PackedVector2Array()
	for k in 40:
		var x := lerpf(LEFT - 4, size.x - 6, float(k) / 39.0)
		pts.append(Vector2(x, thread_y + sin(_time * 1.3 + x * 0.02) * 1.2))
	draw_polyline(pts, Palette.GOLD, 2.0, true)

	for i in _items.size():
		var it: Dictionary = _items[i]
		var x := _bead_x(i + _slide)
		var fade := 1.0
		if it["vis"] == "hidden":
			fade = 0.8 - 0.3 * float(i - (_items.size() - HIDDEN_SHOWN))
		var sway := sin(_time * 1.3 + x * 0.02) * 1.2
		draw_line(Vector2(x, thread_y + sway), Vector2(x, bead_y - R), Color(Palette.GOLD, 0.8 * fade), 1.5, true)
		var c := Vector2(x, bead_y)
		for m in _marks:
			if int(m["index"]) == i:
				# A halo in the striker's colour, and a tab on the string.
				var col: Color = Palette.TEAM_FIELD[int(m["team"])]
				draw_circle(c, R + 5, Color(col, 0.95))
				draw_rect(Rect2(x - 5, thread_y + 6, 10, 8), col)
		if i == 0 and _flip < 1.0:
			draw_set_transform(c, 0.0, Vector2(maxf(absf(_flip), 0.05), 1.0))
			BeadArt.draw(self, Vector2.ZERO, R, int(it["value"]) if _flip > 0 else _flip_to, str(it["vis"]), fade)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			BeadArt.draw(self, c, R, int(it["value"]), str(it["vis"]), fade)
		if i == 0:
			draw_string(UiTheme.display(700), Vector2(x - 17, h - 6), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.GOLD)

	for fb in _falling:
		var t: float = fb["t"]
		var c := Vector2(fb["x"], bead_y + t * t * 60.0)
		var col := Palette.MARBLE
		match fb["outcome"]:
			"crit":
				col = Palette.GOLD
			"hit":
				col = Palette.POMPEIAN
			"miss":
				col = Palette.STONE
			"cut":
				col = Palette.VERDIGRIS
		draw_circle(c, R + 4, Color(col, 0.6 * (1.0 - t)))
		BeadArt.draw(self, c, R, int(fb["value"]), str(fb["vis"]), 1.0 - t)
