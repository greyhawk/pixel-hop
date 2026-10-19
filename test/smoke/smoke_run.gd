extends Node
## Headless smoke driver (spec §13.2). Runs as a standalone scene:
##   godot --headless --path . --fixed-fps 60 --quit-after 3600 test/smoke/smoke_run.tscn
## Never uses change_scene_to_file (it would unload the driver).
## M0 scope: autoloads + input map idempotency.
## M3 scope: instantiate all 3 levels (terrain + entities), no SCRIPT ERROR.
## M4 scope: Player present in every level; scripted hold-right moves within
## the map; one-way drop-through; corner correction clears the overhang.
## M5 scope: per-level entity counts (coins/walkers/spikies/spikes/signs).
var _failures: PackedStringArray = []


func _ready() -> void:
	Game.smoke_mode = true
	_run()


func _run() -> void:
	await get_tree().physics_frame
	_check_autoloads()
	_check_input_map()
	await _check_levels()
	await _check_player_movement()
	await _check_player_drop_through()
	await _check_player_corner_correction()
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


func _check_levels() -> void:
	var packed: PackedScene = load(Game.LEVEL_SCENE)
	if packed == null:
		_failures.append("level.tscn failed to load")
		return
	for idx in 3:
		var level_index := idx + 1
		var level: Level = packed.instantiate()
		level.level_index = level_index
		add_child(level)
		await get_tree().process_frame
		if level.get_node_or_null("Entities/Spawn") == null:
			_failures.append("level %d: Spawn marker missing" % level_index)
		if level.get_node_or_null("Entities/Player") == null:
			_failures.append("level %d: Player missing" % level_index)
		if level.get_node_or_null("Entities/Flag") == null:
			_failures.append("level %d: Flag marker missing" % level_index)
		var terrain: TileMapLayer = level.get_node_or_null("Terrain") as TileMapLayer
		if terrain == null:
			_failures.append("level %d: Terrain TileMapLayer missing" % level_index)
		else:
			if terrain.get_used_rect().size.x != Levels.COLS:
				_failures.append("level %d: Terrain used rect width %d != %d" % [level_index, terrain.get_used_rect().size.x, Levels.COLS])
		var counts := level.get_entity_counts()
		var expected_counts: Dictionary = {
			1: {"coins": 11, "walkers": 1, "spikies": 0, "spikes": 0, "signs": 5},
			2: {"coins": 17, "walkers": 2, "spikies": 0, "spikes": 0, "signs": 0},
			3: {"coins": 8, "walkers": 1, "spikies": 2, "spikes": 9, "signs": 0},
		}[level_index]
		for key in expected_counts:
			_check(
				counts.get(key, -1) == expected_counts[key],
				"level %d: %s count %d != %d" % [level_index, key, counts.get(key, -1), expected_counts[key]],
			)
		level.queue_free()
	await get_tree().process_frame


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


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures.append(msg)


func _instantiate_level(level_index: int) -> Level:
	var packed: PackedScene = load(Game.LEVEL_SCENE)
	var level: Level = packed.instantiate()
	level.level_index = level_index
	add_child(level)
	return level


func _get_player(level: Level) -> Player:
	return level.get_node_or_null("Entities/Player") as Player


## §13.2 / M4 验收：按住右 120 帧，x 增加且不离开地图（1-1 无坑）。
func _check_player_movement() -> void:
	var level := _instantiate_level(1)
	await get_tree().process_frame
	var player := _get_player(level)
	if player == null:
		_failures.append("movement: Player missing")
		level.queue_free()
		await get_tree().process_frame
		return
	var scripted := InputSource.ScriptedInput.new()
	for i in 120:
		scripted.queue_frame(1, "none")
	player.input_source = scripted
	var x0 := player.global_position.x
	for i in 150:
		await get_tree().physics_frame
	var pos := player.global_position
	_check(pos.x > 100.0, "movement: player x %f did not move right (start %f)" % [pos.x, x0])
	_check(pos.x <= 640.0, "movement: player x %f left the map" % pos.x)
	_check(pos.y < 192.0 + Tuning.PIT_MARGIN, "movement: player y %f fell out of the map" % pos.y)
	level.queue_free()
	await get_tree().process_frame


## §9.4：1-1 的 row8 单向平台（cols 31–34，顶 y=128）。落在平台上，
## 下压 + 跳（held 分支）→ 穿过平台落到地面 y=160，mask 恢复 FULL。
func _check_player_drop_through() -> void:
	var level := _instantiate_level(1)
	await get_tree().process_frame
	var player := _get_player(level)
	if player == null:
		_failures.append("drop: Player missing")
		level.queue_free()
		await get_tree().process_frame
		return
	player.position = Vector2(520, 128)
	player.velocity = Vector2.ZERO
	var scripted := InputSource.ScriptedInput.new()
	for i in 2:
		scripted.queue_frame(0, "none")
	scripted.queue_frame(0, "down", true)
	for i in 40:
		scripted.queue_frame(0, "none")
	player.input_source = scripted
	for i in 45:
		await get_tree().physics_frame
	_check(player.global_position.y > 130.0, "drop: player y %f did not drop through the one-way strip" % player.global_position.y)
	_check(player.collision_mask == Player.FULL_MASK, "drop: collision mask %d not restored to %d" % [player.collision_mask, Player.FULL_MASK])
	level.queue_free()
	await get_tree().process_frame


## §9.5：1-1 顶棚（row8 cols 15–17，y 128–144）。身体 [234,244] 与 col15
## 重叠恰 4 px（== Tuning.CORNER_CORRECTION）：跳起顶头时应被水平推出并继续上升。
func _check_player_corner_correction() -> void:
	var level := _instantiate_level(1)
	await get_tree().process_frame
	var player := _get_player(level)
	if player == null:
		_failures.append("corner: Player missing")
		level.queue_free()
		await get_tree().process_frame
		return
	player.position = Vector2(239, 160)
	player.velocity = Vector2.ZERO
	var scripted := InputSource.ScriptedInput.new()
	scripted.queue_frame(0, "down")
	for i in 12:
		scripted.queue_frame(0, "none")
	scripted.queue_frame(0, "up")
	player.input_source = scripted
	var min_y := player.global_position.y
	for i in 25:
		await get_tree().physics_frame
		min_y = minf(min_y, player.global_position.y)
	_check(min_y < 132.0, "corner: player min y %f — did not clear the overhang (corner correction failed)" % min_y)
	_check(player.global_position.x < 239.0, "corner: player x %f — not pushed off the overhang corner" % player.global_position.x)
	level.queue_free()
	await get_tree().process_frame
