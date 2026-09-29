class_name BattleHud
extends CanvasLayer
## The battle's screen-space interface: unit and terrain panels, the
## objective, the command menu, the combat forecast, the phase banner and the
## end-of-battle screen. The controller owns the logic; this only shows it.

var menu: MenuList
var end_menu: MenuList
var thread_bar: ThreadBar
var fortune: FortunePanel

var _root: Control
var _unit_panel: PanelContainer
var _portrait: CameoPortrait
var _unit_name: Label
var _unit_class: Label
var _unit_hp: HpBar
var _unit_hp_text: Label
var _unit_stats: GridContainer
var _unit_weapons: Label

var _terrain_panel: PanelContainer
var _terrain_name: Label
var _terrain_info: Label

var _objective_turn: Label
var _objective_text: Label
var _objective_panel: PanelContainer

var _forecast: PanelContainer
var _forecast_box: VBoxContainer

var _banner: Control
var _banner_top: Label
var _banner_main: Label

var _end: Control
var _end_title: Label
var _end_sub: Label

var _hints: Label
var _hints_panel: PanelContainer


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.get_theme()
	add_child(_root)
	_build_objective()
	thread_bar = ThreadBar.new()
	_root.add_child(thread_bar)
	fortune = FortunePanel.new()
	_root.add_child(fortune)
	_build_unit_panel()
	_build_terrain_panel()
	_build_forecast()
	_build_hints()
	menu = MenuList.new()
	_root.add_child(menu)
	_build_banner()
	_build_end()
	_root.resized.connect(_layout_top)
	_layout_top.call_deferred()


func _layout_top() -> void:
	var w := _root.size.x
	fortune.reset_size()
	fortune.position = Vector2(w - fortune.size.x - 16, 12)
	thread_bar.size = thread_bar.custom_minimum_size
	var left := 16.0 + maxf(_objective_panel.size.x, 170.0) + 14.0
	var free := fortune.position.x - left
	thread_bar.position = Vector2(left + maxf(0.0, (free - thread_bar.size.x) * 0.5), 12)


# --- Builders ------------------------------------------------------------------

func _panel(anchor: int) -> PanelContainer:
	var p := PanelContainer.new()
	# Panels swallow the mouse so hovering or clicking them doesn't reach the
	# board tiles underneath.
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.set_anchors_preset(anchor)
	_root.add_child(p)
	return p


func _build_objective() -> void:
	_objective_panel = _panel(Control.PRESET_TOP_LEFT)
	_objective_panel.position = Vector2(16, 12)
	_objective_panel.custom_minimum_size = Vector2(170, 96)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_objective_panel.add_child(v)
	_objective_turn = UiTheme.label("TURN I", 22, "display", Palette.INK, 700)
	_objective_text = UiTheme.label("Rout the enemy", 20, "text", Palette.INK_SOFT, 600)
	v.add_child(_objective_turn)
	v.add_child(_objective_text)


func _build_unit_panel() -> void:
	_unit_panel = _panel(Control.PRESET_BOTTOM_LEFT)
	_unit_panel.custom_minimum_size = Vector2(400, 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	_unit_panel.add_child(h)
	_portrait = CameoPortrait.new()
	_portrait.custom_minimum_size = Vector2(96, 96)
	h.add_child(_portrait)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	_unit_name = UiTheme.label("", 22, "display", Palette.INK, 700)
	_unit_class = UiTheme.label("", 18, "text", Palette.INK_SOFT, 600)
	v.add_child(_unit_name)
	v.add_child(_unit_class)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	_unit_hp = HpBar.new()
	_unit_hp.custom_minimum_size = Vector2(150, 10)
	_unit_hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_unit_hp_text = UiTheme.label("", 18, "display", Palette.INK, 600)
	hp_row.add_child(UiTheme.label("HP", 16, "display", Palette.INK_SOFT, 700))
	hp_row.add_child(_unit_hp)
	hp_row.add_child(_unit_hp_text)
	v.add_child(hp_row)
	_unit_stats = GridContainer.new()
	_unit_stats.columns = 4
	_unit_stats.add_theme_constant_override("h_separation", 4)
	_unit_stats.add_theme_constant_override("v_separation", 0)
	v.add_child(_unit_stats)
	_unit_weapons = UiTheme.label("", 17, "text", Palette.INK_SOFT, 600)
	v.add_child(_unit_weapons)
	_unit_panel.visible = false


func _build_terrain_panel() -> void:
	_terrain_panel = _panel(Control.PRESET_BOTTOM_RIGHT)
	_terrain_panel.custom_minimum_size = Vector2(210, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_terrain_panel.add_child(v)
	_terrain_name = UiTheme.label("", 20, "display", Palette.INK, 700)
	_terrain_info = UiTheme.label("", 18, "text", Palette.INK_SOFT, 600)
	v.add_child(_terrain_name)
	v.add_child(_terrain_info)


func _build_forecast() -> void:
	_forecast = _panel(Control.PRESET_CENTER_RIGHT)
	_forecast.custom_minimum_size = Vector2(360, 0)
	_forecast_box = VBoxContainer.new()
	_forecast_box.add_theme_constant_override("separation", 4)
	_forecast.add_child(_forecast_box)
	_forecast.visible = false


func _build_hints() -> void:
	_hints_panel = PanelContainer.new()
	_hints_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.LAPIS_DEEP, 0.88)
	sb.border_color = Color(Palette.GOLD, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 2
	sb.content_margin_bottom = 3
	_hints_panel.add_theme_stylebox_override("panel", sb)
	_hints = UiTheme.label("", 16, "text", Palette.MARBLE, 600)
	_hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hints_panel.add_child(_hints)
	_root.add_child(_hints_panel)


func _build_banner() -> void:
	_banner = Control.new()
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	_root.add_child(_banner)
	var band := ColorRect.new()
	band.name = "Band"
	band.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	band.offset_top = -64
	band.offset_bottom = 64
	band.color = Palette.LAPIS
	_banner.add_child(band)
	for side in [-1, 1]:
		var m := Meander.new()
		m.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
		m.offset_top = -64 if side < 0 else 44
		m.offset_bottom = -44 if side < 0 else 64
		_banner.add_child(m)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -4)
	_banner.add_child(v)
	_banner_top = UiTheme.label("", 20, "display", Palette.GOLD, 600)
	_banner_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_main = UiTheme.label("", 44, "display", Palette.MARBLE, 700)
	_banner_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_banner_top)
	v.add_child(_banner_main)


