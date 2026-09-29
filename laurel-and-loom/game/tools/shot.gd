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
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	Sound.shutdown()
	UiTheme.release()
	await get_tree().process_frame
	get_tree().quit()


func _battle(chapter := "prologue") -> Node:
	var b: Node = load("res://src/battle/battle.tscn").instantiate()
	b.chapter_id = chapter
	b.tutorial_enabled = false
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
	foe.pos = ione.pos + Vector2i(-2, -1)
	b._sync_views()
	b._select(ione)
	b._move_cursor(ione.pos + Vector2i(-2, 0))
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


func measured() -> void:
	var b = await _battle()
	b.state.fortune = 5
	b._use_art("measure")
	var ione: Unit = b.state.lord()
	var foe: Unit = b.state.living(Unit.Team.ENEMY)[1]
	foe.pos = ione.pos + Vector2i(-1, -1)
	b._sync_views()
	b._select(ione)
	b._move_cursor(ione.pos + Vector2i(-1, 0))
	b._confirm_destination()
	await get_tree().create_timer(0.6).timeout
	b._on_menu("attack")
	await get_tree().create_timer(0.3).timeout
	b._use_art("turn")
	await get_tree().create_timer(1.2).timeout


func title() -> void:
	var m: Node = load("res://src/main.tscn").instantiate()
	add_child(m)
	await get_tree().create_timer(1.2).timeout


func enemy_phase() -> void:
	var b = await _battle()
	# Walk Cassian forward so the enemy has someone to strike.
	var cassian: Unit = b.state.living(Unit.Team.PLAYER)[0]
	b.state.move_unit(cassian, cassian.pos + Vector2i(-2, -3))
	b._sync_views()
	b._end_player_phase()
	await get_tree().create_timer(3.2).timeout


func story() -> void:
	var s: Control = load("res://src/ui/story_scene.gd").new()
	s.scene_id = "ch3_pre"
	add_child(s)
	await get_tree().process_frame
	while s._index < 4:
		s._advance()
	s._shown = 999.0
	s._text.visible_characters = -1
	await get_tree().create_timer(0.3).timeout


func codex() -> void:
	var b: Node = load("res://src/battle/battle.tscn").instantiate()
	b.chapter_id = "prologue"
	add_child(b)
	await get_tree().create_timer(0.8).timeout
	for c in b.hud.get_children():
		if c.has_method("_show"):
			c.page = 1
			c._show()
	await get_tree().create_timer(0.2).timeout


func levelup() -> void:
	var b = await _battle()
	var ione: Unit = b.state.lord()
	var lv := Progression.level_up(ione)
	b._sync_views()
	b.hud.show_level_up(ione, lv)
	await get_tree().create_timer(0.8).timeout


func temple() -> void:
	var b = await _battle("ch3")
	b._move_cursor(b.state.boss().pos)
	await get_tree().create_timer(0.6).timeout


func aqueduct() -> void:
	var b = await _battle("ch2")
	b.danger_on = true
	b._refresh()
	await get_tree().create_timer(0.3).timeout


func ending() -> void:
	var c := Campaign.start("classic")
	for id in ["ione", "cassian", "selene", "dama", "oren", "mirelle", "theron"]:
		var u := Unit.from_character(id)
		Progression.grant(u, 300)
		var d := u.to_dict()
		d["fallen"] = id == "oren"
		c.roster[id] = d
	c.turns = {"prologue": 4, "ch1": 9, "ch2": 7, "ch3": 11}
	c.chapter = 4
	var e: Control = load("res://src/ui/ending.gd").new()
	e.campaign = c
	add_child(e)
	await get_tree().create_timer(0.4).timeout
