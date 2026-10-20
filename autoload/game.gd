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

## M8: 屏幕震动（由 Level 注入；可为空——测试 / 无场景时 shake() 静默）。
var screen_shake: ScreenShake = null
## M8: hitstop 结束时间（Time.get_ticks_msec() 墙钟，不受 Engine.time_scale 影响）。
var _hitstop_end_ms := 0

const LEVEL_SCENE := "res://scenes/levels/level.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"


func _ready() -> void:
	register_input_map()
	get_window().min_size = Vector2i(320, 180)
	state = GameState.new()
	save = SaveData.new()
	if save.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## M8: hitstop 用墙钟计时（Time.get_ticks_msec 单调，不受 Engine.time_scale 影响），
## 到点恢复 time_scale = 1。多次叠加取最长剩余时间（见 hitstop）。
func _process(_delta: float) -> void:
	if _hitstop_end_ms > 0 and Time.get_ticks_msec() >= _hitstop_end_ms:
		_hitstop_end_ms = 0
		Engine.time_scale = 1.0


## M8: 触发屏幕震动（振幅 px, 时长 s）。无 screen_shake 时静默。
func shake(amplitude: float, duration: float) -> void:
	if is_instance_valid(screen_shake):
		screen_shake.shake(amplitude, duration)


## M8: 冻结 time_scale 到 HITSTOP_TIME_SCALE，墙钟 d 秒后恢复 1.0。
## 烟测模式跳过（避免扰动帧计数）；多次叠加取最长剩余时间。
func hitstop(d: float) -> void:
	if smoke_mode or d <= 0.0:
		return
	var end := Time.get_ticks_msec() + int(round(d * 1000.0))
	if end > _hitstop_end_ms:
		_hitstop_end_ms = end
		Engine.time_scale = Tuning.HITSTOP_TIME_SCALE


## M8: 组合反馈——arr = [振幅, 震屏时长, hitstop 时长]（见 Tuning.SHAKE_*）。
func feedback(arr: Array) -> void:
	shake(float(arr[0]), float(arr[1]))
	hitstop(float(arr[2]))


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
	if smoke_mode:
		return
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		save.fullscreen = false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		save.fullscreen = true
	save.save()


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
