extends GutTest
## Verifies spec §9.1 actions + physical keycodes, and idempotent registration.


func test_all_actions_present_with_keys() -> void:
	Game.register_input_map()
	var expected := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z, KEY_W, KEY_UP],
		"pause": [KEY_ESCAPE, KEY_P],
		"toggle_fullscreen": [KEY_F11],
		"ui_accept": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z],
		"ui_cancel": [KEY_ESCAPE, KEY_X, KEY_BACKSPACE],
		"ui_up": [KEY_UP, KEY_W],
		"ui_down": [KEY_DOWN, KEY_S],
		"ui_left": [KEY_LEFT, KEY_A],
		"ui_right": [KEY_RIGHT, KEY_D],
	}
	for action in expected:
		assert_true(InputMap.has_action(action), "action missing: " + action)
		if not InputMap.has_action(action):
			continue
		for kc in expected[action]:
			assert_true(_has_physical_key(action, kc), "%s should include key %d" % [action, kc])


func test_register_is_idempotent() -> void:
	Game.register_input_map()
	var before := _snapshot()
	Game.register_input_map()
	Game.register_input_map()
	assert_eq(_snapshot(), before, "register_input_map must not add duplicate events")


func _has_physical_key(action: String, kc: Key) -> bool:
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
