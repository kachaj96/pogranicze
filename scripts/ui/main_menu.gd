extends Control
## Start menu. Placeholder until exploration becomes the default entry.

const COMBAT_SCENE := "res://scenes/combat/combat.tscn"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#171c20")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := Label.new()
	title.text = "POGRANICZE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#c7b79d"))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "prototyp %s - grafika tymczasowa" % ProjectSettings.get_setting("application/config/version")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("#816782"))
	box.add_child(sub)
	box.add_child(_button("Walka próbna: Polana w Starym Lesie", func() -> void: get_tree().change_scene_to_file(COMBAT_SCENE)))
	if OS.get_name() != "Android":
		box.add_child(_button("Wyjście", func() -> void: get_tree().quit()))


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 60)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	return b
