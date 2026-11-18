extends RefCounted
## Combat rule tests. Pure logic, no scenes.

var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func _resolver() -> CombatResolver:
	return CombatResolver.new(GameData.abilities())


## Empty 8x8 board, hero A at (1,1) owned by peer 1, enemy E at (5,1).
func _small_state() -> CombatState:
	var enc := {
		"id": "test", "width": 8, "height": 8, "walls": [[3, 3]], "cracks": [[6, 1]],
		"players": [
			{"slot": 0, "unit": "wanderer_iron", "pos": [1, 1]},
			{"slot": 1, "unit": "companion_whisper", "pos": [1, 5]},
		],
		"enemies": [{"unit": "split_wolf", "pos": [5, 1]}],
	}
	return CombatSetup.build(enc, GameData.unit_defs(), {0: 1, 1: 1})


var _n := 0


func _cmd(d: Dictionary) -> Dictionary:
	_n += 1
	var c := d.duplicate()
	c["id"] = "t%d" % _n
	if not c.has("peer"):
		c["peer"] = 1
	return c


func _assert_rejected_unchanged(state: CombatState, cmd: Dictionary, reason: String) -> void:
	var before := state.to_dict()
	var res := _resolver().apply(state, cmd)
	check(not res["ok"], "expected rejection '%s' for %s" % [reason, cmd])
	check(res["reason"] == reason, "expected reason '%s', got '%s'" % [reason, res["reason"]])
	check(state.to_dict() == before, "rejected command changed state (%s)" % reason)


func test_iso_projection_roundtrip() -> void:
	for x in range(-3, 12):
		for y in range(-3, 12):
			var c := Vector2i(x, y)
			check(IsoMath.screen_to_grid(IsoMath.grid_to_screen(c)) == c, "roundtrip %s" % c)
			# Points inside the diamond near its edges still map to the same cell.
			var s := IsoMath.grid_to_screen(c)
			check(IsoMath.screen_to_grid(s + Vector2(30, 0)) == c, "inside right %s" % c)
			check(IsoMath.screen_to_grid(s + Vector2(0, -15)) == c, "inside top %s" % c)
	check(IsoMath.grid_to_screen(Vector2i(1, 0)) == Vector2(32, 16), "tile is 64x32 (2:1)")


func test_facing_8_directions() -> void:
	for i in 8:
		check(IsoMath.facing_between(Vector2i(4, 4), Vector2i(4, 4) + IsoMath.GRID_DIRS[i]) == i, "facing %d" % i)


func test_move_is_orthogonal_only() -> void:
	var s := _small_state()
	var r := _resolver()
	# Diagonal neighbour costs 2 MP and the path has no diagonal step.
	var res := r.apply(s, _cmd({"type": "move", "unit": "p0", "target": [2, 2]}))
	check(res["ok"], "diagonal neighbour reachable in 2 steps: %s" % res["reason"])
	var u := s.get_unit("p0")
	check(u.mp == 1, "diagonal neighbour should cost 2 MP, mp=%d" % u.mp)
	for e in res["events"]:
		if e["type"] == "step":
			var d: Vector2i = e["to"] - e["from"]
			check(absi(d.x) + absi(d.y) == 1, "step must be orthogonal, got %s" % d)


func test_move_limits_and_blocking() -> void:
	var s := _small_state()
	# 4 steps away with 3 MP.
	_assert_rejected_unchanged(s, _cmd({"type": "move", "unit": "p0", "target": [1, 5 - 0]}), "invalid_target")  # occupied by ally
	_assert_rejected_unchanged(s, _cmd({"type": "move", "unit": "p0", "target": [5, 1]}), "invalid_target")  # enemy cell
	_assert_rejected_unchanged(s, _cmd({"type": "move", "unit": "p0", "target": [3, 3]}), "invalid_target")  # wall
	_assert_rejected_unchanged(s, _cmd({"type": "move", "unit": "p0", "target": [4, 2]}), "not_enough_mp")
	_assert_rejected_unchanged(s, _cmd({"type": "move", "unit": "p0", "target": [-1, 1]}), "invalid_target")


func test_path_goes_around_wall() -> void:
	var s := _small_state()
	s.get_unit("p0").pos = Vector2i(3, 2)
	s.get_unit("p0").mp = 10
	var path := CombatRules.find_path(s, Vector2i(3, 2), Vector2i(3, 4))
	check(path.size() == 4, "must walk around the wall at (3,3), len=%d" % path.size())
	check(not path.has(Vector2i(3, 3)), "path must not enter wall")


