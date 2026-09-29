extends Node
## The main scene: owns whichever screen is showing and runs the campaign —
## title → (story → battle → story) per chapter → the end of the act.
## The campaign is saved after every chapter won.

const BATTLE := preload("res://src/battle/battle.tscn")
const TitleScreen := preload("res://src/ui/title.gd")
const StoryScene := preload("res://src/ui/story_scene.gd")
const SettingsPanel := preload("res://src/ui/settings_panel.gd")
const Ending := preload("res://src/ui/ending.gd")

var campaign: Campaign
var _screen: Node


func _ready() -> void:
	goto_title()


func _swap(next: Node) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)


# --- Title ------------------------------------------------------------------------

func goto_title() -> void:
	var t: Control = TitleScreen.new()
	_swap(t)
	Sound.music("title")
	t.chosen.connect(_on_title_choice)
	_title_menu()


func _title_menu() -> void:
	var items := []
	var saved := Campaign.load_saved()
	if saved != null and not saved.is_finished():
		items.append({"id": "continue", "label": "Continue — %s" % Chapters.data(saved.chapter_id())["numeral"]})
	items.append({"id": "new", "label": "New Campaign"})
	items.append({"id": "settings", "label": "Settings"})
	items.append({"id": "quit", "label": "Quit"})
	_screen.open_menu(items)


func _on_title_choice(id: String) -> void:
	match id:
		"continue":
			campaign = Campaign.load_saved()
			_play_chapter()
		"new":
			_screen.open_menu([
				{"id": "classic", "label": "Classic — the fallen stay fallen"},
				{"id": "casual", "label": "Casual — the fallen return"},
				{"id": "back", "label": "Back"},
			])
		"classic", "casual":
			campaign = Campaign.start(id)
			_play_chapter()
		"back":
			_title_menu()
		"settings":
			_screen.menu.close()
			var p: Control = SettingsPanel.new()
			_screen.add_child(p)
			await p.closed
			_title_menu()
		"quit":
			get_tree().quit()


# --- Campaign -----------------------------------------------------------------------

func _play_chapter() -> void:
	var id := campaign.chapter_id()
	await _story(id + "_pre")
	_start_battle(id)


func _story(scene_id: String) -> void:
	if not Story.has(scene_id):
		return
	var s: Control = StoryScene.new()
	s.scene_id = scene_id
	_swap(s)
	Sound.music("title")
	await s.finished


func _start_battle(id: String) -> void:
	var b: Node = BATTLE.instantiate()
	b.chapter_id = id
	b.roster = campaign.roster
	b.battle_seed = campaign.battle_seed()
	b.in_campaign = true
	b.exit_requested.connect(_on_battle_exit.bind(b))
	_swap(b)


func _on_battle_exit(action: String, b: Node) -> void:
	match action:
		"continue":
			var id := campaign.chapter_id()
			campaign.record_victory(b.state)
			campaign.save()
			await _story(id + "_post")
			if campaign.is_finished():
				_show_ending()
			else:
				_play_chapter()
		"retry":
			_start_battle(campaign.chapter_id())
		_:
			goto_title()


func _show_ending() -> void:
	var e: Control = Ending.new()
	e.campaign = campaign
	_swap(e)
	Sound.music("title")
	await e.done
	goto_title()
