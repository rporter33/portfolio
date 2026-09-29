class_name Terrain
extends RefCounted
## Terrain, keyed by the character that draws it in an ASCII map.
## Costs are per movement type; IMPASSABLE means the tile can't be entered.

const IMPASSABLE := 99

const DEFS := {
	".": {"id": "plaza", "name": "Plaza", "avoid": 0, "def": 0,
		"cost": {"foot": 1, "armor": 1, "cavalry": 1, "flier": 1}},
	",": {"id": "meadow", "name": "Meadow", "avoid": 0, "def": 0,
		"cost": {"foot": 1, "armor": 1, "cavalry": 1, "flier": 1}},
	"_": {"id": "road", "name": "Road", "avoid": 0, "def": 0,
		"cost": {"foot": 1, "armor": 1, "cavalry": 1, "flier": 1}},
	"t": {"id": "grove", "name": "Olive Grove", "avoid": 20, "def": 1,
		"cost": {"foot": 2, "armor": 3, "cavalry": 3, "flier": 1}},
	"|": {"id": "column", "name": "Colonnade", "avoid": 20, "def": 1,
		"cost": {"foot": 2, "armor": 2, "cavalry": IMPASSABLE, "flier": 1}},
	"^": {"id": "rubble", "name": "Rubble", "avoid": 10, "def": 0,
		"cost": {"foot": 2, "armor": 2, "cavalry": 3, "flier": 1}},
	"s": {"id": "stairs", "name": "Stairs", "avoid": 0, "def": 0,
		"cost": {"foot": 1, "armor": 1, "cavalry": 2, "flier": 1}},
	"A": {"id": "altar", "name": "Altar", "avoid": 20, "def": 2, "heal": 20,
		"cost": {"foot": 1, "armor": 1, "cavalry": 1, "flier": 1}},
	"G": {"id": "gate", "name": "Gate", "avoid": 10, "def": 1,
		"cost": {"foot": 1, "armor": 1, "cavalry": 1, "flier": 1}},
	"=": {"id": "bridge", "name": "Bridge", "avoid": 0, "def": 0,
		"cost": {"foot": 1, "armor": 1, "cavalry": 1, "flier": 1}},
	"~": {"id": "pool", "name": "Pool", "avoid": 0, "def": 0,
		"cost": {"foot": IMPASSABLE, "armor": IMPASSABLE, "cavalry": IMPASSABLE, "flier": 1}},
	"#": {"id": "wall", "name": "Wall", "avoid": 0, "def": 0,
		"cost": {"foot": IMPASSABLE, "armor": IMPASSABLE, "cavalry": IMPASSABLE, "flier": IMPASSABLE}},
}


static func is_known(ch: String) -> bool:
	return DEFS.has(ch)


static func info(ch: String) -> Dictionary:
	return DEFS.get(ch, DEFS["#"])


static func move_cost(ch: String, move_type: String) -> int:
	return int(info(ch)["cost"].get(move_type, IMPASSABLE))


static func avoid(ch: String) -> int:
	return int(info(ch).get("avoid", 0))


static func defense(ch: String) -> int:
	return int(info(ch).get("def", 0))


static func heal_percent(ch: String) -> int:
	return int(info(ch).get("heal", 0))
