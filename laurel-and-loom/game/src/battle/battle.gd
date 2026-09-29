extends Node2D
## The battle scene's controller: input, the player-phase state machine, the
## enemy phase, and the animations that replay what BattleState decided.
## All rules live in src/core; this file only asks and shows.

signal battle_finished(victory: bool)

enum S { IDLE, SELECTED, ACTION_MENU, WEAPON_MENU, TARGETING, HEAL_TARGETING, MAP_MENU, BUSY, ENEMY, ENDED }

const T := 64.0
const MARGIN_TOP := 96.0
const MARGIN_BOTTOM := 170.0
const MARGIN_SIDE := 32.0
const DIRS := {
	"cursor_up": Vector2i(0, -1), "cursor_down": Vector2i(0, 1),
	"cursor_left": Vector2i(-1, 0), "cursor_right": Vector2i(1, 0),
}

## Which chapter to fight. Set before the node enters the tree.
@export var chapter_id := "prologue"
## Companions carried over from earlier chapters (id → Unit.to_dict()).
var roster := {}

var state: BattleState
var s: int = S.BUSY
var cursor := Vector2i.ZERO

var selected: Unit
var origin := Vector2i.ZERO
var origin_moved := false
var reach := {}
var stands := {}
var targets: Array[Unit] = []
var target_index := 0
var weapon := ""
var danger_on := false
var marked := {}
var history: Array[BattleState] = []
var pending_snapshot: BattleState

var board: BoardView
var overlay: OverlayView
var units_layer: Node2D
var cursor_view: CursorView
var fx_layer: Node2D
var camera: Camera2D
var hud: BattleHud
var views := {}


func _ready() -> void:
	state = BattleSetup.create(chapter_id, roster)
	_build_scene()
	_rebuild_views()
	var lord := state.lord()
	_move_cursor(lord.pos if lord != null else Vector2i.ZERO, true)
	hud.menu.chosen.connect(_on_menu)
	hud.end_menu.chosen.connect(_on_end_menu)
	_refresh()
	await _phase_banner()
	s = S.IDLE
	_refresh()


func _build_scene() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -1
	add_child(bg)
	var bg_rect := ColorRect.new()
	bg_rect.color = Palette.LAPIS_DEEP
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(bg_rect)

	board = BoardView.new()
	add_child(board)
	board.set_map(state.map, state.objective.get("tile", Vector2i(-1, -1)))
	overlay = OverlayView.new()
	add_child(overlay)
	if state.objective.get("type", "") == "seize":
		overlay.seize_tile = state.objective["tile"]
	units_layer = Node2D.new()
	add_child(units_layer)
	cursor_view = CursorView.new()
	add_child(cursor_view)
	fx_layer = Node2D.new()
	fx_layer.z_index = 10
	add_child(fx_layer)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	add_child(camera)
	camera.make_current()
	hud = BattleHud.new()
	add_child(hud)


# --- Views ----------------------------------------------------------------------

func _rebuild_views() -> void:
	for v in views.values():
		v.queue_free()
	views.clear()
	for u in state.units:
		if u.is_alive():
			_make_view(u)


func _make_view(u: Unit) -> UnitView:
	var v := UnitView.new()
	v.setup(u)
	units_layer.add_child(v)
	views[u.uid] = v
	return v


## Snap every view to the state. Only call when nothing is animating.
func _sync_views() -> void:
	for u in state.units:
		var v: UnitView = views.get(u.uid)
		if u.is_alive():
			if v == null:
				v = _make_view(u)
			v.refresh(u)
			v.position = UnitView.tile_center(u.pos)
			v.set_shown_hp(u.hp)
			v.offset = Vector2.ZERO
			v.modulate.a = 1.0
		elif v != null:
			v.queue_free()
			views.erase(u.uid)


# --- Camera and cursor ------------------------------------------------------------

func _view_size() -> Vector2:
	return get_viewport_rect().size


