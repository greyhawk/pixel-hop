extends Node
## Global autoload: InputMap registration (D9), window min size, level flow,
## F11 fullscreen, hitstop (M8), state holders (M6).
## M6: GameState / SaveData 实例、重生（respawn）、过关→下一关、Game Over 重试。

## When true, UI scene-changing callbacks only print (smoke driver).
var smoke_mode := false
## M6: true = 下一次进 level.tscn 时给玩家 1.0 s 重生无敌（死亡重生路由用）。
var respawn_pending := false

## M6: 运行时状态（单进程内跨场景共享；GUT 单测自建实例，勿用 Game.state）。
var state: GameState = null
## M6: 存档（user://save.cfg）。
var save: SaveData = null

const LEVEL_SCENE := "res://scenes/levels/level.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"


func _ready() -> void:
	register_input_map()
	get_window().min_size = Vector2i(320, 180)
	state = GameState.new()
	save = SaveData.new()


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


# --- Level flow (M6: state machine + scene routing) ---

func go_title() -> void:
	Transition.change_scene(TITLE_SCENE)


func go_game_over() -> void:
	Transition.change_scene(GAME_OVER_SCENE)


## §10.2: 新游戏：命数=3、HP=3、进指定关（默认 1-1）。
func start_new_game(level: int = 1) -> void:
	state.start_new_game(level)
	start_level(level)


## 进关：状态重置（HP 满、金币 / 计时 / 失误清零）、切 level.tscn、开 BGM。
func start_level(level_index: int) -> void:
	state.start_level(level_index)
	Transition.change_scene(LEVEL_SCENE)
	Audio.play_bgm("bgm_level")


## §9.6: 重生——重载当前关（Game.state 已由 on_death 结算）。
func respawn() -> void:
	respawn_pending = true
	Transition.change_scene(LEVEL_SCENE)
	Audio.play_bgm("bgm_level")


## §10.5: 暂停菜单"重新开始本关"——不扣命、不清失误（D23）。
func restart_level() -> void:
	state.restart_level_from_pause()
	Transition.change_scene(LEVEL_SCENE)
	Audio.play_bgm("bgm_level")


## §10.7: Game Over"重试本关"——命数=3、重进当前关。
func retry_after_game_over() -> void:
	state.retry_after_game_over()
	Transition.change_scene(LEVEL_SCENE)
	Audio.play_bgm("bgm_level")
