class_name CombatUnit
extends RefCounted
## A unit inside a CombatState. Pure data, no nodes.

var id: String
var def_id: String
var display_name: String
var team: int
var owner_peer: int
var max_hp: int
var hp: int
var max_ap: int
var ap: int
var max_mp: int
var mp: int
var pos: Vector2i
var facing: int = 3
var ward: int = 0
var abilities: Array[String] = []


func is_alive() -> bool:
	return hp > 0


func to_dict() -> Dictionary:
	return {
		"id": id, "def_id": def_id, "name": display_name, "team": team,
		"owner_peer": owner_peer, "max_hp": max_hp, "hp": hp,
		"max_ap": max_ap, "ap": ap, "max_mp": max_mp, "mp": mp,
		"pos": [pos.x, pos.y], "facing": facing, "ward": ward,
		"abilities": abilities.duplicate(),
	}


static func from_dict(d: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = str(d["id"])
	u.def_id = str(d.get("def_id", ""))
	u.display_name = str(d.get("name", u.id))
	u.team = int(d["team"])
	u.owner_peer = int(d.get("owner_peer", 0))
	u.max_hp = int(d["max_hp"])
	u.hp = int(d["hp"])
	u.max_ap = int(d["max_ap"])
	u.ap = int(d["ap"])
	u.max_mp = int(d["max_mp"])
	u.mp = int(d["mp"])
	u.pos = Vector2i(int(d["pos"][0]), int(d["pos"][1]))
	u.facing = int(d.get("facing", 3))
	u.ward = int(d.get("ward", 0))
	for a in d.get("abilities", []):
		u.abilities.append(str(a))
	return u