func _clamp_camera(p: Vector2) -> Vector2:
	var view := _view_size()
	var map_px := Vector2(state.map.width, state.map.height) * T
	var out := p
	var min_x := view.x * 0.5 - MARGIN_SIDE
	var max_x := map_px.x - view.x * 0.5 + MARGIN_SIDE
	out.x = map_px.x * 0.5 if min_x > max_x else clampf(p.x, min_x, max_x)
	var min_y := view.y * 0.5 - MARGIN_TOP
	var max_y := map_px.y - view.y * 0.5 + MARGIN_BOTTOM
	out.y = map_px.y * 0.5 + (MARGIN_BOTTOM - MARGIN_TOP) * 0.5 if min_y > max_y else clampf(p.y, min_y, max_y)
	return out


func _focus_camera(tile: Vector2i, instant: bool = false) -> void:
	var view := _view_size()
	var cam := camera.position
	var p := UnitView.tile_center(tile)
	var safe := Rect2(MARGIN_SIDE + T, MARGIN_TOP + T * 0.75,
		view.x - MARGIN_SIDE * 2 - T * 2, view.y - MARGIN_TOP - MARGIN_BOTTOM - T * 1.5)
	var screen := p - (cam - view * 0.5)
	if screen.x < safe.position.x:
		cam.x -= safe.position.x - screen.x
	elif screen.x > safe.end.x:
		cam.x += screen.x - safe.end.x
	if screen.y < safe.position.y:
		cam.y -= safe.position.y - screen.y
	elif screen.y > safe.end.y:
		cam.y += screen.y - safe.end.y
	camera.position = _clamp_camera(cam)
	if instant:
		camera.reset_smoothing()


func _move_cursor(t: Vector2i, instant: bool = false) -> void:
	t = Vector2i(clampi(t.x, 0, state.map.width - 1), clampi(t.y, 0, state.map.height - 1))
	cursor = t
	cursor_view.move_to(t)
	_focus_camera(t, instant)
	if s == S.SELECTED:
		_update_path()
	_refresh_panels()


func _screen_pos(tile: Vector2i) -> Vector2:
	return get_viewport().get_canvas_transform() * (Vector2(tile) * T)


func _mouse_tile() -> Vector2i:
	var p := get_global_mouse_position()
	return Vector2i(floori(p.x / T), floori(p.y / T))


# --- Input ------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if s == S.BUSY or s == S.ENEMY:
		return
	if event is InputEventMouseMotion:
		_on_mouse_motion()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_mouse_click()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("unravel"):
		_on_unravel_key()
	elif event.is_action_pressed("cancel"):
		_cancel()
	elif event.is_action_pressed("confirm"):
		_confirm()
	elif event.is_action_pressed("next_unit"):
		_next_unit()
	elif event.is_action_pressed("toggle_danger"):
		_toggle_danger()
	elif event.is_action_pressed("end_turn") and s == S.IDLE:
		_end_player_phase()
	elif event.is_action_pressed("art_measure"):
		_use_art("measure")
	elif event.is_action_pressed("art_cut"):
		_use_art("cut")
	elif event.is_action_pressed("art_turn"):
		_use_art("turn")
	else:
		for action in DIRS:
			if event.is_action_pressed(action, true):
				_direction(DIRS[action])
				break
		return
	get_viewport().set_input_as_handled()


func _on_mouse_motion() -> void:
	var t := _mouse_tile()
	if not state.map.in_bounds(t) or t == cursor:
		return
	match s:
		S.IDLE, S.SELECTED:
			_move_cursor(t)
		S.TARGETING, S.HEAL_TARGETING:
			for i in targets.size():
				if targets[i].pos == t:
					target_index = i
					_show_target()


func _on_mouse_click() -> void:
	var t := _mouse_tile()
	if not state.map.in_bounds(t):
		return
	match s:
		S.IDLE, S.SELECTED:
			_move_cursor(t)
			_confirm()
		S.TARGETING, S.HEAL_TARGETING:
			for i in targets.size():
				if targets[i].pos == t:
					target_index = i
					_confirm()
					return


