class_name SaveData
extends RefCounted
## §9.7: 存档读写（ConfigFile）。路径可注入——默认 user://save.cfg，
## GUT / 冒烟测试传临时路径并在 after_each / 检查后删除。
## 节：progress（unlocked_level / best_coins_1..3）+ settings（fullscreen）。
## 未通关的关卡 best_coins = -1（选关界面显示 --/N，§9.7）。

var path: String
var unlocked_level := 1
var best_coins: Dictionary = { 1: -1, 2: -1, 3: -1 }
var fullscreen := false


func _init(p: String = "user://save.cfg") -> void:
	path = p
	reload()


## 从盘上读档；文件不存在 / 不可读时保持当前（默认）值。
func reload() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	unlocked_level = int(cfg.get_value("progress", "unlocked_level", 1))
	for i in 3:
		best_coins[i + 1] = int(cfg.get_value("progress", "best_coins_%d" % (i + 1), -1))
	fullscreen = bool(cfg.get_value("settings", "fullscreen", false))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	for i in 3:
		cfg.set_value("progress", "best_coins_%d" % (i + 1), int(best_coins[i + 1]))
	cfg.set_value("settings", "fullscreen", fullscreen)
	if cfg.save(path) != OK:
		push_error("SaveData: failed to save %s" % path)


## §9.7: 通关第 N 关——unlocked_level = max(旧, min(N+1, 3))、
## best_coins_N = max(旧, 本次金币数)。写完立即落盘。
func complete_level(level: int, coins: int) -> void:
	unlocked_level = maxi(unlocked_level, mini(level + 1, 3))
	best_coins[level] = maxi(int(best_coins[level]), coins)
	save()


## 第 N 关的历史最佳金币数；-1 = 从未通关（面板显示 --/N）。
func best_coins_for(level: int) -> int:
	return int(best_coins.get(level, -1))
