extends TestCase


func test_attacks_a_reachable_foe() -> void:
	var st := BattleState.new(plaza(8, 3), 1)
	var leg := st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(0, 1))
	var ione := st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(4, 1))
	var plan := EnemyAI.decide(st, leg)
	eq(plan["action"], "attack")
	eq(int(plan["target"]), ione.uid)
	eq(BattleMap.distance(plan["move"], ione.pos), 1)
	var path: Array = plan["path"]
	eq(path[0], leg.pos)
	eq(path[path.size() - 1], plan["move"])


func test_prefers_the_kill() -> void:
	var st := BattleState.new(plaza(8, 5), 1)
	var leg := st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(3, 2))
	st.add_unit(Unit.from_character("cassian"), Unit.Team.PLAYER, Vector2i(3, 0))
	var weak := st.add_unit(Unit.from_character("dama"), Unit.Team.PLAYER, Vector2i(3, 4))
	weak.hp = 4
	var plan := EnemyAI.decide(st, leg)
	eq(int(plan["target"]), weak.uid, "goes for the wounded archer, not the armoured captain")


func test_prefers_cover() -> void:
	var st := state_on([
		".....",
		"..t..",
		".....",
	])
	var leg := st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(0, 1))
	st.add_unit(Unit.from_character("selene"), Unit.Team.PLAYER, Vector2i(2, 0))
	var plan := EnemyAI.decide(st, leg)
	eq(plan["action"], "attack")
	eq(plan["move"], Vector2i(2, 1), "attacks from the grove")


func test_hold_never_moves() -> void:
	var st := BattleState.new(plaza(8, 3), 1)
	var archer := st.add_unit(Unit.from_class("archer", 1), Unit.Team.ENEMY, Vector2i(0, 1))
	archer.ai = "hold"
	st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(4, 1))
	var plan := EnemyAI.decide(st, archer)
	eq(plan["move"], archer.pos)
	eq(plan["action"], "wait")


func test_guard_waits_when_nothing_is_in_reach() -> void:
	var st := BattleState.new(plaza(14, 3), 1)
	var leg := st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(0, 1))
	leg.ai = "guard"
	st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(12, 1))
	var plan := EnemyAI.decide(st, leg)
	eq(plan["move"], leg.pos)
	leg.ai = "charge"
	var charge := EnemyAI.decide(st, leg)
	eq(BattleMap.distance(charge["move"], leg.pos), 5, "charge walks its full Move")
	check(charge["move"].x > leg.pos.x, "towards the foe")


func test_charge_routes_around_walls() -> void:
	var st := state_on([
		"........",
		".######.",
		"........",
	])
	var leg := st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(3, 0))
	st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(3, 2))
	var plan := EnemyAI.decide(st, leg)
	var path: Array = plan["path"]
	for i in range(1, path.size()):
		check(st.map.move_cost(path[i], "foot") < Terrain.IMPASSABLE, "path avoids walls")


func test_healer_heals() -> void:
	var st := BattleState.new(plaza(6, 3), 1)
	var sel := st.add_unit(Unit.from_character("selene"), Unit.Team.PLAYER, Vector2i(0, 1))
	var ione := st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(3, 1))
	ione.hp = 6
	st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(5, 0))
	var plan := EnemyAI.decide(st, sel)
	eq(plan["action"], "heal")
	eq(int(plan["target"]), ione.uid)
