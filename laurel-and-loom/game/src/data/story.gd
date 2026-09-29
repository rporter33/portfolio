class_name Story
extends RefCounted
## The first act's dialogue, staged as friezes before and after each battle.
## Lines are [speaker, text]; "narrator" has no portrait. Speakers who are
## enemies are listed in ENEMY_SPEAKERS so their cameo is drawn terracotta.

const ENEMY_SPEAKERS := ["bassa"]

const SCENES := {
	"prologue_pre": {
		"place": "The Academy of Lachesis", "time": "Night", "scenery": "academy",
		"lines": [
			["narrator", "The Heptapolis: seven marble cities, one Senate, and a bronze loom said to have belonged to the Fates."],
			["narrator", "Tonight the Consul Varro Aurex dissolved the Senate, and took the Distaff of Clotho from the Temple of the Moirai."],
			["selene", "Ione — the bronze doors are open. There are Praetorians in the peristyle."],
			["ione", "Master Pell is still in the library. He gave me these and told me to run."],
			["cassian", "The Shears of Atropos. He trusted you with those?"],
			["ione", "He trusted me to read the thread. I can see a little of what's coming — three strikes, sometimes four. Never more."],
			["cassian", "Four is more than they can see. It'll do. Stay behind my shield, Augur."],
			["selene", "And if anyone is hurt, come to me. The hearth goes where I go."],
		],
	},
	"prologue_post": {
		"place": "The Academy of Lachesis", "time": "Before dawn", "scenery": "academy",
		"lines": [
			["cassian", "That's the courtyard. The north road is open — for now."],
			["selene", "Where do we go? The Senate is scattered to every city in the concord."],
			["ione", "To the Temple of the Moirai. If Aurex took the Distaff from there, the priests will know what it can do."],
			["cassian", "Three weeks on foot, through his legions."],
			["ione", "Then we'd best take the Olive Road before he closes it."],
		],
	},
	"ch1_pre": {
		"place": "The Olive Road", "time": "Two days north", "scenery": "road",
		"lines": [
			["narrator", "The Olive Road climbs through the groves to the Hill Gate. Whoever holds the gate holds the valley."],
			["dama", "You're the Academy runaways? I've been following your Praetorians since the river. They're sloppy."],
			["oren", "Oren Tace, lictor to the Senate. Retired by decree this morning. I'd like to un-retire."],
			["ione", "The gate at the top of the road — if we hold it, the whole valley is ours to cross."],
			["dama", "Then someone should stand in it. Preferably you, Augur. They'll want to see who's in charge."],
			["oren", "And if a hoplite is standing in it first, I'll move him. That's what the axe is for."],
		],
	},
	"ch1_post": {
		"place": "The Hill Gate", "time": "Evening", "scenery": "road",
		"lines": [
			["oren", "Gate's ours. Aurex will hear about that."],
			["ione", "Let him. Dama — what's beyond the valley?"],
			["dama", "The aqueduct at Serra. It's the only water for thirty miles. His cavalry will stop there."],
			["selene", "And so must we."],
		],
	},
	"ch2_pre": {
		"place": "The Aqueduct at Serra", "time": "Dusk", "scenery": "aqueduct",
		"lines": [
			["narrator", "The aqueduct at Serra strides across the plain on a hundred arches. Horses can't pass the piers; people can."],
			["mirelle", "Hold your spears — I'm with you. Mirelle Anthe, of the equestrian order. What's left of it."],
			["cassian", "How much is left?"],
			["mirelle", "Me. And a century of Praetorians an hour behind me."],
			["ione", "Then we hold the arches until nightfall. Seven turns of the glass."],
			["mirelle", "Their riders are fast, but they've never faced a braced spear. Put your captain in front of them."],
		],
	},
	"ch2_post": {
		"place": "The Aqueduct at Serra", "time": "Nightfall", "scenery": "aqueduct",
		"lines": [
			["mirelle", "They're pulling back. The night is on our side."],
			["ione", "The thread ran thin tonight. I could barely see past the next bead."],
			["selene", "The Temple is a day's ride. If the Distaff is there..."],
			["mirelle", "It isn't. But Bassa is — Aurex's centurion. He holds the temple road."],
		],
	},
	"ch3_pre": {
		"place": "The Temple of the Moirai", "time": "Morning", "scenery": "temple",
		"lines": [
			["narrator", "The Temple of the Moirai stands above Serra, its colonnades older than the Heptapolis itself."],
			["theron", "Well. The Augur of the Academy. I'd heard you were dead; I'm glad the rumour was exaggerated."],
			["ione", "Theron Kale. You were exiled."],
			["theron", "For speeches. I've been making them to the temple pigeons since. Bassa's men don't care for them either."],
			["bassa", "Augur! Give me the Shears and I'll let your friends walk home."],
			["ione", "They are home. Every stone of this temple belongs to the Senate."],
			["bassa", "Then you'll share a tomb with it."],
		],
	},
	"ch3_post": {
		"place": "The Temple of the Moirai", "time": "Noon", "scenery": "temple",
		"lines": [
			["bassa", "The Consul... has the Distaff. He'll spin... your thread... short."],
			["theron", "Dramatic. Accurate, possibly."],
			["ione", "The priests are gone. The loom is still here — but the Distaff isn't."],
			["selene", "Then he's taken it to the capital."],
			["ione", "Then so will we."],
			["narrator", "Here ends the First Act."],
		],
	},
}


static func scene(id: String) -> Dictionary:
	return SCENES.get(id, {})


static func has(id: String) -> bool:
	return SCENES.has(id)


static func speaker_name(speaker: String) -> String:
	if speaker == "narrator":
		return ""
	return str(Characters.info(speaker).get("name", speaker.capitalize()))