func _direction(d: Vector2i) -> void:
	match s:
		S.IDLE, S.SELECTED:
			_move_cursor(cursor + d)
		S.ACTION_MENU, S.WEAPON_MENU, S.MAP_MENU:
			if d.y != 0:
				hud.menu.move(d.y)
		S.TARGETING, S.HEAL_TARGETING:
			if not targets.is_empty():
				target_index = posmod(target_index + (1 if d.x + d.y > 0 else -1), targets.size())
				_show_target()
		S.ENDED:
			if d.y != 0:
				hud.end_menu.move(d.y)


func _confirm() -> void:
	match s:
		S.IDLE:
			_confirm_idle()
		S.SELECTED:
			_confirm_destination()
		S.ACTION_MENU, S.WEAPON_MENU, S.MAP_MENU:
			hud.menu.activate()
		S.TARGETING:
			_execute_attack()
		S.HEAL_TARGETING:
			_execute_heal()
		S.ENDED:
			hud.end_menu.activate()


func _cancel() -> void:
	match s:
		S.IDLE:
			if not marked.is_empty():
				marked.clear()
				_refresh()
		S.SELECTED:
			_deselect()
		S.ACTION_MENU:
			hud.menu.close()
			_undo_move()
		S.WEAPON_MENU:
			_open_action_menu()
		S.TARGETING, S.HEAL_TARGETING:
			hud.hide_forecast()
			overlay.clear_ranges()
			_open_action_menu()
		S.MAP_MENU:
			hud.menu.close()
			s = S.IDLE
			_refresh()


# --- Player phase -----------------------------------------------------------------

func _confirm_idle() -> void:
	var u := state.unit_at(cursor)
	if u != null and u.team == Unit.Team.PLAYER and not u.acted:
		_select(u)
	elif u != null and u.team == Unit.Team.ENEMY:
		if marked.has(u.uid):
			marked.erase(u.uid)
		else:
			marked[u.uid] = true
		_refresh()
	else:
		_open_map_menu()


func _select(u: Unit) -> void:
	selected = u
	origin = u.pos
	origin_moved = u.moved
	pending_snapshot = state.clone()
	reach = Pathfinder.reachable(state, u)
	stands = {}
	for t in Pathfinder.stand_tiles(state, u, reach):
		stands[t] = true
	var stand_list: Array[Vector2i] = []
	stand_list.assign(stands.keys())
	overlay.move_tiles = {}
	for t in reach["cost"]:
		overlay.move_tiles[t] = true
	overlay.attack_tiles = Pathfinder.threat_tiles(state, u, stand_list)
	overlay.heal_tiles = Pathfinder.staff_tiles(state, u, stand_list)
	s = S.SELECTED
	_update_path()
	_refresh()


func _deselect() -> void:
	selected = null
	overlay.clear_ranges()
	s = S.IDLE
	_refresh()


func _update_path() -> void:
	if selected != null and reach["cost"].has(cursor):
		overlay.path = Pathfinder.path_to(reach, cursor)
	else:
		overlay.path = []
	overlay.queue_redraw()


func _confirm_destination() -> void:
	if stands.has(cursor):
		_commit_move(cursor, null)
		return
	# Clicking a foe in reach: walk to the best tile to strike it from.
	var foe := state.unit_at(cursor)
	if foe != null and foe.team != selected.team:
		var best := Vector2i(-1, -1)
		var best_cost := 1 << 30
		for t in stands:
			for w in selected.attack_weapons():
				if WeaponDB.reaches(w, BattleMap.distance(t, foe.pos)):
					var c := int(reach["cost"][t])
					# Prefer the tile the path preview already ends next to.
					if overlay.path.size() > 1 and t == overlay.path[overlay.path.size() - 2]:
						c -= 100
					if c < best_cost:
						best_cost = c
						best = t
		if best.x >= 0:
			_commit_move(best, foe)


func _commit_move(dest: Vector2i, then_target: Unit) -> void:
	s = S.BUSY
	var path := Pathfinder.path_to(reach, dest)
	overlay.clear_ranges()
	await _animate_walk(selected, path)
	state.move_unit(selected, dest)
	_sync_views()
	if then_target != null:
		var ws := _usable_weapons(selected, then_target)
		if not ws.is_empty():
			weapon = ws[0]
			_begin_targeting(then_target)
			return
	_open_action_menu()


