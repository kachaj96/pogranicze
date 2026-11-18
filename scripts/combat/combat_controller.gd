class_name CombatController
extends Node2D
## Combat scene: owns the CombatState for an offline session, turns input
## into commands, sends them to CombatResolver and plays resulting events.
## Rules are never evaluated here - only through the resolver.
##
## Input: mouse click confirms immediately (hover shows the preview).
## Touch (emulated mouse events): first tap previews, second tap on the same
## cell confirms, "Anuluj" cancels.

const MENU_SCENE := "res://scenes/main/main.tscn"
const COL_REACH := Color(0.35, 0.6, 0.9, 0.28)
const COL_PATH := Color(0.5, 0.78, 1.0, 0.55)
const COL_RANGE := Color(0.95, 0.65, 0.25, 0.32)
const COL_RANGE_EMPTY := Color(0.95, 0.65, 0.25, 0.12)
const COL_NO_LOS := Color(0.45, 0.25, 0.3, 0.45)
const COL_AREA := Color(0.95, 0.3, 0.2, 0.5)
const COL_SELECTED := Color("#e8c86a")
const DRAG_THRESHOLD := 14.0

@export var encounter_id := "forest_clearing"

var state: CombatState
var resolver: CombatResolver
var local_peer := 1
var selected_id := ""
var mode := "move"
var pending_cell: Variant = null
var hover_cell := Vector2i(-99, -99)
var busy := false

var _board: BoardView
var _world: Node2D
var _camera: Camera2D
var _hud: CombatHud
var _unit_views: Dictionary = {}
var _unit_defs: Dictionary
var _cmd_counter := 0
var _press_pos := Vector2.ZERO
var _pressing := false
var _dragging := false
var _touches: Dictionary = {}
var _pinch_start_dist := 0.0
var _pinch_start_zoom := 1.0
var _last_input_touch := false


func _ready() -> void:
	_unit_defs = GameData.unit_defs()
	resolver = CombatResolver.new(GameData.abilities())
	state = CombatSetup.build(GameData.encounter(encounter_id), _unit_defs, {0: local_peer, 1: local_peer})

	_board = BoardView.new()
	_board.state = state
	add_child(_board)
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	for y in state.height:
		for x in state.width:
			var c := Vector2i(x, y)
			if state.get_terrain(c) == CombatState.Terrain.WALL:
				var ob := ObstacleView.new()
				ob.position = IsoMath.grid_to_screen(c)
				_world.add_child(ob)
	for uid: String in state.unit_order:
		var u := state.get_unit(uid)
		var v := UnitView.new()
		v.setup(u, _unit_defs[u.def_id], local_peer)
		v.position = IsoMath.grid_to_screen(u.pos)
		_world.add_child(v)
		_unit_views[uid] = v

	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)

	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = CombatHud.new()
	layer.add_child(_hud)
	_hud.unit_pressed.connect(_select_unit)
	_hud.mode_pressed.connect(_set_mode)
	_hud.end_turn_pressed.connect(_end_turn)
	_hud.cancel_pressed.connect(_cancel)
	_hud.restart_pressed.connect(func() -> void: get_tree().reload_current_scene())
	_hud.menu_pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	_hud.build_units(_local_units())
	_hud.add_log("Walka: %s. Twoja drużyna zaczyna." % str(GameData.encounter(encounter_id).get("name", encounter_id)))
	var mine := _local_units()
	if not mine.is_empty():
		_select_unit(mine[0].id)
	_refresh()


func _local_units() -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for u in state.living_units(CombatState.TEAM_PLAYERS):
		if u.owner_peer == local_peer:
			out.append(u)
	return out


