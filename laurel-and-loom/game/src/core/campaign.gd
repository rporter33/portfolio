class_name Campaign
extends RefCounted
## A playthrough of the first act: which chapter is next, the companions as
## they stand (levels, stats), and whether the fallen stay fallen.
## Saved as JSON between chapters.

const VERSION := 1

## Where the campaign is saved. Tests point this elsewhere so they never
## touch a player's real save.
static var save_path := "user://laurel_and_loom.save"

## "classic": a companion who falls is gone for good. "casual": they return
## for the next chapter.
var mode := "classic"
## Index into Chapters.ORDER of the next chapter to play.
var chapter := 0
## Character id → Unit.to_dict(), plus "fallen".
var roster := {}
## Chapter id → the turn it was won on.
var turns := {}
## Mixed into every chapter's seed: each campaign has its own threads, while
## retrying a battle within a campaign replays the same one — the thread can
## be learned.
var seed_value := 0


static func start(play_mode: String, seed_in: int = -1) -> Campaign:
	var c := Campaign.new()
	c.mode = play_mode
	c.seed_value = seed_in if seed_in >= 0 else randi() % 1000000
	return c


## The thread seed for the current chapter in this campaign.
func battle_seed() -> int:
	return absi(hash("%s:%d" % [chapter_id(), seed_value])) % 1000000007


func chapter_id() -> String:
	return Chapters.ORDER[chapter] if chapter < Chapters.ORDER.size() else ""


func is_finished() -> bool:
	return chapter >= Chapters.ORDER.size()


## Fold a won battle back into the roster and move to the next chapter.
func record_victory(st: BattleState) -> void:
	for u in st.units:
		if u.team != Unit.Team.PLAYER:
			continue
		var d := u.to_dict()
		d["fallen"] = mode == "classic" and not u.is_alive()
		roster[u.id] = d
	turns[chapter_id()] = st.turn
	chapter += 1


## The companions still with the party, in roster order.
func living_companions() -> Array:
	var out := []
	for id in roster:
		if not roster[id].get("fallen", false):
			out.append(roster[id])
	return out


func fallen_companions() -> Array:
	var out := []
	for id in roster:
		if roster[id].get("fallen", false):
			out.append(roster[id])
	return out


func to_dict() -> Dictionary:
	return {"version": VERSION, "mode": mode, "chapter": chapter, "seed": seed_value, "roster": roster, "turns": turns}


static func from_dict(d: Dictionary) -> Campaign:
	var c := Campaign.new()
	c.mode = str(d.get("mode", "classic"))
	c.chapter = int(d.get("chapter", 0))
	c.seed_value = int(d.get("seed", 0))
	var r: Dictionary = d.get("roster", {})
	for id in r:
		# JSON hands numbers back as floats; round-trip through Unit to get
		# the same ints a fresh campaign would hold.
		var entry := Unit.from_dict(r[id]).to_dict()
		entry["fallen"] = bool(r[id].get("fallen", false))
		c.roster[str(id)] = entry
	var t: Dictionary = d.get("turns", {})
	for id in t:
		c.turns[str(id)] = int(t[id])
	return c


func save(path: String = "") -> Error:
	path = path if path != "" else save_path
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


static func has_save(path: String = "") -> bool:
	return FileAccess.file_exists(path if path != "" else save_path)


static func load_saved(path: String = "") -> Campaign:
	path = path if path != "" else save_path
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dict(parsed)


static func delete_save(path: String = "") -> void:
	path = path if path != "" else save_path
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
