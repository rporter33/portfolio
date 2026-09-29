class_name Pathfinder
extends RefCounted
## Movement: Dijkstra over terrain costs. Units pass through allies but not
## foes, and can't end a move on an occupied tile.


## Explore from `u` up to `budget` movement points.
## Returns {"cost": {Vector2i: int}, "prev": {Vector2i: Vector2i}}.
static func explore(state: BattleState, u: Unit, budget: int) -> Dictionary:
	var cost := {u.pos: 0}
	var prev := {}
	var open: Array[Vector2i] = [u.pos]
	var mt := u.move_type()
	while not open.is_empty():
		var best := 0
		for i in range(1, open.size()):
			if cost[open[i]] < cost[open[best]]:
				best = i
		var cur: Vector2i = open[best]
		open.remove_at(best)
		for n in state.map.neighbors(cur):
			var step := state.map.move_cost(n, mt)
			if step >= Terrain.IMPASSABLE:
				continue
			var occupant := state.unit_at(n)
			if occupant != null and occupant.team != u.team:
				continue
			var c: int = cost[cur] + step
			if c > budget:
				continue
			if not cost.has(n) or c < cost[n]:
				cost[n] = c
				prev[n] = cur
				if not open.has(n):
					open.append(n)
	return {"cost": cost, "prev": prev}


static func reachable(state: BattleState, u: Unit) -> Dictionary:
	return explore(state, u, u.move_range())


## Tiles in `reach` that `u` may end its move on.
static func stand_tiles(state: BattleState, u: Unit, reach: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for t in reach["cost"]:
		var occupant := state.unit_at(t)
		if occupant == null or occupant == u:
			out.append(t)
	return out


## The path from the explore origin to `target`, both ends included.
static func path_to(reach: Dictionary, target: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not reach["cost"].has(target):
		return out
	var cur := target
	out.append(cur)
	while reach["prev"].has(cur):
		cur = reach["prev"][cur]
		out.append(cur)
	out.reverse()
	return out


## Every tile `u` could strike from any of `stands`, as a set.
static func threat_tiles(state: BattleState, u: Unit, stands: Array[Vector2i]) -> Dictionary:
	var out := {}
	var span := u.attack_span()
	if span.y == 0:
		return out
	for s in stands:
		for w in u.attack_weapons():
			for t in state.map.tiles_in_range(s, WeaponDB.min_range(w), WeaponDB.max_range(w)):
				if _holdable(state, t):
					out[t] = true
	return out


## Whether any unit could ever stand on `t` (walls can't be struck at).
static func _holdable(state: BattleState, t: Vector2i) -> bool:
	return state.map.move_cost(t, "flier") < Terrain.IMPASSABLE


## Every tile `u` could heal from any of `stands`, as a set.
static func staff_tiles(state: BattleState, u: Unit, stands: Array[Vector2i]) -> Dictionary:
	var out := {}
	for s in stands:
		for w in u.staves():
			for t in state.map.tiles_in_range(s, WeaponDB.min_range(w), WeaponDB.max_range(w)):
				if _holdable(state, t):
					out[t] = true
	return out


## The union of every living unit of `team`'s threat — the danger zone.
static func team_threat(state: BattleState, team: int) -> Dictionary:
	var out := {}
	for u in state.living(team):
		var stands: Array[Vector2i] = [u.pos]
		if u.ai != "hold":
			stands = stand_tiles(state, u, reachable(state, u))
		out.merge(threat_tiles(state, u, stands))
	return out