func _undo_move() -> void:
	selected.pos = origin
	selected.moved = origin_moved
	_sync_views()
	var u := selected
	_move_cursor(origin)
	_select(u)


func _foes_in_reach(u: Unit, wid: String) -> Array[Unit]:
	var out: Array[Unit] = []
	for f in state.foes_of(u):
		var dist := BattleMap.distance(u.pos, f.pos)
		if wid == "":
			for w in u.attack_weapons():
				if WeaponDB.reaches(w, dist):
					out.append(f)
					break
		elif WeaponDB.reaches(wid, dist):
			out.append(f)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return a.pos.x * 100 + a.pos.y < b.pos.x * 100 + b.pos.y)
	return out


func _usable_weapons(u: Unit, target: Unit = null) -> Array[String]:
	var out: Array[String] = []
	for w in u.attack_weapons():
		if target != null:
			if WeaponDB.reaches(w, BattleMap.distance(u.pos, target.pos)):
				out.append(w)
		elif not _foes_in_reach(u, w).is_empty():
			out.append(w)
	return out


func _heal_targets(u: Unit, staff: String) -> Array[Unit]:
	var out: Array[Unit] = []
	for a in state.allies_of(u):
		if a.is_wounded() and WeaponDB.reaches(staff, BattleMap.distance(u.pos, a.pos)):
			out.append(a)
	return out


func _open_action_menu() -> void:
	var items := []
	if not _foes_in_reach(selected, "").is_empty():
		items.append({"id": "attack", "label": "Attack"})
	for staff in selected.staves():
		if not _heal_targets(selected, staff).is_empty():
			items.append({"id": "heal", "label": "Heal"})
			break
	if state.can_seize(selected):
		items.append({"id": "seize", "label": "Seize"})
	items.append({"id": "wait", "label": "Wait"})
	hud.hide_forecast()
	hud.menu.open(items, _screen_pos(selected.pos) + Vector2(T + 12, -8))
	s = S.ACTION_MENU
	_refresh_hints()


func _open_weapon_menu() -> void:
	var items := []
	for w in _usable_weapons(selected):
		var info := WeaponDB.info(w)
		items.append({"id": w, "label": "%s   Mt %d · Rng %s" % [info["name"], int(info["mt"]), WeaponDB.range_text(w)]})
	hud.menu.open(items, _screen_pos(selected.pos) + Vector2(T + 12, -8))
	s = S.WEAPON_MENU
	_refresh_hints()


func _open_map_menu() -> void:
	var items := [
		{"id": "end", "label": "End Turn"},
		{"id": "danger", "label": "Danger Zone: %s" % ("On" if danger_on else "Off")},
		{"id": "unravel", "label": "Unravel (%d)" % state.unravels_left,
			"enabled": state.unravels_left > 0 and not history.is_empty()},
		{"id": "restart", "label": "Restart Battle"},
	]
	hud.menu.open(items, _screen_pos(cursor) + Vector2(T + 12, -8))
	s = S.MAP_MENU
	_refresh_hints()


func _on_menu(id: String) -> void:
	match s:
		S.ACTION_MENU:
			match id:
				"attack":
					var ws := _usable_weapons(selected)
					if ws.size() > 1:
						_open_weapon_menu()
					else:
						weapon = ws[0]
						_begin_targeting(null)
				"heal":
					weapon = selected.staves()[0]
					_begin_heal_targeting()
				"seize":
					hud.menu.close()
					_commit_action(func() -> void: state.seize(selected))
				"wait":
					hud.menu.close()
					_commit_action(func() -> void: state.wait(selected))
		S.WEAPON_MENU:
			weapon = id
			_begin_targeting(null)
		S.MAP_MENU:
			hud.menu.close()
			s = S.IDLE
			match id:
				"end":
					_end_player_phase()
				"danger":
					_toggle_danger()
				"unravel":
					_unravel()
				"restart":
					get_tree().reload_current_scene()


