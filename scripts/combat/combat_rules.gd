class_name CombatRules
extends RefCounted
## Stateless geometry rules for the combat grid: distance, line of sight,
## 4-neighbour pathfinding and ability areas.

const CRACK_PATH_PENALTY := 1  # tie-breaker only; MP cost is always 1 per step


static func distance(metric: String, a: Vector2i, b: Vector2i) -> int:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	if metric == "chebyshev":
		return maxi(dx, dy)
	return dx + dy


## True if b lies on one of the 8 straight/diagonal lines from a.
static func is_line8(a: Vector2i, b: Vector2i) -> bool:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	return dx == 0 or dy == 0 or dx == dy


static func _blocks_sight(state: CombatState, c: Vector2i) -> bool:
	return state.is_blocking_terrain(c) or state.unit_at(c) != null


## Line of sight between cell centres. Walls and living units on intermediate
## cells block. A line passing exactly through a corner is blocked only if
## both cells touching that corner block.
static func has_line_of_sight(state: CombatState, a: Vector2i, b: Vector2i) -> bool:
	if a == b:
		return true
	var dx := b.x - a.x
	var dy := b.y - a.y
	var nx := absi(dx)
	var ny := absi(dy)
	var sx := signi(dx)
	var sy := signi(dy)
	var x := a.x
	var y := a.y
	var ix := 0
	var iy := 0
	while ix < nx or iy < ny:
		var decision := (1 + 2 * ix) * ny - (1 + 2 * iy) * nx
		if decision == 0:
			if _blocks_sight(state, Vector2i(x + sx, y)) and _blocks_sight(state, Vector2i(x, y + sy)):
				return false
			x += sx
			y += sy
			ix += 1
			iy += 1
		elif decision < 0:
			x += sx
			ix += 1
		else:
			y += sy
			iy += 1
		var c := Vector2i(x, y)
		if c == b:
			return true
		if _blocks_sight(state, c):
			return false
	return true


## Shortest 4-neighbour search from `start` limited to `max_steps`.
## Returns {cell: {"steps": int, "cracks": int, "prev": Vector2i}}.
## Among equal-length paths the one crossing fewer cracks wins.
static func search(state: CombatState, start: Vector2i, max_steps: int) -> Dictionary:
	var best := {start: {"steps": 0, "cracks": 0, "prev": start}}
	var frontier: Array[Vector2i] = [start]
	var steps := 0
	while not frontier.is_empty() and steps < max_steps:
		steps += 1
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			var base: Dictionary = best[cell]
			for d in IsoMath.ORTHO_DIRS:
				var n: Vector2i = cell + d
				if not state.is_walkable(n):
					continue
				var cracks: int = base["cracks"] + (1 if state.get_terrain(n) == CombatState.Terrain.CRACK else 0)
				if best.has(n):
					var known: Dictionary = best[n]
					if known["steps"] < steps or (known["steps"] == steps and known["cracks"] <= cracks):
						continue
				else:
					next_frontier.append(n)
				best[n] = {"steps": steps, "cracks": cracks, "prev": cell}
		frontier = next_frontier
	return best


## Cells reachable with `mp` movement points (excluding the start cell).
static func reachable_cells(state: CombatState, start: Vector2i, mp: int) -> Dictionary:
	var result := search(state, start, mp)
	result.erase(start)
	return result


## Path from start to goal (excluding start). Empty if unreachable within max_steps.
static func find_path(state: CombatState, start: Vector2i, goal: Vector2i, max_steps: int = 64) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if start == goal:
		return path
	var result := search(state, start, max_steps)
	if not result.has(goal):
		return path
	var cur := goal
	while cur != start:
		path.push_front(cur)
		cur = result[cur]["prev"]
	return path


static func area_cells(state: CombatState, area: String, center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [center]
	if area == "cross1":
		for d in IsoMath.ORTHO_DIRS:
			cells.append(center + d)
	var out: Array[Vector2i] = []
	for c in cells:
		if state.in_bounds(c):
			out.append(c)
	return out


## Unit step used for a push from `from` towards `to` (8 directions).
static func push_direction(from: Vector2i, to: Vector2i) -> Vector2i:
	if from == to:
		return Vector2i.ZERO
	if is_line8(from, to):
		return Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	return IsoMath.GRID_DIRS[IsoMath.facing_between(from, to)]
