class_name Characters
extends RefCounted
## The named companions (and named enemies). Stats are level-1 bases unless a
## level is given; growths are percentages rolled on level-up.

const DATA := {
	"ione": {"name": "Ione Vell", "class": "augur", "level": 1, "lord": true,
		"stats": {"hp": 20, "str": 6, "mag": 3, "skl": 7, "spd": 8, "lck": 7, "def": 5, "res": 4},
		"growths": {"hp": 60, "str": 45, "mag": 25, "skl": 50, "spd": 55, "lck": 50, "def": 30, "res": 30},
		"weapons": ["gladius"],
		"bio": "Junior Augur of the Academy. She can read the thread a little way ahead — never far."},
	"cassian": {"name": "Cassian Duro", "class": "hastatus", "level": 2,
		"stats": {"hp": 24, "str": 8, "mag": 0, "skl": 5, "spd": 4, "lck": 3, "def": 9, "res": 2},
		"growths": {"hp": 80, "str": 45, "mag": 0, "skl": 35, "spd": 25, "lck": 25, "def": 45, "res": 15},
		"weapons": ["hasta", "pilum"],
		"bio": "Captain of the Academy watch. Slow to speak, slower to give ground."},
	"dama": {"name": "Dama Rhue", "class": "sagittaria", "level": 1,
		"stats": {"hp": 18, "str": 6, "mag": 1, "skl": 8, "spd": 7, "lck": 4, "def": 3, "res": 3},
		"growths": {"hp": 55, "str": 40, "mag": 10, "skl": 60, "spd": 50, "lck": 35, "def": 20, "res": 25},
		"weapons": ["arcus"],
		"bio": "A hunter from the hill country who came to the capital for the games and stayed for the quarrel."},
	"oren": {"name": "Oren Tace", "class": "lictor", "level": 2,
		"stats": {"hp": 27, "str": 9, "mag": 0, "skl": 3, "spd": 5, "lck": 2, "def": 5, "res": 0},
		"growths": {"hp": 90, "str": 55, "mag": 0, "skl": 30, "spd": 35, "lck": 20, "def": 30, "res": 5},
		"weapons": ["securis"],
		"bio": "Carried the fasces before the Senate for eleven years. Would like the Senate back."},
	"selene": {"name": "Selene Amar", "class": "vestal", "level": 1,
		"stats": {"hp": 17, "str": 1, "mag": 6, "skl": 5, "spd": 6, "lck": 8, "def": 2, "res": 7},
		"growths": {"hp": 50, "str": 10, "mag": 55, "skl": 40, "spd": 45, "lck": 55, "def": 15, "res": 50},
		"weapons": ["caduceus", "ode"],
		"bio": "A Vestal of the temple hearth, who left the flame in another's keeping to follow Ione."},
	"mirelle": {"name": "Mirelle Anthe", "class": "eques", "level": 3,
		"stats": {"hp": 23, "str": 7, "mag": 1, "skl": 6, "spd": 8, "lck": 5, "def": 6, "res": 3},
		"growths": {"hp": 70, "str": 45, "mag": 10, "skl": 45, "spd": 50, "lck": 35, "def": 30, "res": 20},
		"weapons": ["hasta", "gladius"],
		"bio": "A knight of the equestrian order, who rode out of the city the morning the Senate fell."},
	"theron": {"name": "Theron Kale", "class": "orator", "level": 3,
		"stats": {"hp": 19, "str": 1, "mag": 8, "skl": 6, "spd": 6, "lck": 4, "def": 2, "res": 6},
		"growths": {"hp": 50, "str": 5, "mag": 60, "skl": 45, "spd": 45, "lck": 30, "def": 15, "res": 45},
		"weapons": ["ode", "elegy"],
		"bio": "A rhetorician whose speeches against the Consul got him exiled. His hymns are worse."},

	# --- Named enemies -------------------------------------------------------
	"bassa": {"name": "Centurion Bassa", "class": "centurion", "level": 5, "boss": true,
		"stats": {"hp": 32, "str": 11, "mag": 0, "skl": 8, "spd": 6, "lck": 4, "def": 11, "res": 3},
		"growths": {},
		"weapons": ["spatha", "pilum"],
		"bio": "Aurex's most loyal centurion. Holds the Temple road."},
}


static func info(id: String) -> Dictionary:
	return DATA.get(id, {})


static func has(id: String) -> bool:
	return DATA.has(id)
