extends Node
## Registers input actions at startup so the key mapping lives in one place.
##
## PC mapping (documented in README):
##   WASD / arrows   - exploration movement (8 directions with combinations)
##   1-4             - combat abilities
##   M               - combat move mode
##   Tab             - next controllable unit
##   Space / Enter   - end team phase
##   Esc             - cancel
##   Mouse wheel     - zoom; left drag - pan; left click - select / confirm

const KEY_ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"ability_1": [KEY_1],
	"ability_2": [KEY_2],
	"ability_3": [KEY_3],
	"ability_4": [KEY_4],
	"mode_move": [KEY_M],
	"next_unit": [KEY_TAB],
	"end_turn": [KEY_SPACE, KEY_ENTER],
	"cancel": [KEY_ESCAPE],
	"interact": [KEY_E],
}


func _ready() -> void:
	for action: String in KEY_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: int in KEY_ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
