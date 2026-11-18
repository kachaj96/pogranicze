class_name CombatState
extends RefCounted
## Pure combat board model: cells, terrain, units, phase, points.
## No rendering, no input. Serializable for snapshots / network / tests.

enum Phase { PLAYERS, ENEMIES, ENDED }
enum Terrain { FLOOR, WALL, CRACK }

const TEAM_PLAYERS := 0
const TEAM_ENEMIES := 1
const NO_WINNER := -1

var encounter_id: String = ""
var width: int = 10
var height: int = 10
var terrain: PackedInt32Array = PackedInt32Array()
var units: Dictionary = {}  # id -> CombatUnit
var unit_order: Array[String] = []
var phase: int = Phase.PLAYERS
var round_number: int = 1
var winner: int = NO_WINNER
var ready_owners: Dictionary = {}  # peer -> true, for the current players phase
var processed_commands: Dictionary = {}  # command id -> true (idempotency)
var event_seq: int = 0


func setup_board(w: int, h: int) -> void:
	width = w
	height = h
	terrain = PackedInt32Array()
	terrain.resize(w * h)
	terrain.fill(Terrain.FLOOR)


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func get_terrain(c: Vector2i) -> int:
	if not in_bounds(c):
		return Terrain.WALL
	return terrain[c.y * width + c.x]


func set_terrain(c: Vector2i, t: int) -> void:
	if in_bounds(c):
		terrain[c.y * width + c.x] = t


## Terrain that blocks movement and line of sight.
func is_blocking_terrain(c: Vector2i) -> bool:
	return get_terrain(c) == Terrain.WALL


func add_unit(u: CombatUnit) -> void:
	units[u.id] = u
	unit_order.append(u.id)


func get_unit(unit_id: String) -> CombatUnit:
	return units.get(unit_id) as CombatUnit


func unit_at(c: Vector2i) -> CombatUnit:
	for uid: String in unit_order:
		var u: CombatUnit = units[uid]
		if u.is_alive() and u.pos == c:
			return u
	return null


func is_walkable(c: Vector2i) -> bool:
	return in_bounds(c) and not is_blocking_terrain(c) and unit_at(c) == null


func living_units(team: int) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for uid: String in unit_order:
		var u: CombatUnit = units[uid]
		if u.team == team and u.is_alive():
			out.append(u)
	return out


func phase_team() -> int:
	return TEAM_PLAYERS if phase == Phase.PLAYERS else TEAM_ENEMIES


## Peers that control at least one living player unit.
func player_owners() -> Array[int]:
	var out: Array[int] = []
	for u in living_units(TEAM_PLAYERS):
		if not out.has(u.owner_peer):
			out.append(u.owner_peer)
	return out


func next_event_seq() -> int:
	event_seq += 1
	return event_seq


func to_dict() -> Dictionary:
	var unit_list: Array = []
	for uid: String in unit_order:
		unit_list.append((units[uid] as CombatUnit).to_dict())
	var ready: Array = ready_owners.keys()
	ready.sort()
	var processed: Array = processed_commands.keys()
	processed.sort()
	return {
		"encounter_id": encounter_id, "width": width, "height": height,
		"terrain": Array(terrain), "units": unit_list, "phase": phase,
		"round": round_number, "winner": winner, "ready_owners": ready,
		"processed_commands": processed, "event_seq": event_seq,
	}


static func from_dict(d: Dictionary) -> CombatState:
	var s := CombatState.new()
	s.encounter_id = str(d.get("encounter_id", ""))
	s.width = int(d["width"])
	s.height = int(d["height"])
	s.terrain = PackedInt32Array()
	for t in d["terrain"]:
		s.terrain.append(int(t))
	for ud in d["units"]:
		s.add_unit(CombatUnit.from_dict(ud))
	s.phase = int(d["phase"])
	s.round_number = int(d["round"])
	s.winner = int(d["winner"])
	for p in d.get("ready_owners", []):
		s.ready_owners[int(p)] = true
	for cid in d.get("processed_commands", []):
		s.processed_commands[str(cid)] = true
	s.event_seq = int(d.get("event_seq", 0))
	return s


func clone() -> CombatState:
	return CombatState.from_dict(to_dict())
