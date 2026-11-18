extends SceneTree
## Renders a scene and saves a PNG. Needs a real display (e.g. xvfb-run).
## godot --path . -s res://tools/capture.gd -- <scene> <out.png> [frames] [hover_x hover_y]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/combat/combat.tscn"
	var out: String = args[1] if args.size() > 1 else "user://capture.png"
	var frames: int = int(args[2]) if args.size() > 2 else 30
	change_scene_to_packed(load(scene_path))
	for i in frames:
		await process_frame
	if args.size() > 4:
		var ev := InputEventMouseMotion.new()
		ev.position = Vector2(float(args[3]), float(args[4]))
		root.push_input(ev)
		for i in 5:
			await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
