class_name CombatResolver
extends RefCounted
## Single authority for combat rules. Takes a command, validates it against
## the state and, if legal, mutates the state and returns ordered events.
## A rejected command never changes the state.
##
## Command dictionary:
##   id: String      unique per command (idempotency key)
##   peer: int       issuing peer, set by the host - never trusted from payload
##   type: String    "move" | "ability" | "end_phase"
##   unit: String    acting unit id (move / ability)
##   target: Vector2i or [x, y]
##   ability: String ability id (ability)
##
## Result: {"ok": bool, "reason": String, "events": Array[Dictionary]}

const AI_PEER := 0
const CRACK_DAMAGE := 3
const COLLISION_DAMAGE_PER_CELL := 2

var abilities: Dictionary  # id -> AbilityDef


func _init(ability_db: Dictionary) -> void:
	abilities = ability_db


func get_ability(ability_id: String) -> AbilityDef:
	return abilities.get(ability_id) as AbilityDef


static func to_cell(v: Variant) -> Vector2i:
	if v is Vector2i:
		return v
	if v is Vector2:
		return Vector2i(roundi(v.x), roundi(v.y))
	if v is Array and v.size() >= 2:
		return Vector2i(int(v[0]), int(v[1]))
	return Vector2i(-9999, -9999)


func apply(state: CombatState, cmd: Dictionary) -> Dictionary:
	var cmd_id := str(cmd.get("id", ""))
	if cmd_id == "":
		return _reject("missing_id")
	if state.processed_commands.has(cmd_id):
		return _reject("duplicate")
	var err := validate(state, cmd)
	if err != "":
		return _reject(err)
	state.processed_commands[cmd_id] = true
	var events: Array[Dictionary] = []
	match str(cmd["type"]):
		"move":
			_do_move(state, state.get_unit(str(cmd["unit"])), to_cell(cmd["target"]), events)
		"ability":
			_do_ability(state, state.get_unit(str(cmd["unit"])), get_ability(str(cmd["ability"])), to_cell(cmd["target"]), events)
		"end_phase":
			_do_end_phase(state, int(cmd["peer"]), events)
	_check_victory(state, events)
	for e in events:
		e["seq"] = state.next_event_seq()
	return {"ok": true, "reason": "", "events": events}


## Runs the command on a copy of the state. Used for UI previews so that the
## preview is computed by exactly the same rules as the real action.
func preview(state: CombatState, cmd: Dictionary) -> Dictionary:
	var copy := state.clone()
	var c := cmd.duplicate()
	c["id"] = "__preview__"
	copy.processed_commands.erase("__preview__")
	return apply(copy, c)


func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "events": []}


func validate(state: CombatState, cmd: Dictionary) -> String:
	if state.phase == CombatState.Phase.ENDED:
		return "battle_over"
	var type := str(cmd.get("type", ""))
	if not cmd.has("peer"):
		return "missing_peer"
	var peer := int(cmd["peer"])
	if type == "end_phase":
		if state.phase == CombatState.Phase.PLAYERS:
			if not state.player_owners().has(peer):
				return "not_owner"
			if state.ready_owners.has(peer):
				return "already_ready"
		elif peer != AI_PEER:
			return "wrong_phase"
		return ""
	if type != "move" and type != "ability":
		return "unknown_command"
	var unit := state.get_unit(str(cmd.get("unit", "")))
	if unit == null:
		return "unknown_unit"
	if not unit.is_alive():
		return "unit_dead"
	if unit.owner_peer != peer:
		return "not_owner"
	if unit.team != state.phase_team():
		return "wrong_phase"
	if state.phase == CombatState.Phase.PLAYERS and state.ready_owners.has(peer):
		return "already_ready"
	var target := to_cell(cmd.get("target"))
	if not state.in_bounds(target):
		return "invalid_target"
	if type == "move":
		return move_error(state, unit, target)
	var ability := get_ability(str(cmd.get("ability", "")))
	if ability == null or not unit.abilities.has(ability.id):
		return "unknown_ability"
	if unit.ap < ability.ap_cost:
		return "not_enough_ap"
	return ability_target_error(state, unit, ability, target)


func move_error(state: CombatState, unit: CombatUnit, target: Vector2i) -> String:
	if target == unit.pos or not state.is_walkable(target):
		return "invalid_target"
	if unit.mp <= 0:
		return "not_enough_mp"
	var path := CombatRules.find_path(state, unit.pos, target, state.width * state.height)
	if path.is_empty():
		return "unreachable"
	if path.size() > unit.mp:
		return "not_enough_mp"
	return ""


## Target legality ignoring AP (used for range display too).
func ability_target_error(state: CombatState, unit: CombatUnit, ability: AbilityDef, target: Vector2i) -> String:
	if not state.in_bounds(target):
		return "invalid_target"
	var dist := CombatRules.distance(ability.range_metric, unit.pos, target)
	if dist < ability.min_range or dist > ability.max_range:
		return "out_of_range"
	if ability.aim == "line8" and not CombatRules.is_line8(unit.pos, target):
		return "not_in_line"
	if state.is_blocking_terrain(target):
		return "invalid_target"
	var target_unit := state.unit_at(target)
	match ability.target:
		"enemy":
			if target_unit == null or target_unit.team == unit.team:
				return "invalid_target"
		"ally":
			if target_unit == null or target_unit.team != unit.team:
				return "invalid_target"
		"unit":
			if target_unit == null:
				return "invalid_target"
	if ability.needs_los and not CombatRules.has_line_of_sight(state, unit.pos, target):
		return "no_line_of_sight"
	return ""


