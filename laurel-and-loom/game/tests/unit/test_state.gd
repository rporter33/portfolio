extends TestCase


func _small() -> BattleState:
	var st := state_on([
		".....",
		"..A..",
		".....",
	], 5)
	st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(0, 0))
	st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(4, 2))
	st.begin_phase(Unit.Team.PLAYER)
	return st


func test_begin_phase_resets_flags() -> void:
	var st := _small()
	var ione := st.units[0]
	ione.moved = true
	ione.acted = true
	st.begin_phase(Unit.Team.PLAYER)
	check(not ione.moved and not ione.acted)


func test_altar_heals_its_occupant() -> void:
	var st := _small()
	var ione := st.units[0]
	ione.pos = Vector2i(2, 1)
	ione.hp = 5
	var healed := st.begin_phase(Unit.Team.PLAYER)
	eq(ione.hp, 5 + 20 * 20 / 100)
	eq(healed.size(), 1)
	var leg := st.units[1]
	leg.pos = Vector2i(2, 1)
	ione.pos = Vector2i(0, 0)
	leg.hp = 3
	st.begin_phase(Unit.Team.PLAYER)
	eq(leg.hp, 3, "only the phase's own team is healed")


func test_phase_cycle_and_fortune() -> void:
	var st := _small()
	eq(st.turn, 1)
	eq(st.fortune, BattleState.FORTUNE_START)
	st.advance_phase()
	eq(st.phase, Unit.Team.ENEMY)
	eq(st.fortune, BattleState.FORTUNE_START, "no gain on the enemy phase")
	st.advance_phase()
	eq(st.phase, Unit.Team.PLAYER)
	eq(st.turn, 2)
	eq(st.fortune, BattleState.FORTUNE_START + 1, "+1 at the start of player turn 2")
	for i in 10:
		st.gain_fortune(1)
	eq(st.fortune, BattleState.FORTUNE_MAX, "capped")


func test_misses_feed_fortune() -> void:
	var st := _small()
	var ione := st.units[0]
	var leg := st.units[1]
	leg.pos = Vector2i(1, 0)
	# Make the first bead a miss for Ione (hit 96).
	while st.thread.peek(0) <= 96:
		st.thread.cut()
	var before := st.fortune
	var r := st.attack(ione, "gladius", leg)
	eq(r["strikes"][0]["outcome"], "miss")
	check(st.fortune >= before + 1, "a miss turns the wheel")
	eq(int(r["fortune_gained"]), st.fortune - before)


func test_fate_arts() -> void:
	var st := _small()
	st.fortune = 6
	var b1 := st.thread.peek(1)
	check(st.use_art("cut"))
	eq(st.fortune, 4)
	eq(st.thread.peek(0), b1)
	check(st.use_art("turn"))
	eq(st.fortune, 1)
	eq(st.thread.peek(0), 101 - b1)
	check(not st.use_art("turn"), "can't afford")
	check(st.use_art("measure"))
	check(st.thread.measured)
	st.fortune = 6
	check(not st.use_art("measure"), "measure once per phase")
	st.advance_phase()
	check(not st.thread.measured, "measure lapses when the phase ends")
	check(not st.can_use_art("cut"), "no arts in the enemy phase")


func test_arts_need_the_augur() -> void:
	var st := _small()
	st.fortune = 6
	st.lord().hp = 0
	check(not st.can_use_art("cut"))


func test_lord_death_is_defeat() -> void:
	var st := _small()
	st.lord().hp = 0
	eq(st.check_outcome(), BattleState.Outcome.DEFEAT)


func test_rout_is_victory() -> void:
	var st := _small()
	st.units[1].hp = 0
	eq(st.check_outcome(), BattleState.Outcome.VICTORY)


func test_seize() -> void:
	var st := state_on(["..G.."], 1)
	var ione := st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(0, 0))
	st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(4, 0))
	st.objective = {"type": "seize", "tile": Vector2i(2, 0)}
	check(not st.can_seize(ione))
	st.move_unit(ione, Vector2i(2, 0))
	check(st.can_seize(ione))
	st.seize(ione)
	eq(st.outcome, BattleState.Outcome.VICTORY)


func test_survive() -> void:
	var st := _small()
	st.objective = {"type": "survive", "turns": 2}
	st.advance_phase()  # T1 enemy
	st.advance_phase()  # T2 player
	eq(st.outcome, BattleState.Outcome.ONGOING)
	st.advance_phase()  # T2 enemy
	st.advance_phase()  # end of T2 → victory
	eq(st.outcome, BattleState.Outcome.VICTORY)


func test_boss_objective() -> void:
	var st := _small()
	var bassa := st.add_unit(Unit.from_character("bassa"), Unit.Team.ENEMY, Vector2i(4, 0))
	st.objective = {"type": "boss"}
	eq(st.boss(), bassa)
	bassa.hp = 0
	eq(st.check_outcome(), BattleState.Outcome.VICTORY, "the other soldiers needn't fall")


func test_clone_is_deep() -> void:
	var st := _small()
	var c := st.clone()
	c.units[0].hp = 1
	c.units[0].pos = Vector2i(3, 0)
	c.thread.draw()
	c.fortune = 0
	check(st.units[0].hp != 1)
	eq(st.units[0].pos, Vector2i(0, 0))
	eq(st.thread.drawn, 0)
	check(st.fortune != 0)
	eq(c.thread.peek(0), st.thread.peek(1), "the clone's thread is the same thread, one bead on")


func test_move_sets_moved_only_when_tile_changes() -> void:
	var st := _small()
	var ione := st.units[0]
	st.move_unit(ione, ione.pos)
	check(not ione.moved)
	st.move_unit(ione, Vector2i(1, 0))
	check(ione.moved)
