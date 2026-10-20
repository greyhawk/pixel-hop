class_name GameState
extends RefCounted
## §9.7: 纯内存游戏状态机（无节点依赖，GUT 可直接 new 单测）。
## HP / 命数 / 金币 / 计时 / 失误 + 流程入口（新游戏 / 死亡 / 过关 / 重开 / 重试）。
## HUD（M7）订阅 hp_changed / lives_changed / coins_changed。

signal hp_changed(hp: int)
signal lives_changed(lives: int)
signal coins_changed(coins: int)

var lives := Tuning.START_LIVES
var hp := Tuning.MAX_HP
## 当前关卡 1-3（流程切换写入，0 哨兵由 Level 读此值兜底）。
var current_level := 1
var coins_this_level := 0
var coins_total_this_level := int(Levels.META[1]["coins"])
## 本关失误次数（§10.6 结算面板展示；重开本关不清空，D23）。
var deaths_this_level := 0
## 本关计时（秒）：在关内累加，死亡 / 过关 / 重开时归零（M6 假设：
## 死亡后重新开始计时；暂停扣时由 M7 暂停界面处理）。
var level_time := 0.0


## §10.2: 新游戏（标题"开始游戏"）：命数=3、HP=3、进指定关（D17 默认 1-1）。
func start_new_game(level: int = 1) -> void:
	lives = Tuning.START_LIVES
	lives_changed.emit(lives)
	start_level(level)


## 进关（菜单选关 / 过关后下一关 / 重试本关）：HP 满、金币 / 计时 / 失误清零、命数保持。
func start_level(idx: int) -> void:
	current_level = idx
	hp = Tuning.MAX_HP
	hp_changed.emit(hp)
	coins_this_level = 0
	coins_total_this_level = int(Levels.META[idx]["coins"])
	coins_changed.emit(coins_this_level)
	level_time = 0.0
	deaths_this_level = 0


## §8: 受击一次；返回 true 表示致命（hp 归 0）。
func apply_damage() -> bool:
	hp -= 1
	hp_changed.emit(hp)
	return hp <= 0


## §9.6: 死亡结算。lives > 0 → "respawn"（失误 +1、HP 回满、金币 / 计时清零、
## 命数 −1）；lives == 0 → "game_over"。调用方（Level）按返回值路由场景。
func on_death() -> String:
	lives -= 1
	lives_changed.emit(lives)
	deaths_this_level += 1
	if lives <= 0:
		return "game_over"
	hp = Tuning.MAX_HP
	hp_changed.emit(hp)
	coins_this_level = 0
	coins_changed.emit(coins_this_level)
	level_time = 0.0
	return "respawn"


## §9.7: 过关：HP 回满、命数 / 金币保持（结算面板读取它们）。
func on_level_complete() -> void:
	hp = Tuning.MAX_HP
	hp_changed.emit(hp)


## §10.5 / D23: 暂停菜单"重新开始本关"：不扣命、不清空 deaths_this_level。
func restart_level_from_pause() -> void:
	hp = Tuning.MAX_HP
	hp_changed.emit(hp)
	coins_this_level = 0
	coins_changed.emit(coins_this_level)
	level_time = 0.0


## §10.7: Game Over"重试本关"：命数=3、重新进当前关（D23: 清空 deaths_this_level）。
func retry_after_game_over() -> void:
	lives = Tuning.START_LIVES
	lives_changed.emit(lives)
	hp = Tuning.MAX_HP
	hp_changed.emit(hp)
	coins_this_level = 0
	coins_changed.emit(coins_this_level)
	level_time = 0.0
	deaths_this_level = 0


## §8: 拾取一枚金币。
func collect_coin() -> void:
	coins_this_level += 1
	coins_changed.emit(coins_this_level)
