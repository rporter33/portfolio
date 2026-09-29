extends Node
## The main scene: owns whichever screen is showing (title, battle) and moves
## between them.

var _screen: Node


func _ready() -> void:
	goto_title()


func _swap(next: Node) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)


func goto_title() -> void:
	var t: Control = preload("res://src/ui/title.gd").new()
	_swap(t)
	Sound.music("title")
	t.chosen.connect(_on_title_choice)
	t.open_menu([
		{"id": "begin", "label": "Begin"},
		{"id": "quit", "label": "Quit"},
	])


func _on_title_choice(id: String) -> void:
	match id:
		"begin":
			goto_battle("prologue")
		"quit":
			get_tree().quit()


func goto_battle(chapter_id: String, roster: Dictionary = {}) -> void:
	var b: Node = preload("res://src/battle/battle.tscn").instantiate()
	b.chapter_id = chapter_id
	b.roster = roster
	b.exit_requested.connect(func(action: String) -> void: _on_battle_exit(chapter_id, roster, action))
	_swap(b)


func _on_battle_exit(chapter_id: String, roster: Dictionary, action: String) -> void:
	match action:
		"retry":
			goto_battle(chapter_id, roster)
		_:
			goto_title()
