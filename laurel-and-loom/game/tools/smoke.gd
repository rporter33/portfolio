extends Node
## Plays the game through its real scenes — the same controller calls that
## keyboard and mouse input make — with the AI choosing moves for the
## player's side. Catches controller, flow and animation bugs that the pure
## rules tests can't see.
##
##   godot --headless --path . res://tools/smoke.tscn               # every chapter, then the campaign
##   godot --headless --path . res://tools/smoke.tscn -- ch2         # one chapter
##   godot --headless --path . res://tools/smoke.tscn -- campaign    # title to ending
## Exits 0 when everything ends properly, 1 otherwise.

const TIMEOUT_S := 300.0
const SMOKE_SAVE := "user://smoke_test.save"

var _unravelled := {}
var _arts_used := 0
var _last_screen := ""


func _ready() -> void:
	Game.anim_speed = 25.0
	Campaign.save_path = SMOKE_SAVE
	Campaign.delete_save()
	var args := OS.get_cmdline_user_args()
	var ok := true
	var runs: Array = args if args.size() > 0 else Chapters.ORDER + ["campaign"]
	for run in runs:
		var result: String
		if run == "campaign":
			result = await _campaign()
		else:
			var b: Node = load("res://src/battle/battle.tscn").instantiate()
			b.chapter_id = str(run)
			b.tutorial_enabled = false
			add_child(b)
			result = await _drive_battle(b)
			b.queue_free()
		print("smoke %-10s %s" % [run, result])
		ok = ok and (result.begins_with("ended") or result.begins_with("finished"))
	Campaign.delete_save()
	await get_tree().process_frame
	Sound.shutdown()
	UiTheme.release()
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)


func _wait_until(b: Node, states: Array, limit: float = 30.0) -> bool:
	var t := 0.0
	while not (b.s in states):
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > limit:
			return false
	return true


## Play one battle to its end screen. Leaves the battle in place.
## `attempt` rotates which ready unit moves first, so a retry plays out
## differently (the same choices on the same seed give the same battle).
func _drive_battle(b: Node, attempt: int = 0) -> String:
	var S = b.S
	_unravelled.clear()
	_arts_used = 0
	var started := Time.get_ticks_msec()
	var actions := 0
	while true:
		if (Time.get_ticks_msec() - started) / 1000.0 > TIMEOUT_S:
			return "TIMEOUT after %d actions" % actions
		# The Codex may be open before the prologue: close it like a player would.
		for c in b.hud.get_children():
			if c.has_method("_close"):
				c._close()
		if not await _wait_until(b, [S.IDLE, S.ENDED], 60.0):
			return "STUCK in state %d" % b.s
		if b.s == S.ENDED:
			var st: BattleState = b.state
			return "ended: %s on turn %d after %d actions (%d unravels, %d cut/turn)" % [
				"victory" if st.outcome == BattleState.Outcome.VICTORY else "defeat", st.turn, actions,
				BattleState.UNRAVELS - st.unravels_left, _arts_used]
		var ready: Array[Unit] = b.state.ready_units(Unit.Team.PLAYER)
		if ready.is_empty():
			b._end_player_phase()
			continue
		# Exercise the Thread: measure now and then, and unravel a few actions
		# (the AI then makes the same choice again, so the battle still ends).
		if actions % 4 == 1 and b.state.can_use_art("measure"):
			b._use_art("measure")
			if not b.state.thread.measured:
				return "measure did nothing"
		if actions % 5 == 4 and b.state.unravels_left > 0 and not b.history.is_empty() and not _unravelled.has(actions):
			_unravelled[actions] = true
			var before: int = b.state.unravels_left
			b._on_unravel_key()
			if b.state.unravels_left != before - 1:
				return "unravel did not spend a charge"
			if b.views.size() != b.state.living().size():
				return "views out of step after unravel"
			continue
		var u: Unit = ready[(attempt * 2) % ready.size()]
		var plan := EnemyAI.decide(b.state, u)
		# A lord standing on the gate should take it.
		if b.state.objective.get("type", "") == "seize" and u.is_lord:
			var reach := Pathfinder.reachable(b.state, u)
			var gate: Vector2i = b.state.objective["tile"]
			if reach["cost"].has(gate) and b.state.unit_at(gate) == null:
				plan = {"move": gate, "action": "wait"}
		# Drive the controller the way input would.
		b._move_cursor(u.pos)
		b._confirm()
		if b.s != S.SELECTED:
			return "could not select %s" % u.name
		b._move_cursor(plan["move"])
		b._confirm()
		if not await _wait_until(b, [S.ACTION_MENU, S.TARGETING]):
			return "no action menu for %s" % u.name
		actions += 1
		match plan["action"]:
			"attack":
				if b.s == S.ACTION_MENU:
					b._on_menu("attack")
					if b.s == S.WEAPON_MENU:
						b._on_menu(plan["weapon"])
				var target: Unit = b.state.unit_by_uid(plan["target"])
				var idx: int = b.targets.find(target)
				if idx < 0:
					return "target %s not offered" % target.name
				b.target_index = idx
				b._show_target()
				# If the opening strike would miss, spend Fortune to fix it.
				var fc := Combat.forecast(b.state, Combat.plan_here(b.state, u, b.weapon, target))
				if fc["strikes"][0]["outcome"] == "miss":
					var art := "turn" if b.state.can_use_art("turn") else "cut"
					if b.state.can_use_art(art):
						b._use_art(art)
						_arts_used += 1
				b._confirm()
			"heal":
				b._on_menu("heal")
				var ally: Unit = b.state.unit_by_uid(plan["target"])
				b.target_index = maxi(0, b.targets.find(ally))
				b._confirm()
			_:
				if b.state.can_seize(u):
					b._on_menu("seize")
				else:
					b._on_menu("wait")
	return "unreachable"


