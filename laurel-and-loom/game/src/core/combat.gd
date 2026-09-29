class_name Combat
extends RefCounted
## Combat maths (docs/DESIGN.md §6–7). Three steps, kept separate so the
## forecast can never disagree with the fight:
##   plan()     who strikes, in what order, with what numbers — no randomness
##   forecast() reads the thread without drawing from it
##   resolve()  draws beads and applies damage

const CRIT_MULT := 3
const DOUBLE_GAP := 4
const TEMPO_GAP := 3       ## Swords: Tempo.
const STEADY_HIT := 15     ## Bows: Steady.
const EFFECTIVE_MULT := 2  ## Spears vs cavalry, bows vs fliers.


static func is_effective(weapon_type: String, target: Unit) -> bool:
	var mt := target.move_type()
	return (weapon_type == "spear" and mt == "cavalry") or (weapon_type == "bow" and mt == "flier")


## Damage, hit and crit for `a` striking `d` with `wid`, with `a` standing on
## `a_pos` and `d` on `d_pos`. `a_moved` decides whether a bow is Steady.
static func strike_numbers(map: BattleMap, a: Unit, wid: String, d: Unit,
		a_pos: Vector2i, d_pos: Vector2i, a_moved: bool) -> Dictionary:
	var w := WeaponDB.info(wid)
	var wtype := str(w["type"])
	var magic := WeaponDB.is_magic(wid)
	var effective := is_effective(wtype, d)
	var might := int(w["mt"]) * (EFFECTIVE_MULT if effective else 1)
	var atk := (a.stat("mag") if magic else a.stat("str")) + might
	var ch := map.char_at(d_pos)
	var resonance := wtype == "hymn"
	var t_def := 0 if resonance else Terrain.defense(ch)
	var t_avo := 0 if resonance else Terrain.avoid(ch)
	var prot := (d.stat("res") if magic else d.stat("def")) + t_def
	var dmg := maxi(0, atk - prot)
	var steady := wtype == "bow" and not a_moved
	var hit := int(w["hit"]) + a.stat("skl") * 2 + a.stat("lck") / 2 + (STEADY_HIT if steady else 0)
	var avoid := d.stat("spd") * 2 + d.stat("lck") + t_avo
	hit = clampi(hit - avoid, 0, 100)
	var crit := clampi(int(w.get("crit", 0)) + a.stat("skl") / 2 - d.stat("lck"), 0, 100)
	return {
		"dmg": dmg, "hit": hit, "crit": crit, "atk": atk,
		"effective": effective, "steady": steady,
		"resonance": resonance and (Terrain.defense(ch) > 0 or Terrain.avoid(ch) > 0),
	}


static func doubles(a: Unit, wid: String, d: Unit) -> bool:
	var gap := TEMPO_GAP if WeaponDB.type_of(wid) == "sword" else DOUBLE_GAP
	return a.stat("spd") - d.stat("spd") >= gap


## The deterministic shape of a fight: `a` attacks `d` with `wid` from `a_pos`.
static func plan(state: BattleState, a: Unit, wid: String, d: Unit,
		a_pos: Vector2i, a_moved: bool) -> Dictionary:
	var dist := BattleMap.distance(a_pos, d.pos)
	var cw := d.counter_weapon(dist)
	var an := strike_numbers(state.map, a, wid, d, a_pos, d.pos, a_moved)
	var dn := {}
	if cw != "":
		dn = strike_numbers(state.map, d, cw, a, d.pos, a_pos, d.moved)
	var a_x2 := doubles(a, wid, d)
	var d_x2 := cw != "" and doubles(d, cw, a)
	var order: Array[String] = ["a"]
	if cw != "":
		order.append("d")
	if a_x2:
		order.append("a")
	elif d_x2:
		order.append("d")
	return {
		"a": a, "d": d, "a_weapon": wid, "d_weapon": cw,
		"a_num": an, "d_num": dn, "a_doubles": a_x2, "d_doubles": d_x2,
		"order": order, "a_pos": a_pos, "distance": dist,
		"shoves": WeaponDB.type_of(wid) == "axe",
	}


