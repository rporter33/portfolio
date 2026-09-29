class_name Chapters
extends RefCounted
## Chapter definitions. Each map is two ASCII layers of the same size:
##   terrain  — characters from Terrain.DEFS
##   units    — "." for none, otherwise a key into `legend`
## Legend entries name a character ("char") or a soldier class ("class").
## Characters default to the player's side, classes to the enemy's.
## Reinforcements arrive at the start of the enemy phase of their turn, on
## the nearest free tile to `at`, and act from the following turn.

const ORDER := ["prologue", "ch1", "ch2", "ch3"]

const DATA := {
	"prologue": {
		"title": "The Oath at the Academy",
		"numeral": "Prologue",
		"objective": {"type": "rout"},
		"seed": 1017,
		"tutorial": true,
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

	"ch1": {
		"title": "The Olive Road",
		"numeral": "Chapter I",
		"objective": {"type": "seize"},
		"seed": 2203,
		"terrain": [
			"tt,,,,t,,~,,,t,,#G#,",
			"t,,,t,,,,~,,,,,,#_#t",
			",,t,,,,,,~,,t,,,,_,,",
			",,,,,,t,,~,,______t,",
			",t,,^^^,,~,,_,,,,,,,",
			",,,,^,,,,~,,_,t,,,,,",
			",,t,,,___=__,,,,,t,,",
			",,,,,,_,,~,,,,A,,,,,",
			"t,,,,,_,,~,,t,,,,,t,",
			"_______,,~,,,,,,,,,,",
			"_,,t,,,,,=,,,,t,,,,,",
			"_,,,,,,t,~,,,,,,,t,t",
			"_,,tt,,,,~,,,t,,,,tt",
		],
		"units": [
			"....................",
			"....b............h..",
			"..................a.",
			"..............g.....",
			"....................",
			"...........a........",
			"...........l........",
			"...........l...y....",
			"....................",
			"....................",
			"..C............l....",
			".I.S......b.........",
			"O..D................",
		],
		"legend": {
			"I": {"char": "ione"},
			"C": {"char": "cassian"},
			"S": {"char": "selene"},
			"D": {"char": "dama"},
			"O": {"char": "oren"},
			"l": {"class": "legionary", "level": 2, "ai": "charge"},
			"g": {"class": "legionary", "level": 3, "ai": "guard"},
			"a": {"class": "archer", "level": 2, "ai": "guard"},
			"b": {"class": "brigand", "level": 2, "ai": "charge"},
			"y": {"class": "hymnist", "level": 2, "ai": "guard"},
			"h": {"class": "hoplite", "level": 3, "ai": "hold"},
		},
	},

	"ch2": {
		"title": "The Aqueduct at Serra",
		"numeral": "Chapter II",
		"objective": {"type": "survive", "turns": 7},
		"seed": 3119,
		"terrain": [
			",,tt,,,,,,,,,,tt,,",
			"__________________",
			",,,,,,,t,,t,,,,,,,",
			",t,,,,,,,,,,,,,,t,",
			",,,,,,,,,,,,,,,,,,",
			"|.|.|.|.|.|.|.|.|.",
			",,,,,,,....,,,,,,,",
			",,t,,,,.~~.,,,,t,,",
			",,,,,,,.A~.,,,,,,,",
			",,,,t,,....,,t,,,,",
			"t,,,,,,,,,,,,,,,,t",
			"tt,,,,,t,,t,,,,,tt",
		],
		"units": [
			"..................",
			"..e............e..",
			"....l........l....",
			"..................",
			"..................",
			"..................",
			"......C....M......",
			"......I....D......",
			".......S..O.......",
			"..................",
			"..................",
			"..................",
		],
		"legend": {
			"I": {"char": "ione"},
			"C": {"char": "cassian"},
			"S": {"char": "selene"},
			"D": {"char": "dama"},
			"O": {"char": "oren"},
			"M": {"char": "mirelle"},
			"l": {"class": "legionary", "level": 3, "ai": "charge"},
			"e": {"class": "eques", "level": 3, "ai": "charge"},
		},
		"reinforcements": [
			{"turn": 2, "at": [0, 4], "class": "legionary", "level": 3, "ai": "charge"},
			{"turn": 2, "at": [17, 4], "class": "archer", "level": 3, "ai": "charge"},
			{"turn": 3, "at": [0, 1], "class": "eques", "level": 3, "ai": "charge"},
			{"turn": 3, "at": [17, 10], "class": "brigand", "level": 3, "ai": "charge"},
			{"turn": 4, "at": [8, 0], "class": "hymnist", "level": 3, "ai": "charge"},
			{"turn": 4, "at": [17, 1], "class": "legionary", "level": 3, "ai": "charge"},
			{"turn": 5, "at": [0, 10], "class": "brigand", "level": 4, "ai": "charge"},
			{"turn": 5, "at": [17, 4], "class": "eques", "level": 4, "ai": "charge"},
			{"turn": 6, "at": [0, 4], "class": "archer", "level": 4, "ai": "charge"},
		],
	},

	"ch3": {
		"title": "The Temple of the Moirai",
		"numeral": "Chapter III",
		"objective": {"type": "boss"},
		"seed": 4441,
		"terrain": [
			"######..A..#######",
			"#tt|.........|tt##",
			"#,,|.|.|.|.|.|,,,#",
			"#,,|.........|,t,#",
			"#,t|....~~...|,,,#",
			"#,,|....~~...|,,,#",
			"#,,|.........|,,,#",
			"#,,||||.s.||||,,,#",
			"#,,,,,,,s,,,,,,t,#",
			"#t,,,,,,s,,,,,,,,#",
			"#,,,^,,,s,,,,^,,,#",
			"#,,,^,,,s,,,t^,,,#",
			"#,t,,,,,,,,,,,,,,#",
			"##################",
		],
		"units": [
			"........B.........",
			"......h...h.......",
			"....a.......a.....",
			"..................",
			"......y.......l...",
			"..................",
			"......l....l......",
			"..................",
			".....g.....g......",
			"..................",
			"..................",
			"......C.I.M.......",
			"....D..S.T.O......",
			"..................",
		],
		"legend": {
			"I": {"char": "ione"},
			"C": {"char": "cassian"},
			"S": {"char": "selene"},
			"D": {"char": "dama"},
			"O": {"char": "oren"},
			"M": {"char": "mirelle"},
			"T": {"char": "theron"},
			"B": {"char": "bassa", "team": "enemy", "ai": "hold", "boss": true},
			"h": {"class": "hoplite", "level": 5, "ai": "hold"},
			"a": {"class": "archer", "level": 4, "ai": "guard"},
			"y": {"class": "hymnist", "level": 4, "ai": "guard"},
			"l": {"class": "legionary", "level": 4, "ai": "charge"},
			"g": {"class": "legionary", "level": 4, "ai": "guard"},
		},
	},
}


static func data(id: String) -> Dictionary:
	return DATA.get(id, {})


static func has(id: String) -> bool:
	return DATA.has(id)


static func index_of(id: String) -> int:
	return ORDER.find(id)
