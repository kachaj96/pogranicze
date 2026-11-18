class_name AbilityDef
extends RefCounted
## Data definition of a combat ability. Loaded from data/abilities/*.json.

var id: String
var display_name: String
var school: String
var ap_cost: int
var min_range: int
var max_range: int
var range_metric: String  # "manhattan" | "chebyshev"
var needs_los: bool
var aim: String  # "any" | "line8" (straight or diagonal lines only)
var target: String  # "enemy" | "ally" | "unit" | "cell"
var area: String  # "single" | "cross1"
var damage: int
var push: int
var ward: int
var friendly_fire: bool
var description: String


static func from_dict(ability_id: String, d: Dictionary) -> AbilityDef:
	var a := AbilityDef.new()
	a.id = ability_id
	a.display_name = str(d.get("name", ability_id))
	a.school = str(d.get("school", ""))
	a.ap_cost = int(d.get("ap_cost", 3))
	a.min_range = int(d.get("min_range", 1))
	a.max_range = int(d.get("max_range", 1))
	a.range_metric = str(d.get("range_metric", "manhattan"))
	a.needs_los = bool(d.get("needs_los", true))
	a.aim = str(d.get("aim", "any"))
	a.target = str(d.get("target", "enemy"))
	a.area = str(d.get("area", "single"))
	a.damage = int(d.get("damage", 0))
	a.push = int(d.get("push", 0))
	a.ward = int(d.get("ward", 0))
	a.friendly_fire = bool(d.get("friendly_fire", false))
	a.description = str(d.get("description", ""))
	return a


func is_offensive() -> bool:
	return damage > 0 or push > 0