## Title → new casual campaign → every story and battle → the ending → title.
## Midway, return to the title and Continue from the save.
func _campaign() -> String:
	var m: Node = load("res://src/main.tscn").instantiate()
	add_child(m)
	await get_tree().process_frame
	m._on_title_choice("new")
	m._on_title_choice("casual")
	m.campaign.seed_value = 1
	var battles := 0
	var stories := 0
	var attempts := {}
	var continued := false
	var started := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - started) / 1000.0 < TIMEOUT_S * 4:
		await get_tree().process_frame
		var screen: Node = m._screen
		if screen == null or screen.is_queued_for_deletion():
			continue
		var script_path: String = screen.get_script().resource_path
		if script_path != _last_screen:
			_last_screen = script_path
			print("  campaign screen: %s (chapter %d)" % [script_path.get_file(), m.campaign.chapter if m.campaign else -1])
		if script_path.ends_with("story_scene.gd"):
			stories += 1
			# After the first chapter's story ends, prove Continue works.
			if not continued and m.campaign.chapter == 1:
				continued = true
				if not Campaign.has_save():
					m.queue_free()
					return "no save after the prologue"
				m.goto_title()
				await get_tree().process_frame
				m._on_title_choice("continue")
				continue
			while screen._index < screen._lines.size():
				screen._advance()
			await get_tree().process_frame
		elif script_path.ends_with("battle.gd"):
			battles += 1
			var ch: String = screen.chapter_id
			attempts[ch] = int(attempts.get(ch, -1)) + 1
			if attempts[ch] >= 8:
				m.queue_free()
				return "could not win %s in 8 attempts" % ch
			var result := await _drive_battle(screen, attempts[ch])
			if not result.begins_with("ended"):
				m.queue_free()
				return "battle %s: %s" % [screen.chapter_id, result]
			var won: bool = screen.state.outcome == BattleState.Outcome.VICTORY
			print("  campaign %-9s %s" % [screen.chapter_id, result])
			screen._on_end_menu("continue" if won else "retry")
		elif script_path.ends_with("ending.gd"):
			var summary := "finished: %d battles, %d stories, level %d Ione, save %s" % [
				battles, stories, int(m.campaign.roster["ione"]["level"]),
				"kept" if Campaign.has_save() else "missing"]
			screen.done.emit()
			await get_tree().process_frame
			m.queue_free()
			return summary
	m.queue_free()
	return "TIMEOUT in the campaign"
