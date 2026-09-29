class_name UnitClasses
extends RefCounted
## Classes: movement, weapon types, how the cameo is drawn, and — for classes
## the enemy fields — base stats and growths used to level generic soldiers.
##
## Stat keys everywhere: hp str mag skl spd lck def res.

const STAT_KEYS := ["hp", "str", "mag", "skl", "spd", "lck", "def", "res"]

const DATA := {
	# --- Companions --------------------------------------------------------
	"augur": {"name": "Augur", "move": 5, "move_type": "foot", "weapons": ["sword"],
		"mark": "laurel", "desc": "A reader of the Measured Thread."},
	"hastatus": {"name": "Hastatus", "move": 5, "move_type": "foot", "weapons": ["spear"],
		"mark": "crest", "desc": "A spearman of the front rank."},
	"sagittaria": {"name": "Sagittaria", "move": 5, "move_type": "foot", "weapons": ["bow"],
		"mark": "bow", "desc": "An archer. Deadliest when she holds her ground."},
	"lictor": {"name": "Lictor", "move": 5, "move_type": "foot", "weapons": ["axe"],
		"mark": "fasces", "desc": "Bearer of the fasces. Strong, not subtle."},
	"vestal": {"name": "Vestal", "move": 5, "move_type": "foot", "weapons": ["staff", "hymn"],
		"mark": "veil", "desc": "Keeper of the hearth. Heals with the caduceus."},
	"orator": {"name": "Orator", "move": 5, "move_type": "foot", "weapons": ["hymn"],
		"mark": "scroll", "desc": "A hymn-mage. Words that wound."},
	"eques": {"name": "Eques", "move": 7, "move_type": "cavalry", "weapons": ["spear", "sword"],
		"mark": "horse", "desc": "A mounted knight. Far-ranging, but spears break her charge.",
		"base": {"hp": 21, "str": 7, "mag": 0, "skl": 5, "spd": 6, "lck": 2, "def": 5, "res": 1},
		"growths": {"hp": 70, "str": 40, "mag": 0, "skl": 35, "spd": 40, "lck": 20, "def": 30, "res": 10},
		"kit": ["hasta"]},

	# --- Praetorians -------------------------------------------------------
	"legionary": {"name": "Legionary", "move": 5, "move_type": "foot", "weapons": ["sword"],
		"mark": "crest", "desc": "A sworn soldier of the Consul.",
		"base": {"hp": 19, "str": 6, "mag": 0, "skl": 4, "spd": 5, "lck": 1, "def": 4, "res": 1},
		"growths": {"hp": 70, "str": 40, "mag": 0, "skl": 35, "spd": 40, "lck": 15, "def": 25, "res": 10},
		"kit": ["gladius"]},
	"hoplite": {"name": "Hoplite", "move": 4, "move_type": "armor", "weapons": ["spear"],
		"mark": "helm", "desc": "Bronze from crest to greave. Hymns find the gaps.",
		"base": {"hp": 23, "str": 7, "mag": 0, "skl": 3, "spd": 2, "lck": 0, "def": 10, "res": 0},
		"growths": {"hp": 80, "str": 45, "mag": 0, "skl": 30, "spd": 15, "lck": 10, "def": 50, "res": 5},
		"kit": ["hasta"]},
	"brigand": {"name": "Lictor", "move": 5, "move_type": "foot", "weapons": ["axe"],
		"mark": "fasces", "desc": "An axe-bearer of the Consul's escort.",
		"base": {"hp": 24, "str": 8, "mag": 0, "skl": 2, "spd": 4, "lck": 0, "def": 3, "res": 0},
		"growths": {"hp": 85, "str": 50, "mag": 0, "skl": 25, "spd": 30, "lck": 10, "def": 20, "res": 5},
		"kit": ["securis"]},
	"archer": {"name": "Archer", "move": 5, "move_type": "foot", "weapons": ["bow"],
		"mark": "bow", "desc": "A Praetorian bowman.",
		"base": {"hp": 17, "str": 5, "mag": 0, "skl": 5, "spd": 5, "lck": 1, "def": 3, "res": 1},
		"growths": {"hp": 60, "str": 40, "mag": 0, "skl": 45, "spd": 40, "lck": 15, "def": 20, "res": 15},
		"kit": ["arcus"]},
	"hymnist": {"name": "Hymnist", "move": 5, "move_type": "foot", "weapons": ["hymn"],
		"mark": "scroll", "desc": "A temple singer turned to the Consul's cause.",
		"base": {"hp": 16, "str": 0, "mag": 6, "skl": 4, "spd": 5, "lck": 1, "def": 1, "res": 5},
		"growths": {"hp": 50, "str": 0, "mag": 45, "skl": 35, "spd": 40, "lck": 20, "def": 10, "res": 40},
		"kit": ["ode"]},
	"centurion": {"name": "Centurion", "move": 5, "move_type": "armor", "weapons": ["sword", "spear"],
		"mark": "helm", "desc": "Commander of a hundred. Wears the transverse crest.",
		"base": {"hp": 28, "str": 9, "mag": 0, "skl": 7, "spd": 5, "lck": 3, "def": 10, "res": 3},
		"growths": {"hp": 80, "str": 50, "mag": 0, "skl": 40, "spd": 30, "lck": 20, "def": 40, "res": 15},
		"kit": ["spatha", "pilum"]},
}


static func info(id: String) -> Dictionary:
	return DATA.get(id, {})


static func display_name(id: String) -> String:
	return str(info(id).get("name", id.capitalize()))


static func move(id: String) -> int:
	return int(info(id).get("move", 5))


static func move_type(id: String) -> String:
	return str(info(id).get("move_type", "foot"))


static func can_wield(id: String, weapon_id: String) -> bool:
	return WeaponDB.type_of(weapon_id) in info(id).get("weapons", [])
