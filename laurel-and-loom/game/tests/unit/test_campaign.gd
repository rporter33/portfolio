extends TestCase
## Progression, reinforcements, the roster and saves.

const TEST_SAVE := "user://test_campaign.save"


func test_level_ups_are_fated() -> void:
	var a := Unit.from_character("ione")
	var b := Unit.from_character("ione")
	var ga := Progression.level_up(a)
	var gb := Progression.level_up(b)
	eq(ga, gb, "the same companion reaching the same level grows the same way")
	eq(a.level, 2)
	for i in 30:
		var u := Unit.from_class("legionary", 1)
		u.id = "test%d" % i
		check(not Progression.level_up(u)["gains"].is_empty(), "a level is never empty")


func test_level_up_raises_hp_with_max() -> void:
	var u := Unit.from_character("oren")  # 90% HP growth
	var before_max := u.max_hp()
	var before_hp := u.hp
	var lv := {}
	for i in 5:
		lv = Progression.level_up(u)
		if lv["gains"].has("hp"):
			break
	check(u.max_hp() > before_max, "HP rose within five levels")
	eq(u.hp - before_hp, u.max_hp() - before_max, "current HP rises with max")


func test_xp_amounts() -> void:
	var ione := Unit.from_character("ione")
	var leg := Unit.from_class("legionary", 1)
	eq(Progression.combat_xp(ione, leg, false, false), 1, "a whiff is worth 1")
	eq(Progression.combat_xp(ione, leg, true, false), 10)
	eq(Progression.combat_xp(ione, leg, true, true), 30)
	var boss := Unit.from_character("bassa")
	check(Progression.combat_xp(ione, boss, true, true) >= 75, "a commander is worth most of a level")


func test_grant_carries_over() -> void:
	var u := Unit.from_character("dama")
	var ups := Progression.grant(u, 250)
	eq(ups.size(), 2)
	eq(u.level, 3)
	eq(u.xp, 50)


func test_combat_awards_xp_to_player_units_only() -> void:
	var st := state_on(["...."], 3)
	var ione := st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(0, 0))
	var leg := st.add_unit(Unit.from_class("legionary", 1), Unit.Team.ENEMY, Vector2i(1, 0))
	var r := st.attack(ione, "gladius", leg)
	eq((r["xp"] as Array).size(), 1)
	eq(int(r["xp"][0]["uid"]), ione.uid)
	check(ione.xp > 0 or ione.level > 1)
	eq(leg.xp, 0)


func test_healing_awards_xp() -> void:
	var st := state_on(["...."], 3)
	var sel := st.add_unit(Unit.from_character("selene"), Unit.Team.PLAYER, Vector2i(0, 0))
	var ione := st.add_unit(Unit.from_character("ione"), Unit.Team.PLAYER, Vector2i(1, 0))
	ione.hp = 5
	var r := st.heal(sel, "caduceus", ione)
	eq(int(r["amount"]), 15, "Mag 6 + 10, capped at the 15 missing")
	eq(sel.xp, Progression.STAFF_XP)


func test_reinforcements_arrive_and_wait_a_turn() -> void:
	var st := BattleSetup.create("ch2")
	var before := st.living(Unit.Team.ENEMY).size()
	st.advance_phase()  # T1 enemy: none due
	eq(st.living(Unit.Team.ENEMY).size(), before)
	st.advance_phase()  # T2 player
	st.advance_phase()  # T2 enemy: two arrive
	eq(st.last_spawned.size(), 2)
	eq(st.living(Unit.Team.ENEMY).size(), before + 2)
	for uid in st.last_spawned:
		check(st.unit_by_uid(uid).acted, "reinforcements don't act on arrival")


func test_clearing_the_field_early_doesnt_win_a_survive_map() -> void:
	var st := BattleSetup.create("ch2")
	for e in st.living(Unit.Team.ENEMY):
		e.hp = 0
	eq(st.check_outcome(), BattleState.Outcome.ONGOING, "reinforcements are still coming")


