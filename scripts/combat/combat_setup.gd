class_name CombatSetup
extends RefCounted
## Builds a CombatState from encounter data.


## slot_owners maps player slot (0, 1) to the controlling peer.
## Solo: {0: 1, 1: 1} - one peer controls hero and companion.
## Co-op: {0: host_peer, 1: guest_peer}.
static func build(encounter: Dictionary, unit_defs: Dictionary, slot_owners: Dictionary) -> CombatState:
	var s := CombatState.new()
	s.encounter_id = str(encounter.get("id", ""))
	s.setup_board(int(encounter["width"]), int(encounter["height"]))
	for c in encounter.get("walls", []):
		s.set_terrain(Vector2i(int(c[0]), int(c[1])), CombatState.Terrain.WALL)
	for c in encounter.get("cracks", []):
		s.set_terrain(Vector2i(int(c[0]), int(c[1])), CombatState.Terrain.CRACK)
	var counter := 0
	for entry in encounter.get("players", []):
		var slot := int(entry.get("slot", 0))
		s.add_unit(_make_unit("p%d" % slot, str(entry["unit"]), unit_defs, CombatState.TEAM_PLAYERS, int(slot_owners.get(slot, 1)), entry["pos"]))
	for entry in encounter.get("enemies", []):
		counter += 1
		s.add_unit(_make_unit("e%d" % counter, str(entry["unit"]), unit_defs, CombatState.TEAM_ENEMIES, CombatResolver.AI_PEER, entry["pos"]))
	return s


static func _make_unit(uid: String, def_id: String, unit_defs: Dictionary, team: int, owner: int, pos: Array) -> CombatUnit:
	var d: Dictionary = unit_defs[def_id]
	var u := CombatUnit.new()
	u.id = uid
	u.def_id = def_id
	u.display_name = str(d.get("name", def_id))
	u.team = team
	u.owner_peer = owner
	u.max_hp = int(d["hp"])
	u.hp = u.max_hp
	u.max_ap = int(d["ap"])
	u.ap = u.max_ap
	u.max_mp = int(d["mp"])
	u.mp = u.max_mp
	u.pos = Vector2i(int(pos[0]), int(pos[1]))
	u.facing = 3 if team == CombatState.TEAM_PLAYERS else 7
	for a in d.get("abilities", []):
		u.abilities.append(str(a))
	return u
