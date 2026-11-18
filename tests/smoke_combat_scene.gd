extends SceneTree
## Scene smoke test for the combat prototype (runs headless).
## godot --headless --path . -s res://tests/smoke_combat_scene.gd
## 1) A real mouse click on a reachable cell moves the selected unit.
## 2) The rest of the battle is auto-played through the controller, so every
##    event type goes through the presenter. Must end without hanging.

var _ok := true


func _fail(msg: String) -> void:
	_ok = false
	print("FAIL  ", msg)


func _initialize() -> void:
	Engine.time_scale = 6.0
	change_scene_to_packed(load("res://scenes/combat/combat.tscn"))
	for i in 5:
		await process_frame
	var ctl: CombatController = current_scene
	var hero := ctl.state.get_unit("p0")
	var target := hero.pos + Vector2i(1, 0)
	var screen := ctl.get_canvas_transform() * IsoMath.grid_to_screen(target)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = screen
		root.push_input(ev, true)
		await process_frame
	await create_timer(1.0).timeout
	if hero.pos != target:
		_fail("click did not move hero to %s (at %s)" % [target, hero.pos])
	else:
		print("PASS  mouse click -> move command -> unit at %s, mp=%d" % [hero.pos, hero.mp])
	var guard := 0
	while ctl.state.phase != CombatState.Phase.ENDED and guard < 400:
		guard += 1
		while ctl.busy:
			await process_frame
		if ctl.state.phase != CombatState.Phase.PLAYERS:
			await process_frame
			continue
		var cmd := CombatAI.next_command(ctl.state, ctl.resolver, CombatState.TEAM_PLAYERS)
		if cmd["type"] != "end_phase":
			ctl.selected_id = str(cmd["unit"])
			ctl.mode = "move" if cmd["type"] == "move" else str(cmd["ability"])
		await ctl._submit(cmd)
	if ctl.state.phase != CombatState.Phase.ENDED:
		_fail("battle did not end through the scene (guard=%d)" % guard)
	else:
		print("PASS  battle finished in scene: winner=%d round=%d" % [ctl.state.winner, ctl.state.round_number])
	for uid: String in ctl._unit_views:
		var u := ctl.state.get_unit(uid)
		var v: UnitView = ctl._unit_views[uid]
		if v.position != IsoMath.grid_to_screen(u.pos) or v.visible != u.is_alive() or v.hp != u.hp:
			_fail("view out of sync for %s" % uid)
	print("---- smoke %s" % ("PASS" if _ok else "FAIL"))
	quit(0 if _ok else 1)
