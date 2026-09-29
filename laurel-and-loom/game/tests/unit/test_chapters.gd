extends TestCase
## Every chapter's data is well-formed, and every chapter, played AI against
## AI on many seeds, ends without breaking an invariant.


func test_chapter_data_is_well_formed() -> void:
	for id in Chapters.ORDER:
		var ch := Chapters.data(id)
		var terrain: Array = ch["terrain"]
		var layer: Array = ch["units"]
		eq(layer.size(), terrain.size(), "%s: layers have the same height" % id)
		for y in terrain.size():
			eq(str(layer[y]).length(), str(terrain[0]).length(), "%s row %d width" % [id, y])
			eq(str(terrain[y]).length(), str(terrain[0]).length(), "%s terrain row %d width" % [id, y])
			for x in str(terrain[y]).length():
				check(Terrain.is_known(str(terrain[y])[x]), "%s: unknown terrain at %d,%d" % [id, x, y])
		var st := BattleSetup.create(id)
		check(st.lord() != null, "%s has a lord" % id)
		check(not st.living(Unit.Team.ENEMY).is_empty(), "%s has enemies" % id)
		for u in st.units:
			check(st.map.move_cost(u.pos, u.move_type()) < Terrain.IMPASSABLE,
				"%s: %s starts on passable ground" % [id, u.name])
			check(not u.attack_weapons().is_empty() or not u.staves().is_empty(), "%s: %s is armed" % [id, u.name])
		if ch["objective"]["type"] == "seize":
			check(st.objective.has("tile"), "%s: seize chapter has a gate" % id)
		if ch["objective"]["type"] == "boss":
			check(st.boss() != null, "%s: boss chapter has a boss" % id)


func _invariants(st: BattleState, label: String) -> void:
	var seen := {}
	for u in st.living():
		check(st.map.in_bounds(u.pos), "%s: %s in bounds" % [label, u.name])
		check(st.map.move_cost(u.pos, u.move_type()) < Terrain.IMPASSABLE, "%s: %s on passable tile" % [label, u.name])
		check(not seen.has(u.pos), "%s: two units on %s" % [label, u.pos])
		seen[u.pos] = true
		check(u.hp > 0 and u.hp <= u.max_hp(), "%s: %s hp in range" % [label, u.name])


func test_ai_battles_terminate_cleanly() -> void:
	for id in Chapters.ORDER:
		var outcomes := {0: 0, 1: 0, 2: 0}
		for seed_value in range(1, 26):
			var st := BattleSetup.create(id, {}, seed_value)
			var turns := 0
			while st.outcome == BattleState.Outcome.ONGOING and st.turn <= 30:
				AutoBattle.play_phase(st)
				st.check_outcome()
				_invariants(st, "%s seed %d turn %d" % [id, seed_value, st.turn])
				st.advance_phase()
				turns += 1
			outcomes[st.outcome] += 1
		check(outcomes[BattleState.Outcome.ONGOING] == 0 or Chapters.data(id)["objective"]["type"] == "seize",
			"%s: some AI battles never ended (%s)" % [id, outcomes])
		print("    %s AI-vs-AI over 25 seeds: %d won, %d lost, %d unfinished" % [
			id, outcomes[BattleState.Outcome.VICTORY], outcomes[BattleState.Outcome.DEFEAT],
			outcomes[BattleState.Outcome.ONGOING]])


func test_same_seed_same_battle() -> void:
	for id in Chapters.ORDER:
		var a := BattleSetup.create(id, {}, 77)
		var b := BattleSetup.create(id, {}, 77)
		AutoBattle.play(a, 12)
		AutoBattle.play(b, 12)
		eq(a.outcome, b.outcome, id)
		eq(a.turn, b.turn, id)
		for i in a.units.size():
			eq(a.units[i].hp, b.units[i].hp, "%s: %s" % [id, a.units[i].name])
			eq(a.units[i].pos, b.units[i].pos, "%s: %s" % [id, a.units[i].name])
