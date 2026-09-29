extends TestCase


func _unit(cls: String, lvl: int = 1) -> Unit:
	return Unit.from_class(cls, lvl)


func test_map_basics() -> void:
	var m := BattleMap.new(PackedStringArray(["..t", "#~."]))
	eq(m.width, 3)
	eq(m.height, 2)
	eq(m.char_at(Vector2i(2, 0)), "t")
	eq(m.char_at(Vector2i(-1, 0)), "#", "out of bounds reads as wall")
	eq(m.neighbors(Vector2i(0, 0)).size(), 2)
	eq(BattleMap.distance(Vector2i(0, 0), Vector2i(3, -2)), 5)


func test_tiles_in_range() -> void:
	var m := plaza(9, 9)
	eq(m.tiles_in_range(Vector2i(4, 4), 1, 1).size(), 4)
	eq(m.tiles_in_range(Vector2i(4, 4), 2, 2).size(), 8)
	eq(m.tiles_in_range(Vector2i(4, 4), 1, 2).size(), 12)
	eq(m.tiles_in_range(Vector2i(0, 0), 1, 1).size(), 2, "clipped at the edge")


func test_open_field_reach_is_a_diamond() -> void:
	var st := BattleState.new(plaza(15, 15), 1)
	var u := st.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(7, 7))
	var reach := Pathfinder.reachable(st, u)
	# Tiles within Manhattan distance 5: 2*5*6 + 1 = 61.
	eq(reach["cost"].size(), 61)
	eq(int(reach["cost"][Vector2i(7, 2)]), 5)


func test_terrain_costs_by_move_type() -> void:
	var st := state_on([
		".tttt",
		".....",
	])
	var foot := st.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(0, 0))
	var reach := Pathfinder.explore(st, foot, 4)
	eq(int(reach["cost"][Vector2i(1, 0)]), 2, "grove costs foot 2")
	eq(int(reach["cost"][Vector2i(2, 0)]), 4)
	var armor := BattleState.new(st.map, 1)
	var h := armor.add_unit(_unit("hoplite"), Unit.Team.ENEMY, Vector2i(0, 0))
	var r2 := Pathfinder.explore(armor, h, 4)
	eq(int(r2["cost"][Vector2i(1, 0)]), 3, "armor pays 3 for a grove")


func test_cavalry_cannot_pass_columns() -> void:
	var st := state_on([
		"..|..",
		"##|##",
	])
	var cav := st.add_unit(_unit("eques"), Unit.Team.ENEMY, Vector2i(0, 0))
	var reach := Pathfinder.reachable(st, cav)
	check(not reach["cost"].has(Vector2i(2, 0)), "column blocks cavalry")
	check(not reach["cost"].has(Vector2i(3, 0)), "and everything past it")
	var foot := BattleState.new(st.map, 1)
	var f := foot.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(0, 0))
	check(Pathfinder.reachable(foot, f)["cost"].has(Vector2i(4, 0)), "foot passes the column")


func test_walls_and_water_block() -> void:
	var st := state_on([
		".#.",
		".~.",
		"...",
	])
	var u := st.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(0, 0))
	var reach := Pathfinder.reachable(st, u)
	check(not reach["cost"].has(Vector2i(1, 0)))
	check(not reach["cost"].has(Vector2i(1, 1)))
	check(not reach["cost"].has(Vector2i(2, 0)), "(2,0) is 6 steps round — beyond Move 5")


func test_pass_allies_not_foes() -> void:
	var st := state_on([
		".....",
		"#####",
	])
	var u := st.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(0, 0))
	st.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(1, 0))
	var reach := Pathfinder.reachable(st, u)
	check(reach["cost"].has(Vector2i(4, 0)), "walks through an ally")
	var stands := Pathfinder.stand_tiles(st, u, reach)
	check(not stands.has(Vector2i(1, 0)), "can't stop on the ally")
	check(stands.has(Vector2i(0, 0)), "can stay put")

	var st2 := state_on([".....", "#####"])
	var v := st2.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(0, 0))
	st2.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(2, 0))
	var r2 := Pathfinder.reachable(st2, v)
	check(r2["cost"].has(Vector2i(1, 0)))
	check(not r2["cost"].has(Vector2i(3, 0)), "foes block the corridor")


func test_path_is_contiguous() -> void:
	var st := state_on([
		"..t..",
		".#...",
		".....",
	])
	var u := st.add_unit(_unit("legionary"), Unit.Team.ENEMY, Vector2i(0, 0))
	var reach := Pathfinder.reachable(st, u)
	# (3,1) costs exactly 5 — through the grove, since the way round is 6.
	var path := Pathfinder.path_to(reach, Vector2i(3, 1))
	check(path.size() > 1, "reachable")
	if path.size() < 2:
		return
	eq(path[0], Vector2i(0, 0))
	eq(path[path.size() - 1], Vector2i(3, 1))
	check(path.has(Vector2i(2, 0)), "through the grove")
	for i in range(1, path.size()):
		eq(BattleMap.distance(path[i - 1], path[i]), 1, "step %d" % i)
	var spent := 0
	for i in range(1, path.size()):
		spent += st.map.move_cost(path[i], "foot")
	eq(spent, int(reach["cost"][Vector2i(3, 1)]), "path cost matches Dijkstra cost")
	eq(spent, 5)


func test_threat_tiles() -> void:
	var st := BattleState.new(plaza(9, 9), 1)
	var archer := st.add_unit(_unit("archer"), Unit.Team.ENEMY, Vector2i(4, 4))
	var threat := Pathfinder.threat_tiles(st, archer, [archer.pos] as Array[Vector2i])
	eq(threat.size(), 8, "a bow threatens exactly the range-2 ring")
	check(not threat.has(Vector2i(4, 5)), "not adjacent tiles")