func _won(id: String, roster: Dictionary, kill: Array = []) -> BattleState:
	var st := BattleSetup.create(id, roster)
	for u in st.units:
		if u.id in kill:
			u.hp = 0
	return st


func test_roster_carries_levels() -> void:
	var c := Campaign.start("casual")
	var st := _won("prologue", c.roster)
	var ione := st.lord()
	Progression.grant(ione, 150)
	c.record_victory(st)
	eq(c.chapter, 1)
	eq(c.chapter_id(), "ch1")
	var next := BattleSetup.create("ch1", c.roster)
	eq(next.lord().level, 2, "Ione keeps her level")
	eq(next.lord().hp, next.lord().max_hp(), "and starts at full health")
	eq(next.lord().xp, 50)


func test_classic_keeps_the_fallen_fallen() -> void:
	var c := Campaign.start("classic")
	c.record_victory(_won("prologue", c.roster, ["cassian"]))
	check(c.roster["cassian"]["fallen"])
	var ch1 := BattleSetup.create("ch1", c.roster)
	for u in ch1.units:
		check(u.id != "cassian", "Cassian doesn't return")
	eq(c.fallen_companions().size(), 1)


func test_casual_brings_them_back() -> void:
	var c := Campaign.start("casual")
	c.record_victory(_won("prologue", c.roster, ["cassian"]))
	check(not c.roster["cassian"]["fallen"])
	var found := false
	for u in BattleSetup.create("ch1", c.roster).units:
		found = found or u.id == "cassian"
	check(found, "Cassian is back")


func test_save_round_trip() -> void:
	var c := Campaign.start("classic", 4242)
	var st := _won("prologue", c.roster)
	Progression.grant(st.lord(), 120)
	c.record_victory(st)
	check(c.save(TEST_SAVE) == OK, "saved")
	var back := Campaign.load_saved(TEST_SAVE)
	check(back != null, "loaded")
	if back == null:
		return
	eq(JSON.stringify(back.to_dict()), JSON.stringify(c.to_dict()), "round trip is exact")
	var a := BattleSetup.create("ch1", c.roster)
	var b := BattleSetup.create("ch1", back.roster)
	for i in a.units.size():
		eq(a.units[i].stats, b.units[i].stats, a.units[i].name)
		eq(a.units[i].level, b.units[i].level, a.units[i].name)
	Campaign.delete_save(TEST_SAVE)
	check(not Campaign.has_save(TEST_SAVE), "deleted")


## Play the whole act AI-against-AI, carrying the roster, to see that it can
## be finished and how hard each chapter is with levelled companions.
func test_the_act_can_be_played_through() -> void:
	var wins := {}
	var finished := 0
	for id in Chapters.ORDER:
		wins[id] = 0
	for seed_value in range(1, 13):
		var c := Campaign.start("casual")
		var tries := 0
		while not c.is_finished() and tries < 12:
			var id := c.chapter_id()
			var st := BattleSetup.create(id, c.roster, seed_value * 100 + tries)
			AutoBattle.play(st, 30)
			tries += 1
			if st.outcome == BattleState.Outcome.VICTORY:
				wins[id] += 1
				c.record_victory(st)
		if c.is_finished():
			finished += 1
	print("    whole act AI-vs-AI, casual, 12 runs: %d finished; first-try-or-later wins per chapter %s" % [finished, wins])
	check(finished >= 9, "the act is finishable (%d of 12 runs)" % finished)


func test_campaign_seeds() -> void:
	var a := Campaign.start("casual", 1)
	var b := Campaign.start("casual", 2)
	check(a.battle_seed() != b.battle_seed(), "campaigns have their own threads")
	eq(a.battle_seed(), Campaign.start("casual", 1).battle_seed(), "a retry replays the same thread")
	var first := a.battle_seed()
	a.chapter = 1
	check(a.battle_seed() != first, "each chapter its own")
