extends Node
## Headless smoke driver (spec §13.2). Runs as a standalone scene:
##   godot --headless --path . --fixed-fps 60 --quit-after 3600 test/smoke/smoke_run.tscn
## Never uses change_scene_to_file (it would unload the driver).
## M0 scope: autoloads + input map idempotency. Level/UI sections land in M3+.

var _failures: PackedStringArray = []


func _ready() -> void:
	Game.smoke_mode = true
	_run()


func _run() -> void:
	await get_tree().physics_frame
	_check_autoloads()
	_check_input_map()
	for i in 30:
		await get_tree().physics_frame
	if _failures.is_empty():
		print("SMOKE OK")
		get_tree().quit(0)
	else:
		for f in _failures:
			push_error("SMOKE FAIL: %s" % f)
		get_tree().quit(1)


func _check_autoloads() -> void:
	if not is_instance_valid(Game):
		_failures.append("Game autoload missing")
	if not is_instance_valid(Transition):
		_failures.append("Transition autoload missing")
	if not is_instance_valid(Audio):
		_failures.append("Audio autoload missing")


func _check_input_map() -> void:
	var expected := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z, KEY_W, KEY_UP],
		"pause": [KEY_ESCAPE, KEY_P],
		"toggle_fullscreen": [KEY_F11],
		"ui_accept": [KEY_ENTER, KEY_SPACE, KEY_Z],
		"ui_cancel": [KEY_ESCAPE, KEY_X],
		"ui_up": [KEY_UP, KEY_W],
		"ui_down": [KEY_DOWN, KEY_S],
		"ui_left": [KEY_LEFT, KEY_A],
		"ui_right": [KEY_RIGHT, KEY_D],
	}
	for action in expected:
		if not InputMap.has_action(action):
			_failures.append("missing action %s" % action)
			continue
		for kc in expected[action]:
			if not _has_key(action, kc):
				_failures.append("action %s missing key %d" % [action, kc])
	# Idempotency: second registration must not add duplicates.
	var before := _snapshot()
	Game.register_input_map()
	if not before == _snapshot():
		_failures.append("register_input_map is not idempotent")


func _has_key(action: String, kc: Key) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.physical_keycode == kc:
			return true
	return false


func _snapshot() -> String:
	var out := {}
	for action in InputMap.get_actions():
		var keys := []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and ev.physical_keycode != KEY_NONE:
				keys.append(int(ev.physical_keycode))
		keys.sort()
		out[action] = keys
	return JSON.stringify(out)