func _build_end() -> void:
	_end = Control.new()
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.mouse_filter = Control.MOUSE_FILTER_STOP
	_end.visible = false
	_root.add_child(_end)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(Palette.LAPIS_DEEP, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end.add_child(dim)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	_end.add_child(v)
	_end_title = UiTheme.label("", 72, "display", Palette.GOLD, 700)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_sub = UiTheme.label("", 24, "text", Palette.MARBLE, 600)
	_end_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m := Meander.new()
	m.custom_minimum_size = Vector2(420, 18)
	m.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_end_title)
	v.add_child(m)
	v.add_child(_end_sub)
	end_menu = MenuList.new()
	_root.add_child(end_menu)


# --- Updates -------------------------------------------------------------------

## Remove children now (not at frame end) so the container re-measures correctly.
static func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func set_objective(turn: int, text: String, phase_team: int) -> void:
	_objective_turn.text = "TURN %s" % UiTheme.roman(turn)
	_objective_text.text = text
	var sb := UiTheme.panel_box()
	sb.border_color = Palette.GOLD if phase_team == Unit.Team.PLAYER else Palette.TERRACOTTA_DEEP
	_objective_panel.add_theme_stylebox_override("panel", sb)


func show_unit(u: Unit) -> void:
	if u == null:
		_unit_panel.visible = false
		return
	_unit_panel.visible = true
	_portrait.show_unit(u)
	_unit_name.text = u.name.to_upper()
	_unit_name.add_theme_color_override("font_color", Palette.INK if u.team == Unit.Team.PLAYER else Palette.TERRACOTTA_DEEP)
	var role := "  ·  Commander" if u.is_boss else ("  ·  Lord" if u.is_lord else "")
	_unit_class.text = "%s  ·  Level %d%s" % [u.class_name_text(), u.level, role]
	_unit_hp.set_hp(u.hp, u.max_hp())
	_unit_hp_text.text = "%d / %d" % [u.hp, u.max_hp()]
	_clear(_unit_stats)
	for k in ["str", "mag", "skl", "spd", "lck", "def", "res", "mov"]:
		var val := u.move_range() if k == "mov" else u.stat(k)
		var cell := HBoxContainer.new()
		cell.custom_minimum_size = Vector2(66, 0)
		cell.add_theme_constant_override("separation", 5)
		cell.add_child(UiTheme.label(k.capitalize(), 14, "display", Palette.INK_SOFT, 600))
		cell.add_child(UiTheme.label(str(val), 18, "text", Palette.INK, 700))
		_unit_stats.add_child(cell)
	var ws: Array[String] = []
	for w in u.weapons:
		ws.append("%s (%s)" % [WeaponDB.info(w)["name"], WeaponDB.range_text(w)])
	_unit_weapons.text = "  ·  ".join(ws)
	_unit_panel.reset_size()
	_unit_panel.position = Vector2(16, _root.size.y - _unit_panel.size.y - 16)


