extends Node
## Screenshot driver for checking the look of the game without a person at
## the keyboard. Runs a scene, puts it into a named situation, saves a PNG.
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tools/shot.tscn -- <scenario> <out.png>
##
## Scenarios: board, select, forecast, enemy, title, story, levelup.


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := args[0] if args.size() > 0 else "board"
	var out := args[1] if args.size() > 1 else "user://shot.png"
	await call(scenario)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("saved %s (%s)" % [out, img.get_size()])
	get_tree().quit()


func _battle(chapter := "prologue") -> Node:
	var b: Node = load("res://src/battle/battle.tscn").instantiate()
	b.chapter_id = chapter
	add_child(b)
	await get_tree().create_timer(2.2).timeout
	return b


func board() -> void:
	await _battle()


func select() -> void:
	var b = await _battle()
	var ione: Unit = b.state.lord()
	b._move_cursor(ione.pos)
	b._select(ione)
	b._move_cursor(ione.pos + Vector2i(-2, -3))
	await get_tree().create_timer(0.4).timeout


func forecast() -> void:
	var b = await _battle()
	var ione: Unit = b.state.lord()
	var foe: Unit = b.state.living(Unit.Team.ENEMY)[1]
	foe.pos = ione.pos + Vector2i(0, -2)
	b._sync_views()
	b._select(ione)
	b._move_cursor(ione.pos + Vector2i(0, -1))
	b._confirm_destination()
	await get_tree().create_timer(0.6).timeout
	b._on_menu("attack")
	await get_tree().create_timer(0.4).timeout


func enemy() -> void:
	var b = await _battle()
	b.danger_on = true
	b._refresh()
	await get_tree().create_timer(0.3).timeout


func menu() -> void:
	var b = await _battle()
	var ione: Unit = b.state.lord()
	b._select(ione)
	b._move_cursor(ione.pos + Vector2i(-2, -1))
	b._confirm_destination()
	await get_tree().create_timer(0.6).timeout
