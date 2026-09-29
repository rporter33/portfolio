class_name WeaponDB
extends RefCounted
## Every weapon in the game. No weapon triangle: each type carries one trait,
## documented in docs/DESIGN.md §7 and applied in Combat.
##
##   sword  Tempo      follows up at +3 Spd instead of +4
##   spear  Brace      effective against cavalry
##   axe    Shove      when initiating and landing a hit, pushes a surviving foe back
##   bow    Steady     +15 Hit if the archer hasn't moved this turn; effective vs fliers
##   hymn   Resonance  ignores terrain Avoid and Def
##   staff  —          heals Mag + heal, draws no bead

const TYPES := ["sword", "spear", "axe", "bow", "hymn", "staff"]
const MAGIC_TYPES := ["hymn", "staff"]

const DATA := {
	"gladius": {"name": "Gladius", "type": "sword", "mt": 5, "hit": 90, "crit": 0, "min": 1, "max": 1,
		"desc": "The legion's short sword. Quick in the hand."},
	"spatha": {"name": "Spatha", "type": "sword", "mt": 8, "hit": 75, "crit": 5, "min": 1, "max": 1,
		"desc": "A longer cavalry blade. Heavier, surer to wound."},
	"hasta": {"name": "Hasta", "type": "spear", "mt": 6, "hit": 80, "crit": 0, "min": 1, "max": 1,
		"desc": "The thrusting spear of the line. Braced against horse."},
	"pilum": {"name": "Pilum", "type": "spear", "mt": 4, "hit": 70, "crit": 0, "min": 1, "max": 2,
		"desc": "A weighted javelin, thrown or held."},
	"securis": {"name": "Securis", "type": "axe", "mt": 8, "hit": 70, "crit": 5, "min": 1, "max": 1,
		"desc": "The axe of the fasces. Drives a foe back a step."},
	"arcus": {"name": "Arcus", "type": "bow", "mt": 6, "hit": 85, "crit": 0, "min": 2, "max": 2,
		"desc": "A composite bow. Truest from a held position."},
	"ode": {"name": "Ode", "type": "hymn", "mt": 5, "hit": 85, "crit": 0, "min": 1, "max": 2,
		"desc": "A hymn of praise, sung until it cuts. Cover is no shelter from it."},
	"elegy": {"name": "Elegy", "type": "hymn", "mt": 8, "hit": 75, "crit": 5, "min": 1, "max": 2,
		"desc": "A lament with weight in it."},
	"caduceus": {"name": "Caduceus", "type": "staff", "heal": 10, "min": 1, "max": 1,
		"desc": "The herald's staff. Restores Mag + 10 HP."},
}


static func has(id: String) -> bool:
	return DATA.has(id)


static func info(id: String) -> Dictionary:
	return DATA.get(id, {})


static func type_of(id: String) -> String:
	return str(info(id).get("type", ""))


static func is_attack(id: String) -> bool:
	return has(id) and type_of(id) != "staff"


static func is_staff(id: String) -> bool:
	return type_of(id) == "staff"


static func is_magic(id: String) -> bool:
	return type_of(id) in MAGIC_TYPES


static func min_range(id: String) -> int:
	return int(info(id).get("min", 1))


static func max_range(id: String) -> int:
	return int(info(id).get("max", 1))


static func reaches(id: String, distance: int) -> bool:
	return has(id) and distance >= min_range(id) and distance <= max_range(id)


static func range_text(id: String) -> String:
	var lo := min_range(id)
	var hi := max_range(id)
	return str(lo) if lo == hi else "%d–%d" % [lo, hi]
