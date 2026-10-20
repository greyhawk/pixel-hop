extends GutTest
## §9.7: SaveData 存档读写单测（ConfigFile，临时路径 + 前后清理）。

const TEMP_PATH := "user://test_save_data.cfg"

var _save: SaveData


func before_each() -> void:
	_remove_temp()
	_save = SaveData.new(TEMP_PATH)


func after_each() -> void:
	_remove_temp()


func test_missing_file_gives_defaults() -> void:
	assert_eq(_save.unlocked_level, 1, "无存档 → 从第 1 关解锁")
	assert_eq(_save.best_coins_for(1), -1, "未通关 → -1")
	assert_eq(_save.best_coins_for(2), -1, "未通关 → -1")
	assert_eq(_save.best_coins_for(3), -1, "未通关 → -1")
	assert_false(_save.fullscreen, "默认窗口化")


func test_save_and_load_round_trip() -> void:
	_save.unlocked_level = 2
	_save.best_coins[1] = 7
	_save.fullscreen = true
	_save.save()
	var reloaded := SaveData.new(TEMP_PATH)
	assert_eq(reloaded.unlocked_level, 2, "unlocked_level 往返")
	assert_eq(reloaded.best_coins_for(1), 7, "best_coins 往返")
	assert_true(reloaded.fullscreen, "fullscreen 往返")
	assert_eq(reloaded.best_coins_for(2), -1, "未动过的关卡保持 -1")


func test_complete_level_unlocks_next_and_persists() -> void:
	_save.complete_level(1, 5)
	assert_eq(_save.unlocked_level, 2, "通关 1-1 → 解锁 2")
	assert_eq(_save.best_coins_for(1), 5, "记录本次金币")
	var reloaded := SaveData.new(TEMP_PATH)
	assert_eq(reloaded.unlocked_level, 2, "立即落盘：unlocked_level")
	assert_eq(reloaded.best_coins_for(1), 5, "立即落盘：best_coins")


func test_complete_level_caps_at_three() -> void:
	_save.complete_level(3, 4)
	assert_eq(_save.unlocked_level, 3, "终关通关后解锁上限为 3")


func test_complete_level_keeps_historical_best() -> void:
	_save.complete_level(1, 9)
	_save.complete_level(1, 4)
	assert_eq(_save.best_coins_for(1), 9, "best = 历史最高（不回退）")
	_save.complete_level(1, 12)
	assert_eq(_save.best_coins_for(1), 12, "更好的成绩会覆盖")


func _remove_temp() -> void:
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))