func _fit_camera() -> void:
	var vp := get_viewport_rect().size
	var board_w := float(state.width + state.height) * IsoMath.HALF_W
	var board_h := float(state.width + state.height) * IsoMath.HALF_H + 90.0
	var z := minf(vp.x / (board_w + 80.0), (vp.y - 190.0) / board_h)
	z = clampf(z, 0.6, 3.0)
	_camera.zoom = Vector2(z, z)
	var center := IsoMath.plane_to_screen(Vector2((state.width - 1) * 0.5, (state.height - 1) * 0.5))
	_camera.position = center + Vector2(0, 10)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_touch_drag(event)
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(1.1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(1.0 / 1.1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_dragging = false
				_press_pos = mb.position
			elif _pressing:
				_pressing = false
				if not _dragging and _touches.size() < 2:
					_last_input_touch = mb.device == InputEvent.DEVICE_ID_EMULATION
					_on_cell_clicked(_screen_to_cell(mb.position))
				_dragging = false
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _pressing and (mm.position - _press_pos).length() > DRAG_THRESHOLD and _touches.size() < 2:
			_dragging = true
		if _dragging:
			_camera.position -= mm.relative / _camera.zoom
		elif mm.device != InputEvent.DEVICE_ID_EMULATION:
			var c := _screen_to_cell(mm.position)
			if c != hover_cell:
				hover_cell = c
				_refresh()
		return
	if event.is_action_pressed("cancel"):
		_cancel()
	elif event.is_action_pressed("end_turn"):
		_end_turn()
	elif event.is_action_pressed("mode_move"):
		_set_mode("move")
	elif event.is_action_pressed("next_unit"):
		_cycle_unit()
	else:
		for i in 4:
			if event.is_action_pressed("ability_%d" % (i + 1)):
				var u := state.get_unit(selected_id)
				if u != null and i < u.abilities.size():
					_set_mode(u.abilities[i])


func _handle_touch(t: InputEventScreenTouch) -> void:
	if t.pressed:
		_touches[t.index] = t.position
	else:
		_touches.erase(t.index)
	if _touches.size() == 2:
		var pts: Array = _touches.values()
		_pinch_start_dist = (pts[0] as Vector2).distance_to(pts[1])
		_pinch_start_zoom = _camera.zoom.x
		_dragging = true  # suppress the tap from the emulated mouse


func _handle_touch_drag(d: InputEventScreenDrag) -> void:
	_touches[d.index] = d.position
	if _touches.size() == 2 and _pinch_start_dist > 0.0:
		var pts: Array = _touches.values()
		var dist := (pts[0] as Vector2).distance_to(pts[1])
		var z := clampf(_pinch_start_zoom * dist / _pinch_start_dist, 0.6, 3.0)
		_camera.zoom = Vector2(z, z)


func _zoom_by(f: float) -> void:
	var z := clampf(_camera.zoom.x * f, 0.6, 3.0)
	_camera.zoom = Vector2(z, z)


func _screen_to_cell(screen_pos: Vector2) -> Vector2i:
	var world := get_canvas_transform().affine_inverse() * screen_pos
	return IsoMath.screen_to_grid(world)


# ---------------------------------------------------------------- intents

func _players_turn() -> bool:
	return not busy and state.phase == CombatState.Phase.PLAYERS and not state.ready_owners.has(local_peer)


func _select_unit(uid: String) -> void:
	var u := state.get_unit(uid)
	if u == null or not u.is_alive() or u.owner_peer != local_peer:
		return
	selected_id = uid
	mode = "move"
	pending_cell = null
	_hud.build_modes(u, resolver.abilities)
	_refresh()


func _cycle_unit() -> void:
	var mine := _local_units()
	if mine.is_empty():
		return
	var idx := 0
	for i in mine.size():
		if mine[i].id == selected_id:
			idx = (i + 1) % mine.size()
	_select_unit(mine[idx].id)


func _set_mode(m: String) -> void:
	var u := state.get_unit(selected_id)
	if u == null:
		return
	if m != "move":
		var a := resolver.get_ability(m)
		if a == null or u.ap < a.ap_cost:
			_refresh()
			_hud.show_message(UiText.reason("not_enough_ap"))
			return
	mode = m
	pending_cell = null
	_refresh()


func _cancel() -> void:
	if pending_cell != null:
		pending_cell = null
	else:
		mode = "move"
	_hud.show_message("")
	_refresh()


func _end_turn() -> void:
	if not _players_turn():
		return
	_submit({"type": "end_phase"})


func _build_command(cell: Vector2i) -> Dictionary:
	if selected_id == "":
		return {}
	if mode == "move":
		return {"type": "move", "unit": selected_id, "target": cell, "peer": local_peer}
	return {"type": "ability", "unit": selected_id, "ability": mode, "target": cell, "peer": local_peer}


func _on_cell_clicked(cell: Vector2i) -> void:
	if not _players_turn() or not state.in_bounds(cell):
		return
	var cmd := _build_command(cell)
	if cmd.is_empty():
		return
	var err := resolver.validate(state, cmd)
	var clicked := state.unit_at(cell)
	if err != "" and clicked != null and clicked.owner_peer == local_peer and clicked.team == CombatState.TEAM_PLAYERS:
		_select_unit(clicked.id)
		return
	if err != "":
		pending_cell = null
		_refresh()
		_hud.show_message(UiText.reason(err))
		return
	if _last_input_touch and pending_cell != cell:
		pending_cell = cell
		_refresh()
		_hud.show_message(_hud_preview_text(cell) + "   Dotknij ponownie, aby potwierdzić.")
		return
	_submit(cmd)


func _submit(cmd: Dictionary) -> void:
	_cmd_counter += 1
	cmd["id"] = "L%d-%d" % [local_peer, _cmd_counter]
	cmd["peer"] = local_peer
	var res := resolver.apply(state, cmd)
	if not res["ok"]:
		_hud.show_message(UiText.reason(res["reason"]))
		return
	pending_cell = null
	_hud.show_message("")
	await _play(res["events"])
	if state.phase == CombatState.Phase.ENEMIES:
		await _run_enemy_phase()
	var u := state.get_unit(selected_id)
	if u == null or not u.is_alive():
		var mine := _local_units()
		selected_id = mine[0].id if not mine.is_empty() else ""
	if selected_id != "":
		var su := state.get_unit(selected_id)
		if mode != "move" and su.ap < resolver.get_ability(mode).ap_cost:
			mode = "move"
		_hud.build_modes(su, resolver.abilities)
	_refresh()


func _run_enemy_phase() -> void:
	busy = true
	_refresh()
	var guard := 0
	while state.phase == CombatState.Phase.ENEMIES and guard < 300:
		guard += 1
		var cmd := CombatAI.next_command(state, resolver, CombatState.TEAM_ENEMIES)
		cmd["id"] = "AI-%d-%d" % [state.round_number, guard]
		var res := resolver.apply(state, cmd)
		if not res["ok"]:
			push_error("AI command rejected: %s %s" % [cmd, res["reason"]])
			res = resolver.apply(state, {"id": "AI-force-%d-%d" % [state.round_number, guard], "peer": CombatResolver.AI_PEER, "type": "end_phase"})
		await _play(res["events"])
		await get_tree().create_timer(0.12).timeout
	busy = false


# ---------------------------------------------------------------- presentation

func _play(events: Array) -> void:
	busy = true
	_refresh_overlays_only()
	for e: Dictionary in events:
		await _play_event(e)
	for uid: String in _unit_views:
		var u := state.get_unit(uid)
		var v: UnitView = _unit_views[uid]
		v.sync(u)
		v.position = IsoMath.grid_to_screen(u.pos)
		v.visible = u.is_alive()
	busy = false


func _unit_name(uid: String) -> String:
	var u := state.get_unit(uid)
	return u.display_name if u != null else uid


func _float(uid: String, text: String, color: Color) -> void:
	var v: UnitView = _unit_views.get(uid)
	if v == null:
		return
	var f := FloatText.new()
	f.text = text
	f.color = color
	f.position = v.position + Vector2(0, -92)
	_world.add_child(f)


func _play_event(e: Dictionary) -> void:
	var v: UnitView = _unit_views.get(str(e.get("unit", "")))
	match str(e["type"]):
		"step", "push":
			if e["type"] == "step":
				v.facing = int(e["facing"])
			var tw := create_tween()
			tw.tween_property(v, "position", IsoMath.grid_to_screen(e["to"]), 0.13 if e["type"] == "step" else 0.1)
			await tw.finished
		"ability":
			var a := resolver.get_ability(str(e["ability"]))
			v.facing = int(e["facing"])
			_hud.add_log("%s: %s" % [_unit_name(e["unit"]), a.display_name])
			var dir := (IsoMath.grid_to_screen(e["target"]) - v.position).normalized() * 8.0
			var tw := create_tween()
			tw.tween_property(v, "body_offset", dir, 0.08)
			tw.tween_property(v, "body_offset", Vector2.ZERO, 0.1)
			_board.flash(e["cells"], COL_AREA if a.ward == 0 else Color(0.5, 0.9, 1.0, 0.45), 0.22)
			await tw.finished
		"damage":
			var txt := "-%d" % int(e["amount"])
			if int(e["absorbed"]) > 0:
				txt += " (osł. %d)" % int(e["absorbed"])
			_float(e["unit"], txt, Color("#ff8a70"))
			v.hp = int(e["hp"])
			v.queue_redraw()
			_hud.add_log("  %s: -%d PŻ (%d)" % [_unit_name(e["unit"]), int(e["amount"]), int(e["hp"])])
			await get_tree().create_timer(0.18).timeout
		"hazard":
			_float(e["unit"], "Szczelina!", Color("#d0a0e0"))
			await get_tree().create_timer(0.1).timeout
		"collision":
			_float(e["unit"], "Zderzenie!", Color("#f0d080"))
			await get_tree().create_timer(0.1).timeout
		"ward":
			_float(e["unit"], "+%d osłony" % int(e["amount"]), Color("#8fe0f0"))
			v.ward = int(e["ward"])
			v.queue_redraw()
			await get_tree().create_timer(0.15).timeout
		"death":
			_hud.add_log("  %s pada." % _unit_name(e["unit"]))
			var tw := create_tween()
			tw.tween_property(v, "modulate:a", 0.0, 0.35)
			await tw.finished
			v.visible = false
			v.modulate.a = 1.0
		"phase":
			if int(e["phase"]) == CombatState.Phase.ENEMIES:
				_hud.show_banner("Faza wrogów")
			else:
				_hud.show_banner("Runda %d - Twoja drużyna" % int(e["round"]))
			await get_tree().create_timer(0.5).timeout
		"battle_end":
			var won := int(e["winner"]) == CombatState.TEAM_PLAYERS
			_hud.add_log("Zwycięstwo!" if won else "Drużyna poległa.")
			_hud.show_end(won)


func _refresh_overlays_only() -> void:
	_board.overlays.clear()
	_board.outlines.clear()
	for uid: String in _unit_views:
		(_unit_views[uid] as UnitView).selected = false
		(_unit_views[uid] as UnitView).queue_redraw()
	_board.queue_redraw()


func _focus_cell() -> Variant:
	if pending_cell != null:
		return pending_cell
	if state.in_bounds(hover_cell):
		return hover_cell
	return null


func _refresh() -> void:
	_refresh_overlays_only()
	var u := state.get_unit(selected_id)
	var players_turn := _players_turn()
	_hud.update_selection(selected_id, mode, players_turn, players_turn)
	_hud.set_status(_status_text(u))
	if u == null or not u.is_alive():
		return
	var uv: UnitView = _unit_views[selected_id]
	uv.selected = true
	uv.queue_redraw()
	if not players_turn:
		return
	var focus: Variant = _focus_cell()
	if mode == "move":
		var reach := CombatRules.reachable_cells(state, u.pos, u.mp)
		for c: Vector2i in reach:
			_board.overlays[c] = COL_REACH
		if focus != null and reach.has(focus):
			for c in CombatRules.find_path(state, u.pos, focus, u.mp):
				_board.overlays[c] = COL_PATH
	else:
		var a := resolver.get_ability(mode)
		for y in state.height:
			for x in state.width:
				var c := Vector2i(x, y)
				var err := resolver.ability_target_error(state, u, a, c)
				if err == "":
					_board.overlays[c] = COL_RANGE
				elif err == "no_line_of_sight":
					_board.overlays[c] = COL_NO_LOS
				elif err == "invalid_target" and not state.is_blocking_terrain(c):
					_board.overlays[c] = COL_RANGE_EMPTY
		if focus != null and resolver.ability_target_error(state, u, a, focus) == "":
			for c in CombatRules.area_cells(state, a.area, focus):
				_board.overlays[c] = COL_AREA
	if focus != null:
		_board.outlines[focus] = COL_SELECTED
		if pending_cell == null:
			_hud.show_message(_hud_preview_text(focus))


## Preview text computed by running the real resolver on a copy of the state.
func _hud_preview_text(cell: Vector2i) -> String:
	var cmd := _build_command(cell)
	if cmd.is_empty():
		return ""
	var res := resolver.preview(state, cmd)
	if not res["ok"]:
		return "" if mode == "move" else UiText.reason(res["reason"])
	var parts: Array[String] = []
	var steps := 0
	for e: Dictionary in res["events"]:
		match str(e["type"]):
			"step":
				steps += 1
			"damage":
				parts.append("%s -%d (zostanie %d)" % [_unit_name(e["unit"]), int(e["amount"]), int(e["hp"])])
			"push":
				pass
			"collision":
				parts.append("%s uderzy w przeszkodę" % _unit_name(e["unit"]))
			"hazard":
				parts.append("%s wejdzie na szczelinę" % _unit_name(e["unit"]))
			"ward":
				parts.append("%s +%d osłony" % [_unit_name(e["unit"]), int(e["amount"])])
			"death":
				parts.append("%s padnie" % _unit_name(e["unit"]))
	if mode == "move":
		parts.push_front("Ruch: %d PR" % steps)
	else:
		parts.push_front("%s (%d PA)" % [resolver.get_ability(mode).display_name, resolver.get_ability(mode).ap_cost])
	return " | ".join(parts)


func _status_text(u: CombatUnit) -> String:
	var phase_txt := "Twoja drużyna" if state.phase == CombatState.Phase.PLAYERS else ("Wrogowie" if state.phase == CombatState.Phase.ENEMIES else "Koniec")
	var lines: Array[String] = ["Runda %d - %s" % [state.round_number, phase_txt]]
	if u != null:
		lines.append("%s  PŻ %d/%d" % [u.display_name, u.hp, u.max_hp])
		lines.append("PA %d/%d   PR %d/%d%s" % [u.ap, u.max_ap, u.mp, u.max_mp, ("   Osłona %d" % u.ward) if u.ward > 0 else ""])
	lines.append("Tab: postać  1-4: umiejętności  M: ruch")
	return "\n".join(lines)
