class_name CombatHud
extends Control
## Combat HUD built in code. Emits intents; never touches combat rules.
## Touch targets are at least 56 px high (approx. 48 dp on typical phones
## after canvas_items stretch).

signal unit_pressed(unit_id: String)
signal mode_pressed(mode: String)
signal end_turn_pressed
signal cancel_pressed
signal restart_pressed
signal menu_pressed

const BTN_MIN := Vector2(104, 60)

var _status: Label
var _log: Label
var _message: Label
var _banner: Label
var _unit_box: HBoxContainer
var _mode_box: HBoxContainer
var _end_btn: Button
var _cancel_btn: Button
var _end_panel: PanelContainer
var _end_label: Label
var _log_lines: Array[String] = []
var _unit_buttons: Dictionary = {}
var _mode_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = 17
	theme = th

	var status_panel := _panel()
	status_panel.position = Vector2(12, 12)
	add_child(status_panel)
	_status = Label.new()
	status_panel.add_child(_status)

	var log_panel := _panel()
	log_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	log_panel.offset_left = -360
	log_panel.offset_right = -12
	log_panel.offset_top = 12
	add_child(log_panel)
	_log = Label.new()
	_log.custom_minimum_size = Vector2(330, 0)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.add_theme_font_size_override("font_size", 14)
	log_panel.add_child(_log)

	var menu_btn := Button.new()
	menu_btn.text = "Menu"
	menu_btn.custom_minimum_size = Vector2(90, 48)
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.pressed.connect(func() -> void: menu_pressed.emit())
	add_child(menu_btn)
	menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_btn.offset_left = -466
	menu_btn.offset_right = -372
	menu_btn.offset_top = 12
	menu_btn.offset_bottom = 60

	var bar_panel := _panel()
	bar_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar_panel.offset_bottom = -10
	add_child(bar_panel)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar_panel.add_child(bar)
	_unit_box = HBoxContainer.new()
	bar.add_child(_unit_box)
	bar.add_child(VSeparator.new())
	_mode_box = HBoxContainer.new()
	bar.add_child(_mode_box)
	bar.add_child(VSeparator.new())
	_cancel_btn = _button("Anuluj\n(Esc)")
	_cancel_btn.pressed.connect(func() -> void: cancel_pressed.emit())
	bar.add_child(_cancel_btn)
	_end_btn = _button("Koniec\ntury")
	_end_btn.pressed.connect(func() -> void: end_turn_pressed.emit())
	bar.add_child(_end_btn)

	_message = Label.new()
	_message.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_message.offset_left = 16
	_message.offset_right = -16
	_message.offset_top = -132
	_message.offset_bottom = -100
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_outline_color", Color(0.09, 0.11, 0.13))
	_message.add_theme_constant_override("outline_size", 6)
	_message.add_theme_font_size_override("font_size", 19)
	add_child(_message)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 150
	_banner.offset_bottom = 200
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 30)
	_banner.add_theme_color_override("font_color", Color("#e8c86a"))
	_banner.add_theme_color_override("font_outline_color", Color(0.09, 0.11, 0.13))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.modulate.a = 0.0
	add_child(_banner)

	_end_panel = _panel()
	_end_panel.set_anchors_preset(Control.PRESET_CENTER)
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_panel.visible = false
	add_child(_end_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_end_panel.add_child(vb)
	_end_label = Label.new()
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.add_theme_font_size_override("font_size", 28)
	vb.add_child(_end_label)
	var again := _button("Jeszcze raz")
	again.pressed.connect(func() -> void: restart_pressed.emit())
	vb.add_child(again)
	var back := _button("Menu główne")
	back.pressed.connect(func() -> void: menu_pressed.emit())
	vb.add_child(back)


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.13, 0.82)
	sb.border_color = Color("#775a45")
	sb.set_border_width_all(1)
	sb.set_content_margin_all(10)
	sb.set_corner_radius_all(3)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = BTN_MIN
	b.focus_mode = Control.FOCUS_NONE
	return b


func build_units(units: Array[CombatUnit]) -> void:
	for c in _unit_box.get_children():
		c.queue_free()
	_unit_buttons.clear()
	for u in units:
		var b := _button(u.display_name)
		b.toggle_mode = true
		var uid := u.id
		b.pressed.connect(func() -> void: unit_pressed.emit(uid))
		_unit_box.add_child(b)
		_unit_buttons[uid] = b


func build_modes(unit: CombatUnit, abilities: Dictionary) -> void:
	for c in _mode_box.get_children():
		c.queue_free()
	_mode_buttons.clear()
	var move := _button("Ruch (M)\n%d PR" % unit.mp)
	move.toggle_mode = true
	move.pressed.connect(func() -> void: mode_pressed.emit("move"))
	_mode_box.add_child(move)
	_mode_buttons["move"] = move
	var i := 0
	for aid in unit.abilities:
		i += 1
		var a: AbilityDef = abilities[aid]
		var b := _button("%d %s\n%d PA" % [i, a.display_name, a.ap_cost])
		b.toggle_mode = true
		b.tooltip_text = a.description
		b.disabled = unit.ap < a.ap_cost
		b.pressed.connect(func() -> void: mode_pressed.emit(aid))
		_mode_box.add_child(b)
		_mode_buttons[aid] = b


func update_selection(selected_id: String, mode: String, players_turn: bool, can_end: bool) -> void:
	for uid: String in _unit_buttons:
		(_unit_buttons[uid] as Button).set_pressed_no_signal(uid == selected_id)
	for m: String in _mode_buttons:
		(_mode_buttons[m] as Button).set_pressed_no_signal(m == mode)
	_end_btn.disabled = not can_end
	_cancel_btn.disabled = not players_turn
	_mode_box.modulate.a = 1.0 if players_turn else 0.5


func set_status(text: String) -> void:
	_status.text = text


func show_message(text: String) -> void:
	_message.text = text


func add_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > 9:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


func show_banner(text: String) -> void:
	_banner.text = text
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.tween_interval(0.7)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.3)


func show_end(players_won: bool) -> void:
	_end_label.text = "Zwycięstwo" if players_won else "Porażka"
	_end_panel.visible = true