func _do_move(state: CombatState, unit: CombatUnit, target: Vector2i, events: Array[Dictionary]) -> void:
	var path := CombatRules.find_path(state, unit.pos, target, state.width * state.height)
	for step in path:
		var from := unit.pos
		unit.pos = step
		unit.mp -= 1
		unit.facing = IsoMath.facing_between(from, step)
		events.append({"type": "step", "unit": unit.id, "from": from, "to": step, "mp": unit.mp, "facing": unit.facing})
		_on_enter_cell(state, unit, step, events)
		if not unit.is_alive():
			break


func _do_ability(state: CombatState, caster: CombatUnit, ability: AbilityDef, target: Vector2i, events: Array[Dictionary]) -> void:
	caster.ap -= ability.ap_cost
	if target != caster.pos:
		caster.facing = IsoMath.facing_between(caster.pos, target)
	var cells := CombatRules.area_cells(state, ability.area, target)
	events.append({"type": "ability", "unit": caster.id, "ability": ability.id, "target": target, "cells": cells, "ap": caster.ap, "facing": caster.facing})
	# Snapshot affected units before any push changes positions.
	var affected: Array[CombatUnit] = []
	for c in cells:
		var u := state.unit_at(c)
		if u == null:
			continue
		if u == caster and ability.ward == 0:
			continue
		if u.team == caster.team and ability.is_offensive() and not ability.friendly_fire:
			continue
		if u.team != caster.team and ability.ward > 0:
			continue
		affected.append(u)
	for u in affected:
		if ability.damage > 0:
			_damage(state, u, ability.damage, caster.id, events)
		if ability.push > 0 and u.is_alive():
			_push(state, u, CombatRules.push_direction(caster.pos, u.pos), ability.push, caster.id, events)
		if ability.ward > 0 and u.is_alive():
			u.ward += ability.ward
			events.append({"type": "ward", "unit": u.id, "amount": ability.ward, "ward": u.ward})


func _damage(state: CombatState, unit: CombatUnit, amount: int, source: String, events: Array[Dictionary]) -> void:
	var absorbed := mini(unit.ward, amount)
	unit.ward -= absorbed
	var dealt := amount - absorbed
	unit.hp = maxi(0, unit.hp - dealt)
	events.append({"type": "damage", "unit": unit.id, "amount": dealt, "absorbed": absorbed, "hp": unit.hp, "source": source})
	if unit.hp == 0:
		events.append({"type": "death", "unit": unit.id})


func _push(state: CombatState, unit: CombatUnit, dir: Vector2i, distance: int, source: String, events: Array[Dictionary]) -> void:
	if dir == Vector2i.ZERO:
		return
	for i in distance:
		var next := unit.pos + dir
		var blocked := not state.is_walkable(next)
		if not blocked and dir.x != 0 and dir.y != 0:
			# No squeezing diagonally past a blocked corner.
			blocked = not state.is_walkable(unit.pos + Vector2i(dir.x, 0)) or not state.is_walkable(unit.pos + Vector2i(0, dir.y))
		if blocked:
			var remaining := distance - i
			events.append({"type": "collision", "unit": unit.id, "at": next})
			_damage(state, unit, COLLISION_DAMAGE_PER_CELL * remaining, source, events)
			return
		var from := unit.pos
		unit.pos = next
		events.append({"type": "push", "unit": unit.id, "from": from, "to": next})
		_on_enter_cell(state, unit, next, events)
		if not unit.is_alive():
			return


## CRACK rule (single, documented): a unit takes CRACK_DAMAGE each time it
## enters a crack cell, by walking or by being pushed. Standing still is safe.
func _on_enter_cell(state: CombatState, unit: CombatUnit, cell: Vector2i, events: Array[Dictionary]) -> void:
	if state.get_terrain(cell) == CombatState.Terrain.CRACK:
		events.append({"type": "hazard", "unit": unit.id, "cell": cell, "terrain": "crack"})
		_damage(state, unit, CRACK_DAMAGE, "crack", events)


func _do_end_phase(state: CombatState, peer: int, events: Array[Dictionary]) -> void:
	if state.phase == CombatState.Phase.PLAYERS:
		state.ready_owners[peer] = true
		events.append({"type": "ready", "peer": peer})
		for owner in state.player_owners():
			if not state.ready_owners.has(owner):
				return
		_start_phase(state, CombatState.Phase.ENEMIES, events)
	else:
		state.round_number += 1
		_start_phase(state, CombatState.Phase.PLAYERS, events)


func _start_phase(state: CombatState, phase: int, events: Array[Dictionary]) -> void:
	state.phase = phase
	state.ready_owners.clear()
	var team := state.phase_team()
	for u in state.living_units(team):
		u.ap = u.max_ap
		u.mp = u.max_mp
		u.ward = 0
	events.append({"type": "phase", "phase": phase, "round": state.round_number})


func _check_victory(state: CombatState, events: Array[Dictionary]) -> void:
	if state.phase == CombatState.Phase.ENDED:
		return
	var players_alive := not state.living_units(CombatState.TEAM_PLAYERS).is_empty()
	var enemies_alive := not state.living_units(CombatState.TEAM_ENEMIES).is_empty()
	if players_alive and enemies_alive:
		return
	state.winner = CombatState.TEAM_PLAYERS if players_alive else CombatState.TEAM_ENEMIES
	state.phase = CombatState.Phase.ENDED
	events.append({"type": "battle_end", "winner": state.winner})
