extends Node2D
## Art validation scene: procedural terrain, props and the 8-direction
## character in engine, at integer zoom. Not gameplay - for judging style,
## scale, anchors and readability on PC / phone resolutions.

const DIR := "res://assets/raw/procedural/"
const W := 14
const H := 12
const PROPS := {
	"house": {"anchor": Vector2(160, 226), "cells": [Vector2(4, 3.5)]},
	"tree": {"anchor": Vector2(144, 216), "cells": [Vector2(10, 2), Vector2(11, 5), Vector2(1, 9), Vector2(12, 9), Vector2(9, 0)]},
	"seal_stone": {"anchor": Vector2(48, 128), "cells": [Vector2(8, 8)]},
}

var _world: Node2D
var _walker: AnimatedSprite2D
var _path: Array[Vector2] = [Vector2(2, 7), Vector2(7, 7), Vector2(7, 10), Vector2(10, 10), Vector2(10, 7), Vector2(7, 4), Vector2(2, 7)]
var _seg := 0
var _t := 0.0
var _walker_pos := Vector2(2, 7)
var _frame_size := Vector2(128, 128)
var _anchor := Vector2(64, 112)


func _ready() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "wanderer.json"))
	_frame_size = Vector2(meta["frame_size"][0], meta["frame_size"][1])
	_anchor = Vector2(meta["anchor"][0], meta["anchor"][1])
	var frames := _build_frames(meta)
	_draw_terrain()
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	for prop: String in PROPS:
		var tex: Texture2D = load(DIR + prop + ".png")
		for c: Vector2 in PROPS[prop]["cells"]:
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.offset = -PROPS[prop]["anchor"]
			s.position = IsoMath.plane_to_screen(c)
			_world.add_child(s)
	var block: Texture2D = load(DIR + "block_stone.png")
	for c in [Vector2(5, 9), Vector2(5, 10), Vector2(12, 3)]:
		var b := Sprite2D.new()
		b.texture = block
		b.centered = false
		b.offset = -Vector2(32, 52)
		b.position = IsoMath.plane_to_screen(c)
		_world.add_child(b)
	# Row of idle characters showing all 8 facings.
	for i in 8:
		var a := _character(frames, "idle_%d" % i)
		a.position = IsoMath.plane_to_screen(Vector2(3 + i, 11))
		a.frame = i % 4
	_walker = _character(frames, "walk_4")
	var cam := Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position = IsoMath.plane_to_screen(Vector2(7, 7)) + Vector2(0, -30)
	add_child(cam)


func _character(frames: SpriteFrames, anim: String) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = frames
	a.centered = false
	a.offset = -_anchor
	a.play(anim)
	_world.add_child(a)
	return a


func _build_frames(meta: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in meta["animations"]:
		var info: Dictionary = meta["animations"][anim]
		var sheet: Texture2D = load(DIR + str(info["file"]))
		for d in 8:
			var name := "%s_%d" % [anim, d]
			sf.add_animation(name)
			sf.set_animation_speed(name, float(info["fps"]))
			sf.set_animation_loop(name, true)
			for f in int(info["frames"]):
				var at := AtlasTexture.new()
				at.atlas = sheet
				at.region = Rect2(Vector2(f, d) * _frame_size, _frame_size)
				sf.add_frame(name, at)
	return sf


func _draw_terrain() -> void:
	var grass: Array[Texture2D] = [load(DIR + "floor_grass_0.png"), load(DIR + "floor_grass_1.png"), load(DIR + "floor_grass_2.png")]
	var dirt: Texture2D = load(DIR + "floor_dirt_path.png")
	var crack: Texture2D = load(DIR + "floor_crack.png")
	var ground := Node2D.new()
	ground.z_index = -10
	add_child(ground)
	for y in H:
		for x in W:
			var tex: Texture2D = grass[(x * 7 + y * 3) % 3]
			if y == 7 and x >= 1 or (x == 7 and y >= 4 and y <= 10) or (y == 10 and x >= 7 and x <= 10):
				tex = dirt
			if Vector2i(x, y) in [Vector2i(8, 7), Vector2i(7, 9)]:
				tex = crack
			var s := Sprite2D.new()
			s.texture = tex
			s.position = IsoMath.grid_to_screen(Vector2i(x, y))
			ground.add_child(s)


func _process(delta: float) -> void:
	var a := _path[_seg]
	var b := _path[(_seg + 1) % _path.size()]
	var speed := 1.6  # cells per second
	_t += delta * speed / maxf(0.001, a.distance_to(b))
	if _t >= 1.0:
		_t = 0.0
		_seg = (_seg + 1) % (_path.size() - 1)
		return
	_walker_pos = a.lerp(b, _t)
	_walker.position = IsoMath.plane_to_screen(_walker_pos)
	var facing := IsoMath.facing_from_delta(b - a)
	var anim := "walk_%d" % facing
	if _walker.animation != anim:
		_walker.play(anim)
