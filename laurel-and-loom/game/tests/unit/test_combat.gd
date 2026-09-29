extends TestCase


func _duel(rows: Array, a: Unit, a_at: Vector2i, d: Unit, d_at: Vector2i, seed_value: int = 1) -> BattleState:
	var st := state_on(rows, seed_value)
	st.add_unit(a, Unit.Team.PLAYER, a_at)
	st.add_unit(d, Unit.Team.ENEMY, d_at)
	return st


func test_numbers_on_open_ground() -> void:
	var ione := Unit.from_character("ione")
	var leg := Unit.from_class("legionary", 1)
	var st := _duel(["...."], ione, Vector2i(0, 0), leg, Vector2i(1, 0))
	var n := Combat.strike_numbers(st.map, ione, "gladius", leg, ione.pos, leg.pos, false)
	# Atk 6+5=11 vs Def 4 → 7. Hit 90+14+3=107 − (10+1) = 96. Crit 0+3−1 = 2.
	eq(int(n["dmg"]), 7)
	eq(int(n["hit"]), 96)
	eq(int(n["crit"]), 2)


func test_terrain_adds_avoid_and_def() -> void:
	var ione := Unit.from_character("ione")
	var leg := Unit.from_class("legionary", 1)
	var st := _duel([".t.."], ione, Vector2i(0, 0), leg, Vector2i(1, 0))
	var n := Combat.strike_numbers(st.map, ione, "gladius", leg, ione.pos, leg.pos, false)
	eq(int(n["dmg"]), 6, "grove +1 Def")
	eq(int(n["hit"]), 76, "grove +20 Avoid")


func test_tempo_lets_swords_double_at_three() -> void:
	var ione := Unit.from_character("ione")  # Spd 8
	var leg := Unit.from_class("legionary", 1)  # Spd 5
	check(Combat.doubles(ione, "gladius", leg), "sword doubles at +3")
	var archer := Unit.from_class("archer", 1)  # Spd 5
	var fast := Unit.from_class("archer", 1)
	fast.stats["spd"] = 8
	check(not Combat.doubles(fast, "arcus", archer), "bow needs +4")
	fast.stats["spd"] = 9
	check(Combat.doubles(fast, "arcus", archer), "bow doubles at +4")


func test_brace_spears_are_effective_against_cavalry() -> void:
	var cassian := Unit.from_character("cassian")
	var eques := Unit.from_class("eques", 1)
	var st := _duel(["...."], cassian, Vector2i(0, 0), eques, Vector2i(1, 0))
	var n := Combat.strike_numbers(st.map, cassian, "hasta", eques, cassian.pos, eques.pos, false)
	check(bool(n["effective"]))
	eq(int(n["atk"]), 8 + 6 * 2)


func test_resonance_ignores_terrain() -> void:
	var selene := Unit.from_character("selene")
	var leg := Unit.from_class("legionary", 1)
	var st := _duel([".t.."], selene, Vector2i(0, 0), leg, Vector2i(1, 0))
	var n := Combat.strike_numbers(st.map, selene, "ode", leg, selene.pos, leg.pos, false)
	var open := _duel(["...."], Unit.from_character("selene"), Vector2i(0, 0), Unit.from_class("legionary", 1), Vector2i(1, 0))
	var n2 := Combat.strike_numbers(open.map, selene, "ode", leg, selene.pos, leg.pos, false)
	eq(int(n["hit"]), int(n2["hit"]))
	eq(int(n["dmg"]), int(n2["dmg"]))
	check(bool(n["resonance"]), "flags that resonance mattered")


func test_steady_bows() -> void:
	var dama := Unit.from_character("dama")
	var leg := Unit.from_class("legionary", 1)
	var st := _duel(["...."], dama, Vector2i(0, 0), leg, Vector2i(2, 0))
	var still := Combat.strike_numbers(st.map, dama, "arcus", leg, dama.pos, leg.pos, false)
	var moved := Combat.strike_numbers(st.map, dama, "arcus", leg, dama.pos, leg.pos, true)
	check(bool(still["steady"]))
	eq(int(still["hit"]) - int(moved["hit"]), mini(15, 100 - int(moved["hit"])))


func test_counter_ranges() -> void:
	var dama := Unit.from_character("dama")
	eq(dama.counter_weapon(1), "", "a bow can't counter up close")
	eq(dama.counter_weapon(2), "arcus")
	var cassian := Unit.from_character("cassian")
	eq(cassian.counter_weapon(1), "hasta", "equipped weapon first")
	eq(cassian.counter_weapon(2), "pilum", "falls back to one that reaches")


func test_judge() -> void:
	eq(FateThread.judge(50, 50, 0), "hit")
	eq(FateThread.judge(51, 50, 0), "miss")
	eq(FateThread.judge(5, 50, 5), "crit")
	eq(FateThread.judge(6, 50, 5), "hit")
	eq(FateThread.judge(1, 0, 0), "miss", "0 hit never hits")
	eq(FateThread.judge(100, 100, 0), "hit", "100 hit always hits")


func test_strike_order() -> void:
	var ione := Unit.from_character("ione")
	var leg := Unit.from_class("legionary", 1)
	var st := _duel(["...."], ione, Vector2i(0, 0), leg, Vector2i(1, 0))
	var p := Combat.plan_here(st, ione, "gladius", leg)
	eq(Array(p["order"]), ["a", "d", "a"])
	var dama := Unit.from_character("dama")
	var st2 := _duel(["...."], dama, Vector2i(0, 0), Unit.from_class("legionary", 1), Vector2i(1, 0))
	var foe := st2.units[1]
	var p2 := Combat.plan_here(st2, foe, "gladius", dama)
	eq(Array(p2["order"]), ["a"], "archer can't counter at 1")


