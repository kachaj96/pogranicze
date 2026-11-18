class_name IsoMath
extends RefCounted
## 2:1 isometric projection helpers. Logic always works in grid/world-plane
## coordinates; only presentation converts to screen space.

const TILE_W := 64
const TILE_H := 32
const HALF_W := 32.0
const HALF_H := 16.0

## Facing indices are screen-relative: 0=N 1=NE 2=E 3=SE 4=S 5=SW 6=W 7=NW.
const DIR_NAMES: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
## Grid-space step for each facing index.
const GRID_DIRS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0),
	Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
]
## Orthogonal grid neighbours used for combat movement (no diagonals).
const ORTHO_DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func grid_to_screen(c: Vector2i) -> Vector2:
	return Vector2((c.x - c.y) * HALF_W, (c.x + c.y) * HALF_H)


static func plane_to_screen(p: Vector2) -> Vector2:
	return Vector2((p.x - p.y) * HALF_W, (p.x + p.y) * HALF_H)


static func screen_to_plane(s: Vector2) -> Vector2:
	var a := s.x / HALF_W
	var b := s.y / HALF_H
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## Exact for diamonds centred on grid_to_screen(c).
static func screen_to_grid(s: Vector2) -> Vector2i:
	var p := screen_to_plane(s)
	return Vector2i(roundi(p.x), roundi(p.y))


## Facing index (0..7) from a grid-space delta, snapped to 45 degrees.
static func facing_from_delta(delta: Vector2) -> int:
	if delta.length_squared() < 0.000001:
		return -1
	var step := roundi(atan2(delta.y, delta.x) / (PI / 4.0))
	return posmod(3 + step, 8)


static func facing_between(from: Vector2i, to: Vector2i) -> int:
	return facing_from_delta(Vector2(to - from))


## Screen-space unit vector for a facing index.
static func facing_screen_vector(facing: int) -> Vector2:
	return grid_to_screen(GRID_DIRS[facing]).normalized()
