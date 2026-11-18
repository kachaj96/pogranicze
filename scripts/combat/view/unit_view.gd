class_name UnitView
extends Node2D
## Placeholder unit figure. Origin = feet anchor on the cell centre.
## Team readability uses colour AND shape: players have a round head and a
## blue base ring, enemies a pointed head and a red square base.

var unit_id: String
var team: int
var glyph: String = "?"
var body_color := Color.WHITE
var max_hp := 1
var hp := 1
var ward := 0
var facing := 3
var selected := false
var is_local := false
var body_offset := Vector2.ZERO:
	set(value):
		body_offset = value
		queue_redraw()


func setup(u: CombatUnit, def: Dictionary, local_peer: int) -> void:
	unit_id = u.id
	team = u.team
	glyph = str(def.get("glyph", "?"))
	body_color = Color(str(def.get("color", "#888888")))
	is_local = u.owner_peer == local_peer and team == CombatState.TEAM_PLAYERS
	sync(u)


func sync(u: CombatUnit) -> void:
	max_hp = u.max_hp
	hp = u.hp
	ward = u.ward
	facing = u.facing
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var team_col := Color("#6fb0e0") if team == CombatState.TEAM_PLAYERS else Color("#e0604a")
	# Ground marker (shape differs per team).
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.35))
	if team == CombatState.TEAM_PLAYERS:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, team_col, 3.0 if not selected else 5.0)
	else:
		draw_rect(Rect2(-17, -17, 34, 34), team_col, false, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selected:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 32, Color("#e8c86a"), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Facing arrow on the ground (8 directions).
	var fv := IsoMath.facing_screen_vector(facing)
	var tip := fv * 26.0
	var side := Vector2(-fv.y, fv.x) * 5.0
	draw_colored_polygon(PackedVector2Array([tip, fv * 17.0 + side, fv * 17.0 - side]), Color("#e8c86a"))
	# Body.
	var o := body_offset
	draw_rect(Rect2(o + Vector2(-11, -46), Vector2(22, 40)), body_color.darkened(0.15))
	draw_rect(Rect2(o + Vector2(-11, -46), Vector2(22, 40)), Color(0.09, 0.11, 0.13), false, 1.0)
	if team == CombatState.TEAM_PLAYERS:
		draw_circle(o + Vector2(0, -56), 9.0, body_color.lightened(0.25))
	else:
		draw_colored_polygon(PackedVector2Array([o + Vector2(-10, -50), o + Vector2(10, -50), o + Vector2(0, -68)]), body_color.lightened(0.2))
	draw_string(font, o + Vector2(-6, -18), glyph, HORIZONTAL_ALIGNMENT_CENTER, 12, 16, Color("#f0e6d0"))
	# HP bar.
	var bar := Rect2(o + Vector2(-20, -80), Vector2(40, 6))
	draw_rect(bar, Color(0.09, 0.11, 0.13))
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), team_col)
	if ward > 0:
		draw_rect(bar.grow(1.5), Color("#8fe0f0"), false, 1.5)
	draw_string(font, o + Vector2(-20, -84), "%d" % hp, HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color("#f0e6d0"))