func _begin_targeting(preselect: Unit) -> void:
	hud.menu.close()
	targets = _foes_in_reach(selected, weapon)
	target_index = maxi(0, targets.find(preselect))
	s = S.TARGETING
	overlay.clear_ranges()
	overlay.attack_tiles = {}
	for t in state.map.tiles_in_range(selected.pos, WeaponDB.min_range(weapon), WeaponDB.max_range(weapon)):
		overlay.attack_tiles[t] = true
	_show_target()
	_refresh_hints()


func _begin_heal_targeting() -> void:
	hud.menu.close()
	targets = _heal_targets(selected, weapon)
	target_index = 0
	s = S.HEAL_TARGETING
	overlay.clear_ranges()
	overlay.heal_tiles = {}
	for t in state.map.tiles_in_range(selected.pos, WeaponDB.min_range(weapon), WeaponDB.max_range(weapon)):
		overlay.heal_tiles[t] = true
	_show_target()
	_refresh_hints()


func _show_target() -> void:
	if targets.is_empty():
		return
	var t := targets[target_index]
	cursor = t.pos
	cursor_view.move_to(t.pos)
	_focus_camera(t.pos)
	overlay.targets = [t.pos]
	overlay.queue_redraw()
	hud.show_unit(t)
	hud.show_terrain(state.map, t.pos)
	if s == S.TARGETING:
		var p := Combat.plan_here(state, selected, weapon, t)
		hud.show_forecast(p, Combat.forecast(state, p))
	else:
		hud.hide_forecast()


func _execute_attack() -> void:
	if targets.is_empty():
		return
	var target := targets[target_index]
	s = S.BUSY
	hud.hide_forecast()
	overlay.clear_ranges()
	history.append(pending_snapshot)
	var result := state.attack(selected, weapon, target)
	await _animate_combat(result)
	await _after_action()


func _execute_heal() -> void:
	if targets.is_empty():
		return
	var target := targets[target_index]
	s = S.BUSY
	overlay.clear_ranges()
	history.append(pending_snapshot)
	var amount := state.heal(selected, weapon, target)
	await _animate_heal(target, amount)
	await _after_action()


func _commit_action(action: Callable) -> void:
	s = S.BUSY
	overlay.clear_ranges()
	history.append(pending_snapshot)
	action.call()
	await _after_action()


func _after_action() -> void:
	selected = null
	_sync_views()
	if state.outcome != BattleState.Outcome.ONGOING:
		await _finish()
		return
	if state.ready_units(Unit.Team.PLAYER).is_empty():
		await _run_enemy_phase()
		return
	s = S.IDLE
	_refresh()


func _next_unit() -> void:
	if s != S.IDLE:
		return
	var ready := state.ready_units(Unit.Team.PLAYER)
	if ready.is_empty():
		return
	var i := 0
	for k in ready.size():
		if ready[k].pos == cursor:
			i = (k + 1) % ready.size()
	_move_cursor(ready[i].pos)


func _toggle_danger() -> void:
	danger_on = not danger_on
	_refresh()


func _end_player_phase() -> void:
	if s != S.IDLE:
		return
	await _run_enemy_phase()


# --- Fate Arts and Unravel (Stage 2) ------------------------------------------------

func _use_art(_art: String) -> void:
	pass


func _on_unravel_key() -> void:
	if s == S.IDLE:
		_unravel()


func _unravel() -> void:
	if history.is_empty() or state.unravels_left <= 0:
		return
	var left := state.unravels_left - 1
	state = history.pop_back()
	state.unravels_left = left
	selected = null
	_rebuild_views()
	overlay.clear_ranges()
	s = S.IDLE
	_refresh()


# --- Enemy phase ----------------------------------------------------------------------