func show_terrain(map: BattleMap, c: Vector2i) -> void:
	var t := map.terrain(c)
	_terrain_name.text = str(t["name"]).to_upper()
	var parts: Array[String] = []
	parts.append("Avoid %d" % int(t.get("avoid", 0)))
	parts.append("Def %d" % int(t.get("def", 0)))
	if int(t.get("heal", 0)) > 0:
		parts.append("Heals %d%%" % int(t["heal"]))
	if int(t["cost"]["foot"]) >= Terrain.IMPASSABLE:
		parts = ["Impassable"]
	_terrain_info.text = "  ·  ".join(parts)
	_terrain_panel.reset_size()
	_terrain_panel.position = _root.size - _terrain_panel.size - Vector2(16, 16)


func set_hints(text: String) -> void:
	_hints.text = text
	_hints_panel.visible = text != ""
	_hints_panel.reset_size()
	_hints_panel.position = Vector2((_root.size.x - _hints_panel.size.x) * 0.5, _root.size.y - _hints_panel.size.y - 8)


func hide_forecast() -> void:
	_forecast.visible = false


## p: Combat.plan(); fc: Combat.forecast().
func show_forecast(p: Dictionary, fc: Dictionary) -> void:
	_clear(_forecast_box)
	var a: Unit = p["a"]
	var d: Unit = p["d"]
	var head := UiTheme.label("FORECAST", 16, "display", Palette.GOLD_DEEP, 700)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_forecast_box.add_child(head)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	_forecast_box.add_child(cols)
	cols.add_child(_forecast_column(a, p["a_weapon"], p["a_num"], p["a_doubles"], int(fc["a_hp"]), fc["certain"], HORIZONTAL_ALIGNMENT_LEFT))
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vs := UiTheme.label("vs", 18, "text", Palette.INK_SOFT, 600)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(vs)
	cols.add_child(mid)
	cols.add_child(_forecast_column(d, p["d_weapon"], p["d_num"], p["d_doubles"], int(fc["d_hp"]), fc["certain"], HORIZONTAL_ALIGNMENT_RIGHT))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	for st in fc["strikes"]:
		var chip := StrikeChip.new()
		var striker: Unit = a if st["who"] == "a" else d
		chip.setup(st, striker.team, striker.name.get_slice(" ", 0).to_upper())
		row.add_child(chip)
	var rule := Meander.new()
	rule.custom_minimum_size = Vector2(0, 12)
	rule.color = Color(Palette.GOLD, 0.7)
	rule.line_width = 1.5
	_forecast_box.add_child(rule)
	_forecast_box.add_child(row)
	var traits := _trait_notes(p)
	if not traits.is_empty():
		var t := UiTheme.label("  ·  ".join(traits), 16, "text", Palette.INK_SOFT, 600)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(330, 0)
		_forecast_box.add_child(t)
	_forecast.visible = true
	_forecast.reset_size()
	_forecast.position = Vector2(_root.size.x - _forecast.size.x - 16, (_root.size.y - _forecast.size.y) * 0.5)


