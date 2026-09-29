class_name FateThread
extends RefCounted
## The Measured Thread: a seeded, deterministic stream of beads (1–100).
## Every strike draws the front bead. See docs/DESIGN.md §5.
##
##   bead > hit   → miss
##   bead <= crit → critical
##   otherwise    → hit

const EXACT := 3   ## Beads shown exactly.
const OMEN := 3    ## Beads after those, shown only as fair / middling / ill.

enum Omen { FAIR, MIDDLING, ILL }

var seed_value: int = 0
## Beads drawn by strikes so far this battle.
var drawn: int = 0
## Measure is active: the omen beads are shown exactly until the phase ends.
var measured: bool = false

var _rng := RandomNumberGenerator.new()
var _buffer: Array[int] = []


func _init(seed_in: int = 0) -> void:
	seed_value = seed_in
	_rng.seed = seed_in


func _fill(n: int) -> void:
	while _buffer.size() < n:
		_buffer.append(_rng.randi_range(1, 100))


## The bead `index` places from the front (0 = next to be drawn).
func peek(index: int) -> int:
	_fill(index + 1)
	return _buffer[index]


func draw() -> int:
	_fill(1)
	drawn += 1
	return _buffer.pop_front()


## Atropos: discard the front bead.
func cut() -> int:
	_fill(1)
	return _buffer.pop_front()


## Rota Fortunae: invert the front bead (b → 101 − b).
func turn() -> int:
	_fill(1)
	_buffer[0] = 101 - _buffer[0]
	return _buffer[0]


func exact_count() -> int:
	return EXACT + (OMEN if measured else 0)


func visible_count() -> int:
	return EXACT + OMEN


func is_exact(index: int) -> bool:
	return index < exact_count()


func is_visible(index: int) -> bool:
	return index < visible_count()


static func omen_of(bead: int) -> int:
	if bead <= 33:
		return Omen.FAIR
	if bead <= 66:
		return Omen.MIDDLING
	return Omen.ILL


static func omen_name(omen: int) -> String:
	return ["Fair", "Middling", "Ill"][omen]


## The bead values an omen stands for, as (lo, hi).
static func omen_range(omen: int) -> Vector2i:
	return [Vector2i(1, 33), Vector2i(34, 66), Vector2i(67, 100)][omen]


## Every outcome a bead somewhere in [lo, hi] could give a strike with shown
## `hit` and `crit`, in the order crit, hit, miss.
static func possible_outcomes(lo: int, hi: int, hit: int, crit: int) -> Array[String]:
	var out: Array[String] = []
	if lo <= mini(hi, mini(crit, hit)):
		out.append("crit")
	if maxi(lo, crit + 1) <= mini(hi, hit):
		out.append("hit")
	if maxi(lo, hit + 1) <= hi:
		out.append("miss")
	return out


## The outcome of a strike with shown `hit` and `crit` that draws `bead`.
static func judge(bead: int, hit: int, crit: int) -> String:
	if bead > hit:
		return "miss"
	if bead <= crit:
		return "crit"
	return "hit"


func clone() -> FateThread:
	var t := FateThread.new(seed_value)
	t._rng.state = _rng.state
	t._buffer = _buffer.duplicate()
	t.drawn = drawn
	t.measured = measured
	return t
