extends Node
## Global autoload: InputMap registration (D9), window min size, level flow,
## F11 fullscreen, hitstop (M8), state holders (M6).

## When true, UI scene-changing callbacks only print (smoke driver).
var smoke_mode := false

const LEVEL_SCENE := "res://scenes/levels/level.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"


func _ready() -> void:
	register_input_map()
	get_window().min_size = Vector2i(320, 180)


## Registers all actions from spec §9.1. Idempotent: safe to call repeatedly.
func register_input_map() -> void:
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("move_down", [KEY_S, KEY_DOWN])
	_register_action("jump", [KEY_SPACE, KEY_Z, KEY_W, KEY_UP])
	_register_action("pause", [KEY_ESCAPE, KEY_P])
	_register_action("toggle_fullscreen", [KEY_F11])
	# Built-in ui_* actions already exist; only append missing keys (dedupe by
	# physical_keycode — InputMap.action_has_event signature is 【未验证】).
	_append_action_keys("ui_accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z])
	_append_action_keys("ui_cancel", [KEY_ESCAPE, KEY_X, KEY_BACKSPACE])
	_append_action_keys("ui_up", [KEY_UP, KEY_W])
	_append_action_keys("ui_down", [KEY_DOWN, KEY_S])
	_append_action_keys("ui_left", [KEY_LEFT, KEY_A])
	_append_action_keys("ui_right", [KEY_RIGHT, KEY_D])


func _register_action(action: String, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	_append_action_keys(action, keycodes)


func _append_action_keys(action: String, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var existing := _action_physical_keys(action)
	for kc in keycodes:
		if not kc in existing:
			var ev := InputEventKey.new()
			ev.physical_keycode = kc
			InputMap.action_add_event(action, ev)
			existing.append(kc)


func _action_physical_keys(action: String) -> Array:
	var out: Array = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.physical_keycode != KEY_NONE:
			out.append(ev.physical_keycode)
	return out


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()


func toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- Level flow (state machine lands in M6; scene paths fixed now) ---

func go_title() -> void:
	Transition.change_scene(TITLE_SCENE)


func go_game_over() -> void:
	Transition.change_scene(GAME_OVER_SCENE)


func start_level(_level_index: int) -> void:
	Transition.change_scene(LEVEL_SCENE)


func restart_level() -> void:
	Transition.change_scene(LEVEL_SCENE)