func _run_enemy_phase() -> void:
	s = S.ENEMY
	hud.menu.close()
	hud.hide_forecast()
	overlay.clear_ranges()
	selected = null
	var healed := state.advance_phase()
	_sync_views()
	await _phase_banner()
	await _show_altar_heals(healed)
	for e in state.living(Unit.Team.ENEMY):
		if state.outcome != BattleState.Outcome.ONGOING:
			break
		if not e.is_alive() or e.acted:
			continue
		var plan := EnemyAI.decide(state, e)
		_move_cursor(e.pos)
		var path: Array = plan["path"]
		if path.size() > 1:
			_focus_camera(plan["move"])
			await _animate_walk(e, path)
		state.move_unit(e, plan["move"])
		match plan["action"]:
			"attack":
				var target := state.unit_by_uid(plan["target"])
				_move_cursor(target.pos)
				var result := state.attack(e, plan["weapon"], target)
				await _animate_combat(result)
			"heal":
				var ally := state.unit_by_uid(plan["target"])
				var amount := state.heal(e, plan["weapon"], ally)
				await _animate_heal(ally, amount)
			_:
				state.wait(e)
		_sync_views()
		await get_tree().create_timer(Game.dur(0.1)).timeout
	if state.outcome == BattleState.Outcome.ONGOING:
		healed = state.advance_phase()
	if state.outcome != BattleState.Outcome.ONGOING:
		await _finish()
		return
	_sync_views()
	await _phase_banner()
	await _show_altar_heals(healed)
	var lord := state.lord()
	if lord != null and lord.is_alive():
		_move_cursor(lord.pos)
	s = S.IDLE
	_refresh()


func _phase_banner() -> void:
	hud.set_objective(state.turn, state.objective_text(), state.phase)
	var main := "PLAYER PHASE" if state.phase == Unit.Team.PLAYER else "ENEMY PHASE"
	var tw := hud.show_banner("TURN %s" % UiTheme.roman(state.turn), main, state.phase)
	await tw.finished


func _finish() -> void:
	s = S.ENDED
	hud.menu.close()
	hud.hide_forecast()
	overlay.clear_ranges()
	var victory := state.outcome == BattleState.Outcome.VICTORY
	var sub := ""
	if victory:
		sub = "The field is yours, on turn %s." % UiTheme.roman(state.turn)
	else:
		var lord := state.lord()
		sub = "%s has fallen. The thread is cut." % (lord.name if lord != null else "The Augur")
	hud.show_end(victory, sub, [{"id": "retry", "label": "Fight Again"}])
	battle_finished.emit(victory)


func _on_end_menu(id: String) -> void:
	if id == "retry":
		get_tree().reload_current_scene()


# --- Animation ----------------------------------------------------------------------

func _animate_walk(u: Unit, path: Array) -> void:
	var v: UnitView = views.get(u.uid)
	if v == null or path.size() < 2:
		return
	v.z_index = 2
	for i in range(1, path.size()):
		var tw := create_tween()
		tw.tween_property(v, "position", UnitView.tile_center(path[i]), Game.dur(0.07))
		await tw.finished
	v.z_index = 0