func test_ap_cannot_go_negative() -> void:
	var s := _small_state()
	var r := _resolver()
	var u := s.get_unit("p0")
	s.get_unit("e1").pos = Vector2i(2, 1)
	check(r.apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_strike", "target": [2, 1]}))["ok"], "first strike")
	check(r.apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_strike", "target": [2, 1]}))["ok"], "second strike")
	check(u.ap == 0, "ap should be 0, got %d" % u.ap)
	_assert_rejected_unchanged(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_strike", "target": [2, 1]}), "not_enough_ap")


func test_line_of_sight_blocks_attack() -> void:
	var s := _small_state()
	# Whisper at (3,5), enemy behind the wall (3,3) at (3,1): wall blocks.
	s.get_unit("p1").pos = Vector2i(3, 5)
	s.get_unit("e1").pos = Vector2i(3, 2)
	_assert_rejected_unchanged(s, _cmd({"type": "ability", "unit": "p1", "ability": "whisper_bolt", "target": [3, 2]}), "no_line_of_sight")
	# Same distance in open column has sight.
	s.get_unit("e1").pos = Vector2i(5, 3)
	s.get_unit("p1").pos = Vector2i(5, 6)
	check(CombatRules.has_line_of_sight(s, Vector2i(5, 6), Vector2i(5, 3)), "open column has LoS")


func test_out_of_range_and_wrong_target() -> void:
	var s := _small_state()
	_assert_rejected_unchanged(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_strike", "target": [5, 1]}), "out_of_range")
	_assert_rejected_unchanged(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_strike", "target": [2, 2]}), "invalid_target")
	_assert_rejected_unchanged(s, _cmd({"type": "ability", "unit": "p0", "ability": "whisper_bolt", "target": [5, 1]}), "unknown_ability")


func test_diagonal_strike_allowed() -> void:
	var s := _small_state()
	s.get_unit("e1").pos = Vector2i(2, 2)
	var res := _resolver().apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_strike", "target": [2, 2]}))
	check(res["ok"], "melee can aim diagonally (8 directions): %s" % res["reason"])
	check(s.get_unit("e1").hp == 12 - 5, "strike damage")
	check(s.get_unit("p0").facing == 4, "facing S after diagonal (+1,+1) attack")


func test_push_into_crack_and_wall() -> void:
	var s := _small_state()
	var r := _resolver()
	# Hero at (4,1), wolf at (5,1), crack at (6,1): push 2 -> (6,1) crack then (7,1).
	s.get_unit("p0").pos = Vector2i(4, 1)
	var res := r.apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_shove", "target": [5, 1]}))
	check(res["ok"], "shove ok: %s" % res["reason"])
	var wolf := s.get_unit("e1")
	check(wolf.pos == Vector2i(7, 1), "wolf pushed 2 cells, at %s" % wolf.pos)
	check(wolf.hp == 12 - 1 - CombatResolver.CRACK_DAMAGE, "shove 1 + crack 3, hp=%d" % wolf.hp)
	# Push again: wolf at (7,1) is at the board edge -> collision 2*2.
	s.get_unit("p0").pos = Vector2i(6, 1)
	var hp_before := wolf.hp
	res = r.apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_shove", "target": [7, 1]}))
	check(res["ok"], "second shove ok")
	check(wolf.pos == Vector2i(7, 1), "wolf stays at edge")
	check(wolf.hp == hp_before - 1 - 2 * CombatResolver.COLLISION_DAMAGE_PER_CELL, "collision damage, hp=%d" % wolf.hp)


func test_diagonal_push_no_corner_squeeze() -> void:
	var s := _small_state()
	# Wolf at (2,2) pushed diagonally to (3,3)? (3,3) is a wall -> collision.
	s.get_unit("e1").pos = Vector2i(2, 2)
	s.get_unit("p0").pos = Vector2i(1, 1)
	var res := _resolver().apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_shove", "target": [2, 2]}))
	check(res["ok"], "diag shove ok")
	check(s.get_unit("e1").pos == Vector2i(2, 2), "blocked by wall diagonally")
	# Corner squeeze: walls at (3,2) and open (3,3)->now make (2,3) wall too.
	var s2 := _small_state()
	s2.set_terrain(Vector2i(3, 3), CombatState.Terrain.FLOOR)
	s2.set_terrain(Vector2i(3, 2), CombatState.Terrain.WALL)
	s2.get_unit("e1").pos = Vector2i(2, 2)
	_resolver().apply(s2, _cmd({"type": "ability", "unit": "p0", "ability": "iron_shove", "target": [2, 2]}))
	check(s2.get_unit("e1").pos == Vector2i(2, 2), "cannot squeeze past a blocked corner")


func test_ward_absorbs_damage() -> void:
	var s := _small_state()
	var r := _resolver()
	check(r.apply(s, _cmd({"type": "ability", "unit": "p0", "ability": "iron_guard", "target": [1, 1]}))["ok"], "self ward")
	check(s.get_unit("p0").ward == 5, "ward 5")
	check(r.apply(s, _cmd({"type": "end_phase"}))["ok"], "end players phase")
	s.get_unit("e1").pos = Vector2i(2, 1)
	var res := r.apply(s, {"id": "ai1", "peer": 0, "type": "ability", "unit": "e1", "ability": "wolf_bite", "target": [1, 1]})
	check(res["ok"], "wolf bite: %s" % res["reason"])
	check(s.get_unit("p0").hp == 30, "4 dmg fully absorbed")
	check(s.get_unit("p0").ward == 1, "1 ward left")


func test_duplicate_command_not_executed_twice() -> void:
	var s := _small_state()
	var r := _resolver()
	s.get_unit("e1").pos = Vector2i(2, 1)
	var cmd := {"id": "net-42", "peer": 1, "type": "ability", "unit": "p0", "ability": "iron_strike", "target": [2, 1]}
	check(r.apply(s, cmd)["ok"], "first apply")
	var hp := s.get_unit("e1").hp
	var res := r.apply(s, cmd)
	check(not res["ok"] and res["reason"] == "duplicate", "duplicate rejected")
	check(s.get_unit("e1").hp == hp, "no double damage")


func test_ownership_and_phase() -> void:
	var s := _small_state()
	s.get_unit("p1").owner_peer = 2  # co-op: guest controls p1
	_assert_rejected_unchanged(s, _cmd({"peer": 2, "type": "move", "unit": "p0", "target": [1, 2]}), "not_owner")
	_assert_rejected_unchanged(s, _cmd({"peer": 1, "type": "move", "unit": "e1", "target": [5, 2]}), "not_owner")
	_assert_rejected_unchanged(s, _cmd({"peer": 0, "type": "move", "unit": "e1", "target": [5, 2]}), "wrong_phase")
	var r := _resolver()
	# Both owners must be ready before enemies act.
	check(r.apply(s, _cmd({"peer": 1, "type": "end_phase"}))["ok"], "host ready")
	check(s.phase == CombatState.Phase.PLAYERS, "still players phase while guest not ready")
	_assert_rejected_unchanged(s, _cmd({"peer": 1, "type": "move", "unit": "p0", "target": [1, 2]}), "already_ready")
	check(r.apply(s, _cmd({"peer": 2, "type": "move", "unit": "p1", "target": [1, 6]}))["ok"], "guest still acts")
	check(r.apply(s, _cmd({"peer": 2, "type": "end_phase"}))["ok"], "guest ready")
	check(s.phase == CombatState.Phase.ENEMIES, "enemies phase")
	check(r.apply(s, {"id": "ai-end", "peer": 0, "type": "end_phase"})["ok"], "ai ends")
	check(s.phase == CombatState.Phase.PLAYERS and s.round_number == 2, "round 2")
	check(s.get_unit("p1").mp == 3 and s.get_unit("p1").ap == 6, "points refreshed")


func test_deterministic_replay() -> void:
	var a := _small_state()
	var b := _small_state()
	var r := _resolver()
	var cmds := [
		{"id": "1", "peer": 1, "type": "move", "unit": "p0", "target": [3, 1]},
		{"id": "2", "peer": 1, "type": "ability", "unit": "p0", "ability": "iron_strike", "target": [4, 1]},
		{"id": "3", "peer": 1, "type": "end_phase"},
	]
	for c in cmds:
		r.apply(a, c)
		r.apply(b, c)
	check(a.to_dict() == b.to_dict(), "same commands -> same state")
	var restored := CombatState.from_dict(a.to_dict())
	check(restored.to_dict() == a.to_dict(), "snapshot roundtrip")


func test_preview_matches_and_does_not_mutate() -> void:
	var s := _small_state()
	var r := _resolver()
	s.get_unit("p0").pos = Vector2i(4, 1)
	var before := s.to_dict()
	var cmd := _cmd({"type": "ability", "unit": "p0", "ability": "iron_shove", "target": [5, 1]})
	var pv := r.preview(s, cmd)
	check(s.to_dict() == before, "preview must not change state")
	var real := r.apply(s, cmd)
	check(pv["ok"] == real["ok"] and pv["events"].size() == real["events"].size(), "preview == real outcome")


func test_full_battle_completes() -> void:
	var s := CombatSetup.build(GameData.encounter("forest_clearing"), GameData.unit_defs(), {0: 1, 1: 1})
	var r := _resolver()
	var guard := 0
	while s.phase != CombatState.Phase.ENDED and guard < 2000:
		guard += 1
		var cmd := CombatAI.next_command(s, r, s.phase_team())
		cmd["id"] = "auto%d" % guard
		var res := r.apply(s, cmd)
		if not res["ok"]:
			check(false, "AI produced illegal command %s: %s" % [cmd, res["reason"]])
			return
		for u: CombatUnit in s.units.values():
			check(u.ap >= 0 and u.mp >= 0 and u.hp >= 0, "points never negative")
	check(s.phase == CombatState.Phase.ENDED, "battle ended (commands=%d, round=%d)" % [guard, s.round_number])
	print("        auto-battle: winner=%d rounds=%d commands=%d" % [s.winner, s.round_number, guard])
