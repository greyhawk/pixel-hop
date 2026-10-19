class_name Level
extends Node2D
## §7 / §8: Level scene root. `level_index` is a Levels.MAPS key (1-3).
## Children (Terrain, Decor, Entities, Bounds, Camera) are built in
## _ready by LevelBuilder — set level_index before add_child.
## M5: 掉坑检测（Bounds 底 + PIT_MARGIN）、死亡时 lives −= 1 + 相机冻结 +
## 发 player_died（重生/结算面板 = M6/M7）。

signal player_died

var level_index: int = 1
var lives := Tuning.START_LIVES

var _player: Player
var _camera: CameraFollow


func _ready() -> void:
	LevelBuilder.build(self, level_index)
	_player = get_node_or_null("Entities/Player") as Player
	_camera = get_node_or_null("Camera") as CameraFollow
	if _player:
		_player.died.connect(_on_player_died)


func _on_player_died() -> void:
	lives -= 1
	if _camera:
		_camera.frozen = true
	player_died.emit()


## 掉坑：玩家脚底越过关卡边界底 + PIT_MARGIN（§9.2）。
func _physics_process(_delta: float) -> void:
	if _player == null or _player.dead or _player.victory:
		return
	if _camera and _player.global_position.y > _camera.limit_bottom + Tuning.PIT_MARGIN:
		_player.die(true)


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