func _animate_combat(result: Dictionary) -> void:
	for strike in result["strikes"]:
		var sv: UnitView = views.get(strike["striker"])
		var tv: UnitView = views.get(strike["target"])
		if sv == null or tv == null:
			continue
		sv.z_index = 2
		var dir := (tv.position - sv.position).normalized()
		var tw := create_tween()
		tw.tween_property(sv, "offset", dir * 18.0, Game.dur(0.10)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw.finished
		match strike["outcome"]:
			"miss":
				_float_text(tv.position, "MISS", Palette.MARBLE, 26)
				var dodge := create_tween()
				dodge.tween_property(tv, "offset", Vector2(-dir.y, dir.x) * 10.0, Game.dur(0.08))
				dodge.tween_property(tv, "offset", Vector2.ZERO, Game.dur(0.10))
			_:
				var crit: bool = strike["outcome"] == "crit"
				if crit:
					_float_text(tv.position + Vector2(0, -22), "CRITICAL", Palette.GOLD, 22)
				_float_text(tv.position, str(int(strike["dealt"])), Palette.POMPEIAN if not crit else Palette.GOLD, 34 if crit else 28)
				tv.flash = 1.0
				var hit := create_tween().set_parallel()
				hit.tween_property(tv, "flash", 0.0, Game.dur(0.25))
				hit.tween_method(tv.set_shown_hp, tv.shown_hp, float(strike["target_hp"]), Game.dur(0.3))
				var shake := create_tween()
				for k in 3:
					shake.tween_property(tv, "offset", dir * (6.0 if crit else 3.5) * (1 if k % 2 == 0 else -1), Game.dur(0.03))
				shake.tween_property(tv, "offset", Vector2.ZERO, Game.dur(0.03))
		var back := create_tween()
		back.tween_property(sv, "offset", Vector2.ZERO, Game.dur(0.12))
		await back.finished
		sv.z_index = 0
		await get_tree().create_timer(Game.dur(0.22)).timeout
	for key in ["a", "d"]:
		if result[key + "_died"]:
			var v: UnitView = views.get(result[key + "_uid"])
			if v != null:
				var fade := create_tween().set_parallel()
				fade.tween_property(v, "modulate:a", 0.0, Game.dur(0.45))
				fade.tween_property(v, "scale", Vector2(1.25, 1.25), Game.dur(0.45))
				await fade.finished
	if not result["shove"].is_empty():
		var v: UnitView = views.get(result["shove"]["uid"])
		if v != null:
			var push := create_tween()
			push.tween_property(v, "position", UnitView.tile_center(result["shove"]["to"]), Game.dur(0.14)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_float_text(v.position, "SHOVED", Palette.MARBLE, 18)
			await push.finished


func _animate_heal(target: Unit, amount: int) -> void:
	var v: UnitView = views.get(target.uid)
	if v == null:
		return
	_float_text(v.position, "+%d" % amount, Palette.VERDIGRIS, 28)
	var tw := create_tween()
	tw.tween_method(v.set_shown_hp, v.shown_hp, float(target.hp), Game.dur(0.35))
	await tw.finished
	await get_tree().create_timer(Game.dur(0.15)).timeout


func _show_altar_heals(healed: Array) -> void:
	for h in healed:
		var u := state.unit_by_uid(h["uid"])
		if u != null:
			await _animate_heal(u, int(h["amount"]))


func _float_text(at: Vector2, text: String, color: Color, size: int) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.display(700))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(160, 40)
	l.position = at - Vector2(80, 44)
	fx_layer.add_child(l)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 26, Game.dur(0.7)).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, Game.dur(0.7)).set_delay(Game.dur(0.35))
	tw.chain().tween_callback(l.queue_free)


# --- Refresh ----------------------------------------------------------------------------

func _refresh() -> void:
	overlay.danger_tiles = Pathfinder.team_threat(state, Unit.Team.ENEMY) if danger_on else {}
	overlay.marked_tiles = {}
	for uid in marked.keys():
		var e := state.unit_by_uid(uid)
		if e == null or not e.is_alive():
			marked.erase(uid)
			continue
		var st: Array[Vector2i] = [e.pos]
		if e.ai != "hold":
			st = Pathfinder.stand_tiles(state, e, Pathfinder.reachable(state, e))
		overlay.marked_tiles.merge(Pathfinder.threat_tiles(state, e, st))
	overlay.queue_redraw()
	hud.set_objective(state.turn, state.objective_text(), state.phase)
	_refresh_panels()
	_refresh_hints()


func _refresh_panels() -> void:
	if s == S.TARGETING or s == S.HEAL_TARGETING:
		return
	var u := state.unit_at(cursor)
	if u == null and selected != null:
		u = selected
	hud.show_unit(u)
	hud.show_terrain(state.map, cursor)


func _refresh_hints() -> void:
	var h := ""
	match s:
		S.IDLE:
			h = "Z select  ·  Tab next  ·  R danger  ·  E end turn"
		S.SELECTED:
			h = "Z move  ·  X cancel"
		S.ACTION_MENU, S.WEAPON_MENU, S.MAP_MENU:
			h = "↑↓ choose  ·  Z confirm  ·  X back"
		S.TARGETING:
			h = "←→ target  ·  Z attack  ·  X back"
		S.HEAL_TARGETING:
			h = "←→ ally  ·  Z heal  ·  X back"
	hud.set_hints(h)
