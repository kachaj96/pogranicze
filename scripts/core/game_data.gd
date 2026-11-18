class_name GameData
extends RefCounted
## Loads static game data (JSON under res://data). Cached per process.
## Export note: data/*.json must be listed in the export include filter.

const ABILITIES_PATH := "res://data/abilities/abilities.json"
const UNITS_PATH := "res://data/units/units.json"
const ENCOUNTERS_DIR := "res://data/encounters/"

static var _json_cache: Dictionary = {}
static var _abilities: Dictionary = {}


static func load_json(path: String) -> Variant:
	if _json_cache.has(path):
		return _json_cache[path]
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		push_error("GameData: cannot read %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("GameData: invalid JSON in %s" % path)
		return null
	_json_cache[path] = parsed
	return parsed


static func abilities() -> Dictionary:
	if _abilities.is_empty():
		var raw: Dictionary = load_json(ABILITIES_PATH)
		for id: String in raw:
			_abilities[id] = AbilityDef.from_dict(id, raw[id])
	return _abilities


static func unit_defs() -> Dictionary:
	return load_json(UNITS_PATH)


static func encounter(encounter_id: String) -> Dictionary:
	return load_json(ENCOUNTERS_DIR + encounter_id + ".json")
