class_name Unit
extends RefCounted
## One unit's battle state. Plain data plus small queries; the rules that
## change it live in BattleState and Combat.

enum Team { PLAYER = 0, ENEMY = 1 }

var uid: int = 0
var id: String = ""            ## Character id, or class id for generic soldiers.
var name: String = ""
var team: int = Team.PLAYER
var class_id: String = ""
var level: int = 1
var xp: int = 0
var stats: Dictionary = {}     ## Max values: hp str mag skl spd lck def res.
var growths: Dictionary = {}
var hp: int = 0
var pos: Vector2i = Vector2i.ZERO
var weapons: Array[String] = []
var is_lord: bool = false
var is_boss: bool = false
var ai: String = "charge"      ## charge | guard | hold
## Set when the unit changes tile during its own phase (bows' Steady reads it).
var moved: bool = false
var acted: bool = false


static func from_character(char_id: String) -> Unit:
	var d: Dictionary = Characters.info(char_id)
	assert(not d.is_empty(), "Unknown character: " + char_id)
	var u := Unit.new()
	u.id = char_id
	u.name = d["name"]
	u.class_id = d["class"]
	u.level = int(d.get("level", 1))
	u.stats = (d["stats"] as Dictionary).duplicate()
	u.growths = (d.get("growths", {}) as Dictionary).duplicate()
	for w in d.get("weapons", []):
		u.weapons.append(str(w))
	u.is_lord = bool(d.get("lord", false))
	u.is_boss = bool(d.get("boss", false))
	u.hp = u.max_hp()
	return u


## A generic soldier of `class_id` at `lvl`: class bases plus the expected
## (deterministic) gain for each level above 1.
static func from_class(cls: String, lvl: int = 1) -> Unit:
	var c: Dictionary = UnitClasses.info(cls)
	assert(c.has("base"), "Class has no base stats: " + cls)
	var u := Unit.new()
	u.id = cls
	u.name = c["name"]
	u.class_id = cls
	u.level = lvl
	u.growths = (c["growths"] as Dictionary).duplicate()
	for k in UnitClasses.STAT_KEYS:
		var base := int(c["base"].get(k, 0))
		u.stats[k] = base + (lvl - 1) * int(u.growths.get(k, 0)) / 100
	for w in c.get("kit", []):
		u.weapons.append(str(w))
	u.hp = u.max_hp()
	return u


func max_hp() -> int:
	return int(stats.get("hp", 1))


func stat(key: String) -> int:
	return int(stats.get(key, 0))


func move_range() -> int:
	return UnitClasses.move(class_id)


func move_type() -> String:
	return UnitClasses.move_type(class_id)


func class_name_text() -> String:
	return UnitClasses.display_name(class_id)


func is_alive() -> bool:
	return hp > 0


func is_wounded() -> bool:
	return hp < max_hp()


func attack_weapons() -> Array[String]:
	var out: Array[String] = []
	for w in weapons:
		if WeaponDB.is_attack(w):
			out.append(w)
	return out


func staves() -> Array[String]:
	var out: Array[String] = []
	for w in weapons:
		if WeaponDB.is_staff(w):
			out.append(w)
	return out


## The weapon a unit fights with by default: the first attack weapon.
func equipped() -> String:
	var aw := attack_weapons()
	return aw[0] if aw.size() > 0 else ""


## Move `weapon_id` to the front so it becomes the equipped weapon.
func equip(weapon_id: String) -> void:
	var i := weapons.find(weapon_id)
	if i > 0:
		weapons.remove_at(i)
		weapons.insert(0, weapon_id)


## The weapon used to counter at `distance`: the equipped one if it reaches,
## otherwise the first attack weapon that does.
func counter_weapon(distance: int) -> String:
	for w in attack_weapons():
		if WeaponDB.reaches(w, distance):
			return w
	return ""


## Union of attack ranges as (min, max); (0, 0) when unarmed.
func attack_span() -> Vector2i:
	var lo := 99
	var hi := 0
	for w in attack_weapons():
		lo = mini(lo, WeaponDB.min_range(w))
		hi = maxi(hi, WeaponDB.max_range(w))
	return Vector2i(lo, hi) if hi > 0 else Vector2i.ZERO


func clone() -> Unit:
	var u := Unit.new()
	u.uid = uid
	u.id = id
	u.name = name
	u.team = team
	u.class_id = class_id
	u.level = level
	u.xp = xp
	u.stats = stats.duplicate()
	u.growths = growths.duplicate()
	u.hp = hp
	u.pos = pos
	u.weapons = weapons.duplicate()
	u.is_lord = is_lord
	u.is_boss = is_boss
	u.ai = ai
	u.moved = moved
	u.acted = acted
	return u


## Persistent parts only (for the campaign roster and saves).
func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "class": class_id, "level": level, "xp": xp,
		"stats": stats.duplicate(), "growths": growths.duplicate(),
		"weapons": Array(weapons), "lord": is_lord,
	}


static func from_dict(d: Dictionary) -> Unit:
	var u := Unit.new()
	u.id = str(d["id"])
	u.name = str(d["name"])
	u.class_id = str(d["class"])
	u.level = int(d.get("level", 1))
	u.xp = int(d.get("xp", 0))
	for k in (d["stats"] as Dictionary):
		u.stats[str(k)] = int(d["stats"][k])
	for k in (d.get("growths", {}) as Dictionary):
		u.growths[str(k)] = int(d["growths"][k])
	for w in d.get("weapons", []):
		u.weapons.append(str(w))
	u.is_lord = bool(d.get("lord", false))
	u.hp = u.max_hp()
	return u
