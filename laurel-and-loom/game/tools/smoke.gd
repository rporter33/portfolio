extends Node
## Plays whole battles through the real battle scene — the same controller
## calls that keyboard and mouse input make — with the AI choosing moves for
## the player's side. Catches controller and animation bugs that the pure
## rules tests can't see.
##
##   godot --headless --path . res://tools/smoke.tscn -- [chapter] [seed]
## Exits 0 when every battle ends in victory or defeat, 1 otherwise.

const TIMEOUT_S := 240.0

var _errors := 0


func _ready() -> void:
	Game.anim_speed = 25.0
	var args := OS.get_cmdline_user_args()
	var chapters: Array = [args[0]] if args.size() > 0 else Chapters.ORDER
	var ok := true
	for ch in chapters:
		var result: String = await _play(str(ch))
		print("smoke %-10s %s" % [ch, result])
		ok = ok and result.begins_with("ended")
	get_tree().quit(0 if ok else 1)


func _wait_until(b: Node, states: Array, limit: float = 30.0) -> bool:
	var t := 0.0
	while not (b.s in states):
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > limit:
			return false
	return true


func _play(chapter: String) -> String:
	var b: Node = load("res://src/battle/battle.tscn").instantiate()
	b.chapter_id = chapter
	add_child(b)
	var S = b.S
	var started := Time.get_ticks_msec()
	var actions := 0
	while true:
		if (Time.get_ticks_msec() - started) / 1000.0 > TIMEOUT_S:
			b.queue_free()
			return "TIMEOUT after %d actions" % actions
		if not await _wait_until(b, [S.IDLE, S.ENDED], 60.0):
			b.queue_free()
			return "STUCK in state %d" % b.s
		if b.s == S.ENDED:
			var st: BattleState = b.state
			var res := "ended: %s on turn %d after %d actions" % [
				"victory" if st.outcome == BattleState.Outcome.VICTORY else "defeat", st.turn, actions]
			b.queue_free()
			await get_tree().process_frame
			return res
		var ready: Array[Unit] = b.state.ready_units(Unit.Team.PLAYER)
		if ready.is_empty():
			b._end_player_phase()
			continue
		var u: Unit = ready[0]
		var plan := EnemyAI.decide(b.state, u)
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
