class_name TestCase
extends RefCounted
## Base for test scripts in tests/unit/. Every method named test_* runs once;
## failures are collected rather than thrown so one run reports them all.

var failures: Array[String] = []
var checks: int = 0
var current: String = ""


func check(cond: bool, msg: String = "") -> void:
	checks += 1
	if not cond:
		failures.append("%s: %s" % [current, msg])


func eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	checks += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s: expected %s, got %s %s" % [current, var_to_str(expected), var_to_str(actual), msg])


## A blank plaza map of the given size, for tests that don't care about terrain.
static func plaza(w: int, h: int) -> BattleMap:
	var rows := PackedStringArray()
	for y in h:
		rows.append(".".repeat(w))
	return BattleMap.new(rows)


static func state_on(rows: Array, seed_value: int = 1) -> BattleState:
	return BattleState.new(BattleMap.new(PackedStringArray(rows)), seed_value)
