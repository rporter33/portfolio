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
			var u := unit_from_spec(spec, roster)
			if u == null:
				continue
			st.add_unit(u, _team_of(spec), Vector2i(x, y))
	for r in ch.get("reinforcements", []):
		var entry: Dictionary = (r as Dictionary).duplicate()
		entry["at"] = Vector2i(int(r["at"][0]), int(r["at"][1]))
		st.reinforcements.append(entry)
	st.begin_phase(Unit.Team.PLAYER)
	return st


## Build a unit from a legend or reinforcement entry. Returns null for a
## companion who has fallen in a Classic campaign.
static func unit_from_spec(spec: Dictionary, roster: Dictionary) -> Unit:
	var u: Unit
	if spec.has("char"):
		var cid := str(spec["char"])
		if roster.has(cid):
			if roster[cid].get("fallen", false):
				return null
			u = Unit.from_dict(roster[cid])
		else:
			u = Unit.from_character(cid)
	else:
		u = Unit.from_class(str(spec["class"]), int(spec.get("level", 1)))
	u.ai = str(spec.get("ai", "charge"))
	if spec.has("weapons"):
		u.weapons.clear()
		for w in spec["weapons"]:
			u.weapons.append(str(w))
	if spec.get("boss", false):
		u.is_boss = true
	return u


static func _team_of(spec: Dictionary) -> int:
	if spec.has("char"):
		return Unit.Team.ENEMY if spec.get("team", "player") == "enemy" else Unit.Team.PLAYER
	return Unit.Team.PLAYER if spec.get("team", "enemy") == "player" else Unit.Team.ENEMY
