class_name CameraFollow
extends Camera2D
## §9.6：平滑跟随 + look-ahead（Tuning.CAMERA_SMOOTHING 可整体关闭，见 D13）。
## 挂在关卡根节点下（不是 Player 子节点）：drag/limit 以世界坐标解释，
## 与关卡边界一致，无需每帧换算。每帧手动 lerp `position`，不依赖 camera 内建
## 平滑（内建平滑跟随"父节点"，而这里跟随任意 Player）。

var player: Node2D = null
## 当前 look-ahead 偏移（像素）。
var look_ahead := 0.0
## §8 M5: 玩家死亡后冻结相机（不再跟随，位置保持死亡瞬间）。
var frozen := false

var _look_target := 0.0


func _ready() -> void:
	position_smoothing_enabled = Tuning.CAMERA_SMOOTHING
	position_smoothing_speed = Tuning.CAMERA_SMOOTHING_SPEED
	drag_horizontal_enabled = true
	drag_left_margin = Tuning.DRAG_LR
	drag_right_margin = Tuning.DRAG_LR
	drag_vertical_enabled = true
	drag_top_margin = Tuning.DRAG_TOP
	drag_bottom_margin = Tuning.DRAG_BOTTOM
	limit_smoothed = true
	snap_to_player()


func _physics_process(delta: float) -> void:
	if frozen or not is_instance_valid(player):
		return
	var cb := player as CharacterBody2D
	if absf(cb.velocity.x) > Tuning.LOOK_AHEAD_MIN_VX:
		_look_target = float(cb.facing) * Tuning.LOOK_AHEAD
	else:
		_look_target = 0.0
	look_ahead = lerpf(look_ahead, _look_target, 1.0 - exp(-Tuning.LOOK_AHEAD_RATE * delta))
	var target := player.global_position + Vector2(look_ahead, Tuning.CAMERA_Y_OFFSET)
	if Tuning.CAMERA_SMOOTHING:
		position = position.lerp(target, 1.0 - exp(-Tuning.CAMERA_SMOOTHING_SPEED * delta))
	else:
		position = target


## 关卡加载 / 重生时立即对位（无平滑过渡）。
func snap_to_player() -> void:
	look_ahead = 0.0
	_look_target = 0.0
	if is_instance_valid(player):
		position = player.global_position + Vector2(0.0, Tuning.CAMERA_Y_OFFSET)
	reset_smoothing()
