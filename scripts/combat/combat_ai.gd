class_name CombatAI
extends RefCounted
## Simple deterministic AI. Produces one command at a time for `team`.
## Works for any team, so tests can auto-play the player side as well.
## The AI never mutates the state permanently: every action goes through
## CombatResolver like a player command.


## Returns a command without "id" (the caller assigns ids). If no unit of the
## team can do anything useful, returns an end_phase command.
static func next_command(state: CombatState, resolver: CombatResolver, team: int) -> Dictionary:
	for u in state.living_units(team):
		if team == CombatState.TEAM_PLAYERS and state.ready_owners.has(u.owner_peer):
			continue
		var cmd := _decide(state, resolver, u)
		if not cmd.is_empty():
			return cmd
	var peer := CombatResolver.AI_PEER
	if team == CombatState.TEAM_PLAYERS:
		for owner in state.player_owners():
			if not state.ready_owners.has(owner):
				peer = owner
				break
	return {"type": "end_phase", "peer": peer}


static func _decide(state: CombatState, resolver: CombatResolver, u: CombatUnit) -> Dictionary:
	var attack := _best_attack(state, resolver, u)
	if not attack.is_empty():
		return attack
	if u.mp <= 0:
		return {}
	var reach := CombatRules.reachable_cells(state, u.pos, u.mp)
	if reach.is_empty():
		return {}
	# 1) Closest reachable cell from which an attack becomes possible.
	var origin := u.pos
	var best_cell := Vector2i(-1, -1)
	var best_key := Vector2i(1 << 20, 1 << 20)
	for cell: Vector2i in reach:
		u.pos = cell
		var can_attack := not _best_attack(state, resolver, u).is_empty()
		u.pos = origin
		if can_attack:
			var key := Vector2i(int(reach[cell]["cracks"]), int(reach[cell]["steps"]))
			if key.x < best_key.x or (key.x == best_key.x and key.y < best_key.y):
				best_key = key
				best_cell = cell
	if best_cell.x >= 0:
		return _move_cmd(u, best_cell)
	# 2) Otherwise approach the nearest opponent, avoiding cracks.
	var current := _distance_to_nearest_opponent(state, u, origin)
	var best_score := current * 10
	best_cell = Vector2i(-1, -1)
	for cell: Vector2i in reach:
		var score: int = _distance_to_nearest_opponent(state, u, cell) * 10 + int(reach[cell]["cracks"]) * 15
		if score < best_score:
			best_score = score
			best_cell = cell
	if best_cell.x >= 0:
		return _move_cmd(u, best_cell)
	return {}


static func _move_cmd(u: CombatUnit, cell: Vector2i) -> Dictionary:
	return {"type": "move", "peer": u.owner_peer, "unit": u.id, "target": cell}


static func _best_attack(state: CombatState, resolver: CombatResolver, u: CombatUnit) -> Dictionary:
	var best := {}
	var best_score := 0
	var opponents := state.living_units(CombatState.TEAM_ENEMIES if u.team == CombatState.TEAM_PLAYERS else CombatState.TEAM_PLAYERS)
	for ability_id in u.abilities:
		var ability := resolver.get_ability(ability_id)
		if ability == null or not ability.is_offensive() or u.ap < ability.ap_cost:
			continue
		for opp in opponents:
			if resolver.ability_target_error(state, u, ability, opp.pos) != "":
				continue
			var score := ability.damage * 10 + ability.push * 4
			if opp.hp <= ability.damage:
				score += 50
			if score > best_score:
				best_score = score
				best = {"type": "ability", "peer": u.owner_peer, "unit": u.id, "ability": ability_id, "target": opp.pos}
	return best


static func _distance_to_nearest_opponent(state: CombatState, u: CombatUnit, from: Vector2i) -> int:
	var opp_team := CombatState.TEAM_ENEMIES if u.team == CombatState.TEAM_PLAYERS else CombatState.TEAM_PLAYERS
	var best := 1 << 20
	for opp in state.living_units(opp_team):
		best = mini(best, CombatRules.distance("manhattan", from, opp.pos))
	return best
