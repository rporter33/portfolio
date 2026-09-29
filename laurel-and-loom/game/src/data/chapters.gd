class_name Chapters
extends RefCounted
## Chapter definitions. Each map is two ASCII layers of the same size:
##   terrain  — characters from Terrain.DEFS
##   units    — "." for none, otherwise a key into `legend`
## Legend entries name a character ("char") or a soldier class ("class").
## Characters default to the player's side, classes to the enemy's.

const ORDER := ["prologue"]

const DATA := {
	"prologue": {
		"title": "The Oath at the Academy",
		"numeral": "Prologue",
		"objective": {"type": "rout"},
		"seed": 1017,
		"terrain": [
			"######___######",
			"#t,|..._...|,t#",
			"#,,|.......|,,#",
			"#.............#",
			"#.|..~~~~~..|.#",
			"#.|..~~~~~..|.#",
			"#.............#",
			"#,,|.......|,,#",
			"#t,|...A...|,t#",
			"###############",
		],
		"units": [
			".......a.......",
			".....l...l.....",
			"...............",
			"............g..",
			"...............",
			"...............",
			".......C.......",
			"......I.S......",
			"...............",
			"...............",
		],
		"legend": {
			"I": {"char": "ione"},
			"C": {"char": "cassian"},
			"S": {"char": "selene"},
			"l": {"class": "legionary", "level": 1, "ai": "charge"},
			"g": {"class": "legionary", "level": 1, "ai": "guard"},
			"a": {"class": "archer", "level": 1, "ai": "guard"},
		},
	},
}


static func data(id: String) -> Dictionary:
	return DATA.get(id, {})


static func has(id: String) -> bool:
	return DATA.has(id)
