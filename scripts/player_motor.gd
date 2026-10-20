class_name PlayerMotor
extends RefCounted
## §9.2：纯运动学（RefCounted，不挂场景树，便于单测）。
## 持有 coyote / buffer / 跳跃截断状态；`step` 是唯一入口。
##
## 每物理帧顺序（与 tools/verify_levels.py 的离散积分顺序一致）：
##   1. 水平 move_toward（地面/空中 × 加速/减速）
##   2. coyote / buffer 计时器
##   3. 跳跃判定（buffered + coyote 宽限）
##   4. 跳跃截断（上升中松开 jump，每次跳跃仅一次，先于重力）
##   5. 重力（vy<0 用 GRAVITY_UP，vy>=0 用 GRAVITY_DOWN，封顶 MAX_FALL_SPEED）
## 跳跃帧同样应用重力（第 5 步不跳过）。

var coyote := Tuning.COYOTE_TIME
var buffer := 0.0
var cut_armed := false


## M6 重生时恢复初始状态。
func reset() -> void:
	coyote = Tuning.COYOTE_TIME
	buffer = 0.0
	cut_armed = false


## `dir` ∈ {-1, 0, 1}；`jump_pressed` / `jump_released` 为本帧边沿；
## `jump_held` 保留参数（§14 接口），运动学本身不依赖它。
## 返回 {"velocity": Vector2, "jumped": bool}。
func step(
	vel: Vector2,
	dir: int,
	jump_pressed: bool,
	_jump_held: bool,
	jump_released: bool,
	on_floor: bool,
	delta: float,
) -> Dictionary:
	var vx := vel.x
	var vy := vel.y
	# 1. 水平
	var accel := Tuning.AIR_DECEL
	if dir != 0:
		accel = Tuning.GROUND_ACCEL if on_floor else Tuning.AIR_ACCEL
	elif on_floor:
		accel = Tuning.GROUND_DECEL
	vx = move_toward(vx, float(dir) * Tuning.RUN_SPEED, accel * delta)
	# 2. coyote + buffer
	if on_floor:
		coyote = Tuning.COYOTE_TIME
	else:
		coyote = maxf(coyote - delta, 0.0)
	if jump_pressed:
		buffer = Tuning.JUMP_BUFFER
	else:
		buffer = maxf(buffer - delta, 0.0)
	# 3. 跳跃（buffer > 0 且 在地面或 coyote 宽限内）
	var jumped := false
	if buffer > 0.0 and (on_floor or coyote > 0.0):
		vy = Tuning.JUMP_VELOCITY
		jumped = true
		cut_armed = true
		buffer = 0.0
	# 4. 跳跃截断：上升中松开，每次跳只触发一次
	if cut_armed and jump_released and vy < 0.0:
		vy *= Tuning.JUMP_CUT
		cut_armed = false
	# 5. 重力
	var g := Tuning.GRAVITY_UP if vy < 0.0 else Tuning.GRAVITY_DOWN
	vy = minf(vy + g * delta, Tuning.MAX_FALL_SPEED)
	return {"velocity": Vector2(vx, vy), "jumped": jumped}
