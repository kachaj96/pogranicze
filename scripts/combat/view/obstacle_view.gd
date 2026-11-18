class_name ObstacleView
extends Node2D
## Placeholder raised stone block for a WALL cell. Origin = cell centre (foot).

const HEIGHT := 34.0
const COL_TOP := Color("#5d6f70")
const COL_LEFT := Color("#34454a")
const COL_RIGHT := Color("#283539")


func _draw() -> void:
	var hw := IsoMath.HALF_W - 3.0
	var hh := IsoMath.HALF_H - 1.5
	var h := Vector2(0, -HEIGHT)
	var top := Vector2(0, -hh)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + h, left + h]), COL_LEFT)
	draw_colored_polygon(PackedVector2Array([bottom, right, right + h, bottom + h]), COL_RIGHT)
	draw_colored_polygon(PackedVector2Array([top + h, right + h, bottom + h, left + h]), COL_TOP)
	draw_polyline(PackedVector2Array([top + h, right + h, bottom + h, left + h, top + h]), Color(0.09, 0.11, 0.13), 1.0)