func test_resolve_draws_one_bead_per_strike() -> void:
	for seed_value in range(1, 40):
		var st := _duel(["...."], Unit.from_character("ione"), Vector2i(0, 0),
			Unit.from_class("legionary", 1), Vector2i(1, 0), seed_value)
		var r := st.attack(st.units[0], "gladius", st.units[1])
		eq(st.thread.drawn, (r["strikes"] as Array).size())


## The central promise of the design: what the forecast says is what happens.
func test_forecast_matches_resolution_across_seeds() -> void:
	var pairings := [
		["ione", "legionary", "gladius", 1],
		["cassian", "eques", "hasta", 1],
		["oren", "hoplite", "securis", 1],
		["dama", "archer", "arcus", 2],
		["selene", "legionary", "ode", 2],
		["oren", "legionary", "securis", 1],
	]
	var mismatches := 0
	var compared := 0
	for pair in pairings:
		for seed_value in range(1, 120):
			var a := Unit.from_character(pair[0])
			var d := Unit.from_class(pair[1], 1 + seed_value % 4)
			var st := _duel([".t.,.", "....."], a, Vector2i(0, 0), d, Vector2i(int(pair[3]), 0), seed_value)
			# Burn a few beads so combats start at different offsets.
			for i in seed_value % 5:
				st.thread.draw()
			st.thread.measured = seed_value % 2 == 0
			var fc := Combat.forecast(st, Combat.plan_here(st, a, str(pair[2]), d))
			var res := st.attack(a, str(pair[2]), d)
			var fs: Array = fc["strikes"]
			var rs: Array = res["strikes"]
			for i in mini(fs.size(), rs.size()):
				if fs[i]["outcome"] != "?":
					compared += 1
					if fs[i]["outcome"] != rs[i]["outcome"]:
						mismatches += 1
					if int(fs[i]["bead"]) >= 0 and int(fs[i]["bead"]) != int(rs[i]["bead"]):
						mismatches += 1
				# Whatever the forecast says is possible must include what happened.
				if not (fs[i]["possible"] as Array).has(rs[i]["outcome"]):
					mismatches += 1
			if fc["certain"]:
				compared += 1
				if fs.size() != rs.size() or int(fc["a_hp"]) != a.hp or int(fc["d_hp"]) != d.hp:
					mismatches += 1
	check(compared > 500, "compared %d predictions" % compared)
	eq(mismatches, 0, "forecast disagreed with the fight")


func test_shove_pushes_back() -> void:
	var oren := Unit.from_character("oren")
	var hop := Unit.from_class("hoplite", 1)
	var st := _duel(["....."], oren, Vector2i(1, 0), hop, Vector2i(2, 0))
	# Force a hit on the first bead.
	while st.thread.peek(0) > 60:
		st.thread.cut()
	var r := st.attack(oren, "securis", hop)
	if hop.is_alive():
		eq(hop.pos, Vector2i(3, 0), "shoved one tile away")
		eq(r["shove"]["to"], Vector2i(3, 0))


func test_shove_blocked_by_wall_and_units() -> void:
	var oren := Unit.from_character("oren")
	var hop := Unit.from_class("hoplite", 1)
	var st := _duel(["..#"], oren, Vector2i(0, 0), hop, Vector2i(1, 0))
	while st.thread.peek(0) > 60:
		st.thread.cut()
	st.attack(oren, "securis", hop)
	eq(hop.pos, Vector2i(1, 0), "a wall stops the shove")

	var st2 := _duel(["...."], Unit.from_character("oren"), Vector2i(0, 0), Unit.from_class("hoplite", 1), Vector2i(1, 0))
	st2.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(2, 0))
	while st2.thread.peek(0) > 60:
		st2.thread.cut()
	st2.attack(st2.units[0], "securis", st2.units[1])
	eq(st2.units[1].pos, Vector2i(1, 0), "a unit stops the shove")


func test_heal_amount_caps_at_missing() -> void:
	var selene := Unit.from_character("selene")
	var ione := Unit.from_character("ione")
	ione.hp = ione.max_hp() - 3
	eq(Combat.heal_amount(selene, "caduceus", ione), 3)
	ione.hp = 1
	eq(Combat.heal_amount(selene, "caduceus", ione), 16)


func test_possible_outcomes() -> void:
	eq(Array(FateThread.possible_outcomes(1, 33, 90, 0)), ["hit"], "a fair omen at 90 hit is a sure hit")
	eq(Array(FateThread.possible_outcomes(67, 100, 50, 5)), ["miss"], "an ill omen at 50 hit is a sure miss")
	eq(Array(FateThread.possible_outcomes(34, 66, 50, 0)), ["hit", "miss"])
	eq(Array(FateThread.possible_outcomes(1, 33, 90, 10)), ["crit", "hit"])
	eq(Array(FateThread.possible_outcomes(1, 100, 100, 0)), ["hit"], "unseen beads can't stop a 100")
	eq(Array(FateThread.possible_outcomes(1, 100, 0, 0)), ["miss"], "or save a 0")
	eq(Array(FateThread.possible_outcomes(12, 12, 50, 12)), ["crit"])
	eq(Array(FateThread.possible_outcomes(13, 13, 50, 12)), ["hit"])
