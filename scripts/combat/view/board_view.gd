class_name BoardView
extends Node2D
## Draws the combat floor (placeholder art) and gameplay overlays.
## Reads CombatState, never changes it.

const COL_FLOOR_A := Color("#3e5340")
const COL_FLOOR_B := Color("#45593f")
const COL_GRID := Color(0.09, 0.11, 0.13, 0.6)
const COL_CRACK := Color("#5a4660")
const COL_CRACK_LINE := Color("#c9a0d0")

var state: CombatState
var overlays: Dictionary = {}  # Vector2i -> Color (fill)
var outlines: Dictionary = {}  # Vector2i -> Color (thick outline)
var _flash_cells: Array[Vector2i] = []
var _flash_color := Color(1, 1, 1, 0)


static func diamond(c: Vector2i, inset: float = 0.0) -> PackedVector2Array:
	var p := IsoMath.grid_to_screen(c)
	var hw := IsoMath.HALF_W - inset * 2.0
	var hh := IsoMath.HALF_H - inset
	return PackedVector2Array([p + Vector2(0, -hh), p + Vector2(hw, 0), p + Vector2(0, hh), p + Vector2(-hw, 0)])


func _draw() -> void:
	if state == null:
		return
	for y in state.height:
		for x in state.width:
			var c := Vector2i(x, y)
			var poly := diamond(c)
			var t := state.get_terrain(c)
			var base := COL_FLOOR_A if (x * 7 + y * 13) % 3 != 0 else COL_FLOOR_B
			if t == CombatState.Terrain.CRACK:
				base = COL_CRACK
			draw_colored_polygon(poly, base)
			if t == CombatState.Terrain.CRACK:
				var p := IsoMath.grid_to_screen(c)
				draw_polyline(PackedVector2Array([p + Vector2(-18, -2), p + Vector2(-6, 3), p + Vector2(2, -4), p + Vector2(10, 2), p + Vector2(19, -1)]), COL_CRACK_LINE, 2.0)
			var closed := poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, COL_GRID, 1.0)
	for c: Vector2i in overlays:
		draw_colored_polygon(diamond(c, 1.0), overlays[c])
	for c in _flash_cells:
		draw_colored_polygon(diamond(c, 1.0), _flash_color)
	for c: Vector2i in outlines:
		var poly := diamond(c, 1.5)
		poly.append(poly[0])
		draw_polyline(poly, outlines[c], 2.5)


func flash(cells: Array, color: Color, duration: float) -> void:
	_flash_cells.clear()
	for c in cells:
		_flash_cells.append(c)
	_flash_color = color
	queue_redraw()
	await get_tree().create_timer(duration).timeout
	_flash_cells.clear()
	queue_redraw()
