extends PanelContainer
## The Codex: three short pages on how to play, shown before the prologue and
## any time from the battle menu. Z next · X close.

signal closed

const PAGES := [
	["THE FIELD", "Select a companion, choose where they move, then Attack, Heal or Wait. When everyone has acted, the enemy moves.\n\nPress R to see every tile the enemy can reach next turn. If Ione falls, the battle is lost."],
	["THE MEASURED THREAD", "Every strike — yours and theirs — takes the next bead from the thread at the top of the screen.\n\nA bead at or under the strike's Hit lands; at or under its Crit, it's critical. Low beads are fortunate. You see three beads exactly, three more as omens: fair, middling, ill."],
	["FORTUNE", "Misfortune fills the wheel: each miss, each critical you take, each new turn. Spend it:\n\nMeasure (M) — see every visible bead exactly.   Cut (C) — discard the front bead.   Turn (T) — flip it: a 94 becomes a 7.\n\nMisjudged a move? Unravel (U) takes back your last action, three times a battle."],
]

var page := 0
var _title: Label
var _body: Label
var _dots: Label


func _ready() -> void:
	theme = UiTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UiTheme.panel_box(Palette.MARBLE, Palette.GOLD, 3))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var over := UiTheme.label("CODEX", 16, "display", Palette.GOLD_DEEP, 700)
	over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(over)
	_title = UiTheme.label("", 30, "display", Palette.INK, 700)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	var m := Meander.new()
	m.custom_minimum_size = Vector2(0, 14)
	v.add_child(m)
	_body = UiTheme.label("", 24, "text", Palette.INK, 600)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(640, 230)
	v.add_child(_body)
	_dots = UiTheme.label("", 16, "text", Palette.INK_SOFT, 600)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_dots)
	_show()


func _show() -> void:
	_title.text = PAGES[page][0]
	_body.text = PAGES[page][1]
	var marks := ""
	for i in PAGES.size():
		marks += ("●" if i == page else "○") + " "
	_dots.text = "%s   ·   Z %s   ·   X close" % [marks.strip_edges(), "next" if page < PAGES.size() - 1 else "begin"]
	reset_size()
	position = (get_viewport_rect().size - size) * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		if page < PAGES.size() - 1:
			page += 1
			Sound.play("menu")
			_show()
		else:
			_close()
	elif event.is_action_pressed("cancel"):
		_close()
	elif event.is_action_pressed("cursor_left") and page > 0:
		page -= 1
		_show()
	elif event.is_action_pressed("cursor_right") and page < PAGES.size() - 1:
		page += 1
		_show()
	else:
		return
	get_viewport().set_input_as_handled()


func _close() -> void:
	Sound.play("confirm")
	closed.emit()
	queue_free()
