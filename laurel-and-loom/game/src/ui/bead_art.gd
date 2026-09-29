class_name BeadArt
extends RefCounted
## Draws one bead of the Measured Thread. Shared by the thread bar and the
## forecast's strike chips so a bead looks the same wherever it appears.
##
## vis: "exact" shows the number; "omen" shows only its tier (fair, middling,
## ill); "hidden" is a blank loom weight.


static func tier_color(omen: int) -> Color:
	return [Palette.VERDIGRIS, Palette.GOLD_DEEP, Palette.POMPEIAN][clampi(omen, 0, 2)]


static func draw(ci: CanvasItem, c: Vector2, r: float, value: int, vis: String, alpha: float = 1.0) -> void:
	var a := alpha
	ci.draw_circle(c + Vector2(0, r * 0.14), r, Color(0, 0, 0, 0.30 * a))
	match vis:
		"exact":
			var tier := tier_color(FateThread.omen_of(value))
			ci.draw_circle(c, r, Color(Palette.MARBLE, a))
			ci.draw_arc(c, r - 1.5, 0, TAU, 32, Color(tier, a), 3.0, true)
			var f := UiTheme.display(700)
			var fs := int(r * 0.95)
			var txt := str(value)
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var asc := f.get_ascent(fs)
			var desc := f.get_descent(fs)
			ci.draw_string(f, c + Vector2(-w * 0.5, (asc - desc) * 0.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Palette.INK, a))
		"omen":
			var t: Color = Palette.OMEN_TINT[FateThread.omen_of(value)]
			ci.draw_circle(c, r, Color(t, a))
			ci.draw_arc(c, r - 1.5, 0, TAU, 32, Color(tier_color(FateThread.omen_of(value)), a), 2.0, true)
			ci.draw_arc(c, r * 0.45, 0, TAU, 20, Color(Palette.MARBLE, 0.55 * a), 1.5, true)
		_:
			ci.draw_circle(c, r, Color(Palette.STONE, 0.55 * a))
			ci.draw_arc(c, r - 1.0, 0, TAU, 32, Color(Palette.MARBLE, 0.25 * a), 1.5, true)
