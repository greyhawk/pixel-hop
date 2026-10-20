class_name Level
extends Node2D
## §7 / §8: Level scene root。`level_index` 是 Levels.MAPS key（1-3）；
## 0 是哨兵：场景由游戏流程直接加载时 _ready 取 Game.state.current_level。
## 子节点（Terrain、Decor、Entities、Bounds、Camera）由 LevelBuilder 在
## _ready 构建——冒烟 / 建造器测试需在 add_child 前显式设置 level_index。
## M6: 死亡路由（重生 / Game Over）、本关计时。M7: HUD / 暂停菜单 / 结算面板。

signal player_died

## 0 = 哨兵（§10.7 流程切换不写此值，读 Game.state.current_level）。
@export var level_index: int = 0

var _player: Player
var _camera: CameraFollow
var _time_running := false
var _hud: CanvasLayer
var _pause_menu: CanvasLayer
var _screen_shake: ScreenShake

func _ready() -> void:
	if level_index < 1:
		if Game.state != null:
			level_index = Game.state.current_level
	LevelBuilder.build(self, level_index)
	_player = get_node_or_null("Entities/Player") as Player
	_camera = get_node_or_null("Camera") as CameraFollow
	# M8: 屏幕震动（注入相机，镜像 offset；camera 可空——无相机时不镜像）。
	_screen_shake = ScreenShake.new()
	_screen_shake.name = "ScreenShake"
	_screen_shake.camera = _camera
	add_child(_screen_shake)
	Game.screen_shake = _screen_shake
	if _player:
		_player.died.connect(_on_player_died)
		if Game.respawn_pending:
			# §9.6: 重生——新 Player 实例满 HP，给 1.0 s 无敌（沿用受击闪烁）。
			_player._iframe_timer = Tuning.RESPAWN_IFRAMES
			Audio.play_sfx("sfx_respawn")
		Game.respawn_pending = false
	_time_running = not Game.smoke_mode
	_connect_entities()
	_hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	add_child(_hud)
	_pause_menu = (load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate()
	add_child(_pause_menu)


func _exit_tree() -> void:
	# M8: 本关卡拥有 Game.screen_shake；离开场景时清空，避免跨场景悬空引用。
	if _screen_shake != null and is_instance_valid(_screen_shake) and Game.screen_shake == _screen_shake:
		Game.screen_shake = null


## M6: 金币计数 + 终点旗过关路由（回调里的场景切换在冒烟下只打印，见 Game）。
func _connect_entities() -> void:
	var entities := get_node_or_null("Entities")
	if entities == null:
		return
	for child in entities.get_children():
		if child is Coin and not child.collected.is_connected(_on_coin_collected):
			child.collected.connect(_on_coin_collected)
	var flag := entities.get_node_or_null("Flag") as GoalFlag
	if flag and not flag.completed.is_connected(_on_flag_completed):
		flag.completed.connect(_on_flag_completed)


func _on_coin_collected() -> void:
	Game.state.collect_coin()


## §9.6: 死亡结算（died 在 t=1.0 s、黑幕已拉起后发出）——lives > 0 重生，
## lives == 0 进 Game Over。等 fade_to_black（0.35 s）完成后再切场景。
func _on_player_died() -> void:
	if _camera:
		_camera.frozen = true
	player_died.emit()
	_time_running = false
	if Game.smoke_mode:
		return
	var result := Game.state.on_death()
	await get_tree().create_timer(Tuning.DEATH_FADE + 0.05).timeout
	if result == "game_over":
		Game.go_game_over()
	else:
		Game.respawn()


## §9.7/§10.6: 过关——HP 回满、存档解锁下一关、关内暂停禁用、0.8 s 后出结算
## 面板（M7 替代 M6 自动进下一关；下一关 / 重玩 / 标题由面板驱动）。
func _on_flag_completed() -> void:
	_time_running = false
	if Game.smoke_mode:
		return
	_pause_menu.set_enabled(false)
	Game.state.on_level_complete()
	Game.save.complete_level(level_index, Game.state.coins_this_level)
	await get_tree().create_timer(Tuning.COMPLETE_PANEL_DELAY).timeout
	var panel = (load("res://scenes/ui/level_complete.tscn") as PackedScene).instantiate()
	add_child(panel)
	panel.setup(level_index, Game.state.coins_this_level, Game.state.coins_total_this_level,
			Game.state.level_time, Game.state.deaths_this_level)


## 掉坑：玩家脚底越过关卡边界底 + PIT_MARGIN（§9.2）。
func _physics_process(_delta: float) -> void:
	if _player == null or _player.dead or _player.victory:
		return
	if _camera and _player.global_position.y > _camera.limit_bottom + Tuning.PIT_MARGIN:
		_player.die(true)


## §9.7: 本关计时（死亡 / 过关 / 重开时归零，见 GameState）。
func _process(delta: float) -> void:
	if _time_running and _player and not _player.dead and not _player.victory:
		Game.state.level_time += delta


## §12: 冒烟测试用的实体计数（建造器注入，非运行时状态）。
func get_entity_counts() -> Dictionary:
	var counts := {"coins": 0, "walkers": 0, "spikies": 0, "spikes": 0, "signs": 0}
	var entities := get_node_or_null("Entities")
	if entities == null:
		return counts
	for child in entities.get_children():
		if child is Coin:
			counts["coins"] += 1
		elif child is Enemy:
			counts["walkers" if (child as Enemy).stompable else "spikies"] += 1
		elif child is Spike:
			counts["spikes"] += 1
		elif child is Sign:
			counts["signs"] += 1
	return counts
