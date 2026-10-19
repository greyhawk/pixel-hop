extends GutTest
## §9.7: GameState 状态机单测（M6 起非 autoload，直接 new；
## 不用 Game.state——GUT 所有测试文件同进程运行，共享实例会互相污染）。

var _gs: GameState
var _hp_count := 0
var _hp_last := -1
var _lives_count := 0
var _coins_count := 0


func before_each() -> void:
	_gs = GameState.new()
	_hp_count = 0
	_lives_count = 0
	_coins_count = 0
	_gs.hp_changed.connect(_on_hp)
	_gs.lives_changed.connect(_on_lives)
	_gs.coins_changed.connect(_on_coins)


func test_fresh_defaults() -> void:
	assert_eq(_gs.lives, Tuning.START_LIVES, "默认命数 3")
	assert_eq(_gs.hp, Tuning.MAX_HP, "默认满血")
	assert_eq(_gs.current_level, 1, "默认第 1 关")
	assert_eq(_gs.coins_this_level, 0, "默认金币 0")
	assert_eq(_gs.coins_total_this_level, int(Levels.META[1]["coins"]), "1-1 共 11 枚")
	assert_eq(_gs.deaths_this_level, 0, "默认失误 0")
	assert_almost_eq(_gs.level_time, 0.0, 0.001, "默认计时 0")


func test_start_new_game_full_reset() -> void:
	_gs.start_new_game(2)
	assert_eq(_gs.current_level, 2, "进指定关")
	assert_eq(_gs.lives, Tuning.START_LIVES, "命数=3")
	assert_eq(_gs.hp, Tuning.MAX_HP, "HP=3")
	assert_eq(_gs.coins_total_this_level, int(Levels.META[2]["coins"]), "1-2 共 17 枚")


func test_start_level_resets_but_keeps_lives() -> void:
	_gs.lives = 1
	_gs.coins_this_level = 5
	_gs.level_time = 12.5
	_gs.deaths_this_level = 2
	_gs.start_level(2)
	assert_eq(_gs.hp, Tuning.MAX_HP, "HP 回满")
	assert_eq(_gs.coins_this_level, 0, "金币清零")
	assert_eq(_gs.coins_total_this_level, int(Levels.META[2]["coins"]), "总数取新关")
	assert_almost_eq(_gs.level_time, 0.0, 0.001, "计时清零")
	assert_eq(_gs.deaths_this_level, 0, "进关清零失误")
	assert_eq(_gs.lives, 1, "命数保持")


func test_apply_damage_returns_lethality() -> void:
	assert_false(_gs.apply_damage(), "hp 2 非致命")
	assert_eq(_gs.hp, 2, "hp 2")
	assert_false(_gs.apply_damage(), "hp 1 非致命")
	assert_true(_gs.apply_damage(), "hp 0 致命")
	assert_eq(_gs.hp, 0, "hp 归零")


func test_on_death_respawn_flow() -> void:
	_gs.coins_this_level = 4
	_gs.level_time = 3.0
	assert_eq(_gs.on_death(), "respawn", "第 1 次死亡 → respawn")
	assert_eq(_gs.lives, 2, "命数 2")
	assert_eq(_gs.deaths_this_level, 1, "失误 +1")
	assert_eq(_gs.hp, Tuning.MAX_HP, "HP 回满")
	assert_eq(_gs.coins_this_level, 0, "金币清零")
	assert_almost_eq(_gs.level_time, 0.0, 0.001, "计时清零")
	assert_eq(_gs.on_death(), "respawn", "第 2 次死亡 → respawn")
	assert_eq(_gs.lives, 1, "命数 1")
	assert_eq(_gs.on_death(), "game_over", "第 3 次死亡 → game_over")
	assert_eq(_gs.lives, 0, "命数 0")
	assert_eq(_gs.deaths_this_level, 3, "失误累计 3")


func test_retry_after_game_over_full_reset() -> void:
	_gs.on_death()
	_gs.on_death()
	_gs.on_death()
	assert_eq(_gs.lives, 0, "前置：命数耗尽")
	_gs.retry_after_game_over()
	assert_eq(_gs.lives, Tuning.START_LIVES, "命数回 3")
	assert_eq(_gs.hp, Tuning.MAX_HP, "HP 回满")
	assert_eq(_gs.coins_this_level, 0, "金币清零")
	assert_eq(_gs.deaths_this_level, 0, "D23: 清空失误")
	assert_almost_eq(_gs.level_time, 0.0, 0.001, "计时清零")


func test_restart_level_from_pause_keeps_lives_and_deaths() -> void:
	_gs.on_death()
	_gs.coins_this_level = 2
	_gs.level_time = 7.0
	_gs.restart_level_from_pause()
	assert_eq(_gs.lives, 2, "重开不扣命")
	assert_eq(_gs.hp, Tuning.MAX_HP, "HP 回满")
	assert_eq(_gs.coins_this_level, 0, "金币清零")
	assert_almost_eq(_gs.level_time, 0.0, 0.001, "计时清零")
	assert_eq(_gs.deaths_this_level, 1, "D23: 保留失误")


func test_on_level_complete() -> void:
	_gs.hp = 1
	_gs.coins_this_level = 8
	_gs.lives = 2
	_gs.on_level_complete()
	assert_eq(_gs.hp, Tuning.MAX_HP, "过关 HP 回满")
	assert_eq(_gs.coins_this_level, 8, "金币保持（结算面板读取）")
	assert_eq(_gs.lives, 2, "命数保持")


func test_collect_coin() -> void:
	_gs.collect_coin()
	_gs.collect_coin()
	assert_eq(_gs.coins_this_level, 2, "拾取计数")
	assert_eq(_coins_count, 2, "coins_changed 每枚发出")
	assert_eq(_hp_last, Tuning.MAX_HP, "hp_changed 未被金币触发")


func test_signals_report_new_values() -> void:
	_gs.apply_damage()
	assert_eq(_hp_count, 1, "受击发一次 hp_changed")
	assert_eq(_hp_last, 2, "hp_changed 携带新值")
	_gs.on_death()
	assert_eq(_lives_count, 1, "死亡发一次 lives_changed")
	assert_eq(_gs.lives, 2, "lives_changed 后命数 2")


func _on_hp(hp: int) -> void:
	_hp_count += 1
	_hp_last = hp


func _on_lives(_lives: int) -> void:
	_lives_count += 1


func _on_coins(_coins: int) -> void:
	_coins_count += 1
