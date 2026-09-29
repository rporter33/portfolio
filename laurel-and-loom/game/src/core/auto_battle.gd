class_name AutoBattle
extends RefCounted
## Plays phases with EnemyAI for whichever side is active. Used by the tests
## to run whole chapters AI-against-AI, and by the enemy phase itself.


## Carry out one AI decision for `u`. Returns the plan with the result added.
static func act(st: BattleState, u: Unit) -> Dictionary:
	var plan := EnemyAI.decide(st, u)
	st.move_unit(u, plan["move"])
	match plan["action"]:
		"attack":
			plan["result"] = st.attack(u, plan["weapon"], st.unit_by_uid(plan["target"]))
		"heal":
			plan["amount"] = st.heal(u, plan["weapon"], st.unit_by_uid(plan["target"]))
		_:
			if st.can_seize(u):
				st.seize(u)
				plan["action"] = "seize"
			else:
				st.wait(u)
	return plan


static func play_phase(st: BattleState) -> void:
	for u in st.living(st.phase):
		if st.outcome != BattleState.Outcome.ONGOING:
			return
		if u.is_alive() and not u.acted:
			act(st, u)


## Play until the battle ends or `max_turns` pass. Returns the outcome.
static func play(st: BattleState, max_turns: int = 40) -> int:
	while st.outcome == BattleState.Outcome.ONGOING and st.turn <= max_turns:
		play_phase(st)
		st.check_outcome()
		st.advance_phase()
	return st.outcome
