class_name FloatText
extends Node2D
## Short-lived floating combat text.

var text := ""
var color := Color.WHITE


func _ready() -> void:
	z_index = 100
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 34.0, 0.8)
	tw.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-50, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, 4, Color(0.09, 0.11, 0.13))
	draw_string(font, Vector2(-50, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, color)
