class_name BattleSetup
extends RefCounted
## Builds a BattleState from a chapter definition.


## `roster` maps character id → Unit.to_dict(); companions found there keep
## their levels and stats, everyone else comes from Characters.
static func create(chapter_id: String, roster: Dictionary = {}, seed_override: int = -1) -> BattleState:
	var ch := Chapters.data(chapter_id)
	assert(not ch.is_empty(), "Unknown chapter: " + chapter_id)
	var map := BattleMap.new(PackedStringArray(ch["terrain"]))
	var seed_value := int(ch.get("seed", 1)) if seed_override < 0 else seed_override
	var st := BattleState.new(map, seed_value)

	var obj: Dictionary = (ch.get("objective", {"type": "rout"}) as Dictionary).duplicate()
	if obj.get("type", "") == "seize" and not obj.has("tile"):
		var gates := map.find_all("G")
		if not gates.is_empty():
			obj["tile"] = gates[0]
	st.objective = obj

	var layer: Array = ch["units"]
	var legend: Dictionary = ch["legend"]
	for y in layer.size():
		var row := str(layer[y])
		for x in row.length():
			var key := row[x]
			if key == ".":
				continue
			assert(legend.has(key), "Chapter %s: no legend entry for '%s'" % [chapter_id, key])
			var spec: Dictionary = legend[key]
			var u: Unit
			var team: int
			if spec.has("char"):
				var cid := str(spec["char"])
				u = Unit.from_dict(roster[cid]) if roster.has(cid) else Unit.from_character(cid)
				team = Unit.Team.ENEMY if spec.get("team", "player") == "enemy" else Unit.Team.PLAYER
			else:
				u = Unit.from_class(str(spec["class"]), int(spec.get("level", 1)))
				team = Unit.Team.PLAYER if spec.get("team", "enemy") == "player" else Unit.Team.ENEMY
			u.ai = str(spec.get("ai", "charge"))
			if spec.has("weapons"):
				u.weapons.clear()
				for w in spec["weapons"]:
					u.weapons.append(str(w))
			if spec.get("boss", false):
				u.is_boss = true
			st.add_unit(u, team, Vector2i(x, y))
	st.begin_phase(Unit.Team.PLAYER)
	return st
