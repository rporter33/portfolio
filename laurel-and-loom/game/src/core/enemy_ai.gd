class_name EnemyAI
extends RefCounted
## Decides one unit's turn. Team-agnostic (it targets the unit's foes), so the
## tests can also let it play the player's side.
##
## Dispositions (docs/DESIGN.md §11):
##   charge  attack if possible, otherwise advance on the nearest foe
##   guard   attack anything reachable this turn, otherwise hold
##   hold    never move; attack whatever is already in range
##
## The AI scores by expected value. It does not read the thread.


## Returns {"move": Vector2i, "path": Array[Vector2i], "action": "attack" |
## "heal" | "wait", "target": uid, "weapon": String}.
static func decide(state: BattleState, u: Unit) -> Dictionary:
	var reach := Pathfinder.reachable(state, u)
	var stands: Array[Vector2i] = [u.pos]
	if u.ai != "hold":
		stands = Pathfinder.stand_tiles(state, u, reach)

	var heal := _best_heal(state, u, stands, reach)
	if not heal.is_empty():
		return _with_path(heal, reach)

	var atk := _best_attack(state, u, stands, reach)
	if not atk.is_empty():
		return _with_path(atk, reach)

	if u.ai == "charge":
		var dest := _advance_tile(state, u)
		if dest != u.pos:
			return _with_path({"move": dest, "action": "wait"}, reach)
	return {"move": u.pos, "path": [u.pos], "action": "wait"}


static func _with_path(plan: Dictionary, reach: Dictionary) -> Dictionary:
	plan["path"] = Pathfinder.path_to(reach, plan["move"])
	return plan


static func _best_attack(state: BattleState, u: Unit, stands: Array[Vector2i], reach: Dictionary) -> Dictionary:
	var best := {}
	var best_score := -INF
	for tile in stands:
		for w in u.attack_weapons():
			for foe in state.foes_of(u):
				if not WeaponDB.reaches(w, BattleMap.distance(tile, foe.pos)):
					continue
				var p := Combat.plan(state, u, w, foe, tile, tile != u.pos or u.moved)
				if int(p["a_num"]["dmg"]) <= 0:
					continue
				var score := score_plan(state, p, tile)
				score -= float(reach["cost"].get(tile, 0)) * 0.01  # prefer shorter walks on ties
				if score > best_score:
					best_score = score
					best = {"move": tile, "action": "attack", "target": foe.uid, "weapon": w}
	return best


## Expected-value score for a planned fight from `tile`.
static func score_plan(state: BattleState, p: Dictionary, tile: Vector2i) -> float:
	var foe: Unit = p["d"]
	var an: Dictionary = p["a_num"]
	var dn: Dictionary = p["d_num"]
	var swings := 2 if p["a_doubles"] else 1
	var h := float(an["hit"]) / 100.0
	var c := float(an["crit"]) / 100.0
	var per_swing := float(an["dmg"]) * h * (1.0 + c * (Combat.CRIT_MULT - 1))
	var expected := minf(per_swing * swings, float(foe.hp))
	var kill := 0.0
	if int(an["dmg"]) >= foe.hp:
		kill = 1.0 - pow(1.0 - h, swings)
	elif int(an["dmg"]) * swings >= foe.hp:
		kill = pow(h, swings)
	elif int(an["dmg"]) * Combat.CRIT_MULT >= foe.hp:
		kill = c * swings
	var score := expected + kill * 40.0
	if foe.is_lord:
		score += 15.0
	score += (1.0 - float(foe.hp) / float(foe.max_hp())) * 10.0
	if not dn.is_empty():
		var counters := 2 if p["d_doubles"] else 1
		score -= float(dn["dmg"]) * float(dn["hit"]) / 100.0 * counters * 0.6
	var ch := state.map.char_at(tile)
	score += float(Terrain.avoid(ch)) / 10.0 + float(Terrain.defense(ch))
	return score


static func _best_heal(state: BattleState, u: Unit, stands: Array[Vector2i], reach: Dictionary) -> Dictionary:
	if u.staves().is_empty():
		return {}
	var best := {}
	var best_score := 0.0
	for tile in stands:
		for staff in u.staves():
			for ally in state.allies_of(u):
				if not WeaponDB.reaches(staff, BattleMap.distance(tile, ally.pos)):
					continue
				var amount := Combat.heal_amount(u, staff, ally)
				var urgent := ally.hp * 2 < ally.max_hp()
				if amount < 5 and not urgent:
					continue
				var score := float(amount) + (10.0 if urgent else 0.0) + (5.0 if ally.is_lord else 0.0)
				score -= float(reach["cost"].get(tile, 0)) * 0.01
				if score > best_score:
					best_score = score
					best = {"move": tile, "action": "heal", "target": ally.uid, "weapon": staff}
	return best


## Where a charging unit should walk: as far as it can along the cheapest path
## to any tile from which it could strike a foe.
static func _advance_tile(state: BattleState, u: Unit) -> Vector2i:
	var far := Pathfinder.explore(state, u, 999)
	var goals := {}
	for foe in state.foes_of(u):
		for w in u.attack_weapons():
			for t in state.map.tiles_in_range(foe.pos, WeaponDB.min_range(w), WeaponDB.max_range(w)):
				goals[t] = true
	var goal := u.pos
	var goal_cost := 1 << 30
	for t in far["cost"]:
		if not goals.has(t):
			continue
		var occupant := state.unit_at(t)
		if occupant != null and occupant != u:
			continue
		if int(far["cost"][t]) < goal_cost:
			goal_cost = int(far["cost"][t])
			goal = t
	if goal == u.pos:
		return u.pos
	var path := Pathfinder.path_to(far, goal)
	var dest := u.pos
	for t in path:
		if int(far["cost"][t]) > u.move_range():
			break
		var occupant := state.unit_at(t)
		if occupant == null or occupant == u:
			dest = t
	return dest
