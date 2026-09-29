class_name BattleState
extends RefCounted
## Everything about a battle in progress, and every rule that changes it.
## No nodes: the battle scene asks this object what happens, then animates.
## clone() is cheap enough to snapshot before every player action (Unravel).

enum Outcome { ONGOING, VICTORY, DEFEAT }

const PLAYER := Unit.Team.PLAYER
const ENEMY := Unit.Team.ENEMY

const FORTUNE_MAX := 6
const FORTUNE_START := 2
const UNRAVELS := 3
const ART_COST := {"measure": 1, "cut": 2, "turn": 3}

var map: BattleMap
var units: Array[Unit] = []
var thread: FateThread
var fortune: int = FORTUNE_START
var turn: int = 1
var phase: int = PLAYER
## {"type": "rout" | "seize" | "survive" | "boss", "tile": Vector2i, "turns": int}
var objective: Dictionary = {"type": "rout"}
var outcome: int = Outcome.ONGOING
var unravels_left: int = UNRAVELS
var _next_uid: int = 1


func _init(m: BattleMap = null, seed_in: int = 0) -> void:
	map = m
	thread = FateThread.new(seed_in)


# --- Units -------------------------------------------------------------------

func add_unit(u: Unit, team: int, at: Vector2i) -> Unit:
	u.uid = _next_uid
	_next_uid += 1
	u.team = team
	u.pos = at
	units.append(u)
	return u


func unit_at(c: Vector2i) -> Unit:
	for u in units:
		if u.hp > 0 and u.pos == c:
			return u
	return null


func unit_by_uid(uid: int) -> Unit:
	for u in units:
		if u.uid == uid:
			return u
	return null


func living(team: int = -1) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.hp > 0 and (team == -1 or u.team == team):
			out.append(u)
	return out


func foes_of(u: Unit) -> Array[Unit]:
	return living(ENEMY if u.team == PLAYER else PLAYER)


func allies_of(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o in living(u.team):
		if o != u:
			out.append(o)
	return out


func lord() -> Unit:
	for u in units:
		if u.team == PLAYER and u.is_lord:
			return u
	return null


func boss() -> Unit:
	for u in units:
		if u.team == ENEMY and u.is_boss:
			return u
	return null


func ready_units(team: int = PLAYER) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in living(team):
		if not u.acted:
			out.append(u)
	return out


# --- Phases ------------------------------------------------------------------

## Start `team`'s phase: refresh its units, let altars heal them, and (for the
## player, after turn 1) turn the wheel of Fortune once.
## Returns [{"uid": int, "amount": int}] for altar heals.
func begin_phase(team: int) -> Array:
	phase = team
	thread.measured = false
	var healed: Array = []
	for u in living(team):
		u.moved = false
		u.acted = false
		var pct := Terrain.heal_percent(map.char_at(u.pos))
		if pct > 0 and u.is_wounded():
			var amount := mini(maxi(1, u.max_hp() * pct / 100), u.max_hp() - u.hp)
			u.hp += amount
			healed.append({"uid": u.uid, "amount": amount})
	if team == PLAYER and turn > 1:
		gain_fortune(1)
	return healed


## End the current phase and begin the next. Survive objectives are won when
## the enemy phase of their last turn ends.
func advance_phase() -> Array:
	if outcome != Outcome.ONGOING:
		return []
	if phase == PLAYER:
		return begin_phase(ENEMY)
	if objective.get("type", "") == "survive" and turn >= int(objective.get("turns", 0)):
		outcome = Outcome.VICTORY
		return []
	turn += 1
	return begin_phase(PLAYER)


# --- Actions -----------------------------------------------------------------

func move_unit(u: Unit, to: Vector2i) -> void:
	if to != u.pos:
		u.moved = true
	u.pos = to


func attack(u: Unit, weapon_id: String, target: Unit) -> Dictionary:
	u.equip(weapon_id)
	var result := Combat.resolve(self, u, weapon_id, target)
	u.acted = true
	var gained := 0
	for s in result["strikes"]:
		if s["striker_team"] == PLAYER and s["outcome"] == "miss":
			gained += 1
		if s["target_team"] == PLAYER and s["outcome"] == "crit":
			gained += 1
	result["fortune_gained"] = gain_fortune(gained)
	check_outcome()
	return result


func heal(u: Unit, staff_id: String, target: Unit) -> int:
	var amount := Combat.heal_amount(u, staff_id, target)
	target.hp += amount
	u.acted = true
	return amount


func wait(u: Unit) -> void:
	u.acted = true


func can_seize(u: Unit) -> bool:
	return objective.get("type", "") == "seize" and u.is_lord \
		and u.pos == objective.get("tile", Vector2i(-1, -1))


func seize(u: Unit) -> void:
	u.acted = true
	if can_seize(u):
		outcome = Outcome.VICTORY


# --- Fortune and the Fate Arts ---------------------------------------------

## Add `n` Fortune (capped); returns how much was actually added.
func gain_fortune(n: int) -> int:
	var before := fortune
	fortune = clampi(fortune + n, 0, FORTUNE_MAX)
	return fortune - before


func can_use_art(art: String) -> bool:
	if outcome != Outcome.ONGOING or phase != PLAYER:
		return false
	var l := lord()
	if l == null or not l.is_alive():
		return false
	if art == "measure" and thread.measured:
		return false
	return fortune >= int(ART_COST.get(art, 99))


func use_art(art: String) -> bool:
	if not can_use_art(art):
		return false
	fortune -= int(ART_COST[art])
	match art:
		"measure":
			thread.measured = true
		"cut":
			thread.cut()
		"turn":
			thread.turn()
	return true


# --- Outcome -------------------------------------------------------------------

func check_outcome() -> int:
	if outcome != Outcome.ONGOING:
		return outcome
	var l := lord()
	if (l != null and not l.is_alive()) or living(PLAYER).is_empty():
		outcome = Outcome.DEFEAT
		return outcome
	if living(ENEMY).is_empty():
		outcome = Outcome.VICTORY
		return outcome
	if objective.get("type", "") == "boss":
		var b := boss()
		if b == null or not b.is_alive():
			outcome = Outcome.VICTORY
	return outcome


func objective_text() -> String:
	match objective.get("type", "rout"):
		"seize":
			return "Seize the gate"
		"survive":
			return "Survive %d turns" % int(objective.get("turns", 0))
		"boss":
			var b := boss()
			return "Defeat %s" % (b.name if b != null else "the commander")
	return "Rout the enemy"


# --- Snapshots ---------------------------------------------------------------

## A deep copy. The map is immutable and shared.
func clone() -> BattleState:
	var s := BattleState.new(map, 0)
	for u in units:
		s.units.append(u.clone())
	s.thread = thread.clone()
	s.fortune = fortune
	s.turn = turn
	s.phase = phase
	s.objective = objective.duplicate()
	s.outcome = outcome
	s.unravels_left = unravels_left
	s._next_uid = _next_uid
	return s