func _forecast_column(u: Unit, wid: String, num: Dictionary, x2: bool, hp_after: int, certain: bool, align: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.custom_minimum_size = Vector2(140, 0)
	var name_col := Palette.INK if u.team == Unit.Team.PLAYER else Palette.TERRACOTTA_DEEP
	var rows := [
		[u.name.to_upper(), 17, "display", name_col],
		[WeaponDB.info(wid).get("name", "—") if wid != "" else "No counter", 17, "text", Palette.INK_SOFT],
		["HP %d → %s" % [u.hp, str(hp_after) + ("" if certain else "?")], 20, "display", Palette.INK],
	]
	if num.is_empty():
		rows.append(["Dmg —", 18, "text", Palette.INK])
		rows.append(["Hit —", 18, "text", Palette.INK])
		rows.append(["Crit —", 18, "text", Palette.INK])
	else:
		rows.append(["Dmg %d%s" % [int(num["dmg"]), "  ×2" if x2 else ""], 18, "text", Palette.INK])
		rows.append(["Hit %d" % int(num["hit"]), 18, "text", Palette.INK])
		rows.append(["Crit %d" % int(num["crit"]), 18, "text", Palette.INK])
	for r in rows:
		var l := UiTheme.label(str(r[0]), int(r[1]), str(r[2]), r[3], 700 if r[2] == "display" else 600)
		l.horizontal_alignment = align
		v.add_child(l)
	return v


func _trait_notes(p: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var an: Dictionary = p["a_num"]
	var dn: Dictionary = p["d_num"]
	var atype := WeaponDB.type_of(p["a_weapon"])
	if an.get("effective", false):
		out.append("Brace — effective" if atype == "spear" else "Effective")
	if an.get("steady", false):
		out.append("Steady +15 hit")
	if an.get("resonance", false):
		out.append("Resonance — cover ignored")
	if p["a_doubles"] and atype == "sword":
		out.append("Tempo — strikes twice")
	if p["shoves"]:
		out.append("Shove on a hit")
	if not dn.is_empty() and dn.get("effective", false):
		out.append("Foe's counter is effective")
	return out


## Show the phase banner; await its `finished` via the returned tween.
func show_banner(top: String, main: String, team: int) -> Tween:
	_banner_top.text = top
	_banner_main.text = main
	(_banner.get_node("Band") as ColorRect).color = Palette.LAPIS if team == Unit.Team.PLAYER else Palette.TERRACOTTA_DEEP
	_banner.visible = true
	_banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, Game.dur(0.22))
	tw.tween_interval(Game.dur(0.75))
	tw.tween_property(_banner, "modulate:a", 0.0, Game.dur(0.25))
	tw.tween_callback(func() -> void: _banner.visible = false)
	return tw


func show_end(victory: bool, subtitle: String, options: Array) -> void:
	_end_title.text = "VICTORY" if victory else "DEFEAT"
	_end_title.add_theme_color_override("font_color", Palette.GOLD if victory else Palette.TERRACOTTA)
	_end_sub.text = subtitle
	_end.visible = true
	_end.modulate.a = 0.0
	create_tween().tween_property(_end, "modulate:a", 1.0, Game.dur(0.4))
	end_menu.open(options, Vector2(_root.size.x * 0.5 - 90, _root.size.y * 0.5 + 90))


func hide_end() -> void:
	_end.visible = false
	end_menu.close()


func root_size() -> Vector2:
	return _root.size


## A level-up card: the new level and every stat, with the risen ones in
## gold. Dismisses itself.
func show_level_up(u: Unit, lv: Dictionary) -> void:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiTheme.panel_box(Palette.MARBLE, Palette.GOLD, 3))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var portrait := CameoPortrait.new()
	portrait.custom_minimum_size = Vector2(72, 72)
	portrait.show_unit(u)
	head.add_child(portrait)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_child(UiTheme.label(u.name.to_upper(), 24, "display", Palette.INK, 700))
	names.add_child(UiTheme.label("Level %s" % UiTheme.roman(int(lv["level"])), 22, "display", Palette.GOLD_DEEP, 700))
	head.add_child(names)
	v.add_child(head)
	var m := Meander.new()
	m.custom_minimum_size = Vector2(0, 12)
	v.add_child(m)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	var gains: Dictionary = lv["gains"]
	for k in UnitClasses.STAT_KEYS:
		var up := gains.has(k)
		var cell := HBoxContainer.new()
		cell.custom_minimum_size = Vector2(92, 0)
		cell.add_child(UiTheme.label(k.capitalize(), 16, "display", Palette.INK_SOFT, 600))
		cell.add_child(UiTheme.label(str(u.stat(k)), 22, "text", Palette.GOLD_DEEP if up else Palette.INK, 700))
		if up:
			cell.add_child(UiTheme.label("+%d" % int(gains[k]), 18, "display", Palette.GOLD_DEEP, 700))
		grid.add_child(cell)
	v.add_child(grid)
	_root.add_child(card)
	card.reset_size()
	card.position = (_root.size - card.size) * 0.5
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, Game.dur(0.2))
	tw.tween_interval(Game.dur(1.6))
	tw.tween_property(card, "modulate:a", 0.0, Game.dur(0.25))
	tw.tween_callback(card.queue_free)
	await tw.finished


## A full-screen flash that fades out (crits, unravelling).
func flash(color: Color, strength: float) -> void:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(color, strength)
	_root.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.0, Game.dur(0.35))
	tw.tween_callback(r.queue_free)


## "+1 Fortune", floating up beside the wheel.
func fortune_gain(n: int) -> void:
	if n <= 0:
		return
	Sound.play("fortune")
	fortune.celebrate()
	var l := UiTheme.label("+%d FORTUNE" % n, 18, "display", Palette.GOLD, 700)
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", 5)
	_root.add_child(l)
	l.position = fortune.position + Vector2(4, fortune.size.y + 4)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 18, Game.dur(0.9))
	tw.tween_property(l, "modulate:a", 0.0, Game.dur(0.9)).set_delay(Game.dur(0.4))
	tw.chain().tween_callback(l.queue_free)


## A short message across the top of the board ("Not enough Fortune").
func toast(text: String, color: Color = Palette.MARBLE) -> void:
	var l := UiTheme.label(text, 22, "display", color, 700)
	l.add_theme_color_override("font_outline_color", Palette.LAPIS_DEEP)
	l.add_theme_constant_override("outline_size", 7)
	_root.add_child(l)
	l.reset_size()
	l.position = Vector2((_root.size.x - l.size.x) * 0.5, 128)
	var tw := create_tween()
	tw.tween_interval(Game.dur(0.9))
	tw.tween_property(l, "modulate:a", 0.0, Game.dur(0.4))
	tw.tween_callback(l.queue_free)
