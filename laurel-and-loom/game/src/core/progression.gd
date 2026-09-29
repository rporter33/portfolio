class_name Progression
extends RefCounted
## Experience and level-ups.
##
## Level-ups roll each stat against its growth, but the roll is seeded by the
## unit and the level it's reaching — not drawn from the thread, and not
## random per attempt. A companion's Level 5 is the same Level 5 however many
## times you Unravel or retry: growth is fate, too.

const LEVEL_CAP := 20
const XP_PER_LEVEL := 100
const STAFF_XP := 12


## XP for one combat, for the player unit `u` against `foe`.
static func combat_xp(u: Unit, foe: Unit, dealt_damage: bool, killed: bool) -> int:
	if u.level >= LEVEL_CAP:
		return 0
	var diff := foe.level - u.level
	if not dealt_damage and not killed:
		return 1
	var xp := 10 + diff * 2
	if killed:
		xp += 20 + diff * 3 + (30 if foe.is_boss else 0)
	return clampi(xp, 1, XP_PER_LEVEL)


static func staff_xp(u: Unit) -> int:
	return STAFF_XP if u.level < LEVEL_CAP else 0


## Add XP; returns one entry per level gained: {"level": int, "gains": {stat: +n}}.
static func grant(u: Unit, amount: int) -> Array:
	var ups := []
	u.xp += amount
	while u.xp >= XP_PER_LEVEL and u.level < LEVEL_CAP:
		u.xp -= XP_PER_LEVEL
		ups.append(level_up(u))
	if u.level >= LEVEL_CAP:
		u.xp = 0
	return ups


static func level_up(u: Unit) -> Dictionary:
	u.level += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [u.id, u.level])
	var gains := {}
	for k in UnitClasses.STAT_KEYS:
		if rng.randi_range(1, 100) <= int(u.growths.get(k, 0)):
			gains[k] = 1
	if gains.is_empty():
		# Never an empty level: the best growth always rises.
		var best := "hp"
		for k in UnitClasses.STAT_KEYS:
			if int(u.growths.get(k, 0)) > int(u.growths.get(best, 0)):
				best = k
		gains[best] = 1
	for k in gains:
		u.stats[k] = u.stat(k) + int(gains[k])
		if k == "hp":
			u.hp += int(gains[k])
	return {"level": u.level, "gains": gains}