## The plan for `a` attacking from where it stands now.
static func plan_here(state: BattleState, a: Unit, wid: String, d: Unit) -> Dictionary:
	return plan(state, a, wid, d, a.pos, a.moved)


## Read the thread without drawing from it. Each strike gets the bead it would
## draw; strikes on exact beads get a definite outcome. After the first strike
## that isn't certain, later HP is unknown — `certain` goes false and the
## remaining strikes are listed as possible rather than predicted.
static func forecast(state: BattleState, p: Dictionary) -> Dictionary:
	var a: Unit = p["a"]
	var d: Unit = p["d"]
	var hp := {"a": a.hp, "d": d.hp}
	var strikes: Array = []
	var certain := true
	var index := 0
	for who in p["order"]:
		if certain and (hp["a"] <= 0 or hp["d"] <= 0):
			break
		var num: Dictionary = p["a_num"] if who == "a" else p["d_num"]
		var target := "d" if who == "a" else "a"
		var s := {"who": who, "bead_index": index, "hit": num["hit"], "crit": num["crit"],
			"dmg": num["dmg"], "bead": -1, "omen": -1, "outcome": "?"}
		if state.thread.is_visible(index):
			var bead := state.thread.peek(index)
			if state.thread.is_exact(index):
				s["bead"] = bead
			else:
				s["omen"] = FateThread.omen_of(bead)
		if certain and s["bead"] != -1:
			var outcome := FateThread.judge(int(s["bead"]), int(num["hit"]), int(num["crit"]))
			s["outcome"] = outcome
			if outcome != "miss":
				var dealt := int(num["dmg"]) * (CRIT_MULT if outcome == "crit" else 1)
				hp[target] = maxi(0, hp[target] - dealt)
				s["dealt"] = dealt
		else:
			certain = false
		s["target_hp"] = hp[target] if certain else -1
		strikes.append(s)
		index += 1
	return {"strikes": strikes, "a_hp": hp["a"], "d_hp": hp["d"], "certain": certain}


## Fight. Draws one bead per strike and mutates both units (and the
## defender's position, if shoved). Returns everything the view needs to
## replay the fight.
static func resolve(state: BattleState, a: Unit, wid: String, d: Unit) -> Dictionary:
	var p := plan_here(state, a, wid, d)
	var strikes: Array = []
	var a_landed := 0
	for who in p["order"]:
		if not a.is_alive() or not d.is_alive():
			break
		var striker: Unit = a if who == "a" else d
		var target: Unit = d if who == "a" else a
		var num: Dictionary = p["a_num"] if who == "a" else p["d_num"]
		var bead := state.thread.draw()
		var outcome := FateThread.judge(bead, int(num["hit"]), int(num["crit"]))
		var dealt := 0
		if outcome != "miss":
			dealt = int(num["dmg"]) * (CRIT_MULT if outcome == "crit" else 1)
			target.hp = maxi(0, target.hp - dealt)
			if who == "a":
				a_landed += 1
		strikes.append({
			"who": who, "striker": striker.uid, "target": target.uid,
			"bead": bead, "outcome": outcome, "dealt": dealt, "target_hp": target.hp,
			"striker_team": striker.team, "target_team": target.team,
		})
	var shove := {}
	if p["shoves"] and a_landed > 0 and a.is_alive() and d.is_alive():
		var dest := d.pos + (d.pos - a.pos)
		if state.map.in_bounds(dest) \
				and state.map.move_cost(dest, d.move_type()) < Terrain.IMPASSABLE \
				and state.unit_at(dest) == null:
			shove = {"uid": d.uid, "from": d.pos, "to": dest}
			d.pos = dest
	return {
		"a_uid": a.uid, "d_uid": d.uid, "a_weapon": wid, "d_weapon": p["d_weapon"],
		"strikes": strikes, "shove": shove,
		"a_died": not a.is_alive(), "d_died": not d.is_alive(),
	}


## Staff healing: Mag + the staff's heal value, capped at missing HP.
static func heal_amount(healer: Unit, staff_id: String, target: Unit) -> int:
	var amount := healer.stat("mag") + int(WeaponDB.info(staff_id).get("heal", 0))
	return mini(amount, target.max_hp() - target.hp)
