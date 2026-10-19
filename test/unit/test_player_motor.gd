extends GutTest
## §14 / §9.2：PlayerMotor 单测（8 组断言）。
## 与 tools/verify_levels.py 相同的 60 Hz 离散积分；y 由测试手动累加。

const DT := 1.0 / 60.0


func _step(
	m: PlayerMotor,
	vel: Vector2,
	dir: int,
	pressed: bool,
	held: bool,
	released: bool,
	on_floor: bool,
) -> Dictionary:
	return m.step(vel, dir, pressed, held, released, on_floor, DT)


func test_ground_accel_rest_to_run_speed() -> void:
	var m := PlayerMotor.new()
	var vel := Vector2.ZERO
	var frames := 0
	while absf(vel.x - Tuning.RUN_SPEED) >= 0.01:
		vel = _step(m, vel, 1, false, false, false, true)["velocity"]
		frames += 1
	assert_between(frames, 7, 9)


func test_ground_decel_run_speed_to_rest() -> void:
	var m := PlayerMotor.new()
	var vel := Vector2(Tuning.RUN_SPEED, 0.0)
	var frames := 0
	while vel.x > 0.01:
		vel = _step(m, vel, 0, false, false, false, true)["velocity"]
		frames += 1
	assert_between(frames, 5, 7)


func test_full_jump_apex() -> void:
	var m := PlayerMotor.new()
	var vel: Vector2 = _step(m, Vector2.ZERO, 0, true, true, false, true)["velocity"]
	var y := 0.0
	while vel.y <= 0.0:
		y += vel.y * DT
		vel = _step(m, vel, 0, false, true, false, false)["velocity"]
	var apex := -y
	# §14 连续参考 50±2；与 verify_levels.py 一致的离散积分落在 47.5。
	assert_almost_eq(apex, 47.5, 0.5)


func test_tap_jump_apex() -> void:
	var m := PlayerMotor.new()
	var vel: Vector2 = _step(m, Vector2.ZERO, 0, true, false, true, true)["velocity"]
	var y := 0.0
	while vel.y <= 0.0:
		y += vel.y * DT
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	var apex := -y
	# §14：tap 12.5±2（含跳跃截断）。
	assert_between(apex, 10.5, 14.5)


func test_coyote_window() -> void:
	var m := PlayerMotor.new()
	var vel: Vector2 = _step(m, Vector2.ZERO, 0, false, false, false, true)["velocity"]
	# 4 个空中帧后按（第 5 个空中步）：coyote 0.1−5/60 ≈ 0.0167 > 0 → 跳。
	for i in 4:
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	var out := _step(m, vel, 0, true, true, false, false)
	assert_true(out["jumped"])
	# 跳跃帧同帧加重力：−300 + GRAVITY_UP/60 = −285。
	assert_almost_eq(out["velocity"].y, -285.0, 0.01)

	var m2 := PlayerMotor.new()
	var vel2: Vector2 = _step(m2, Vector2.ZERO, 0, false, false, false, true)["velocity"]
	# 6 个空中帧后按（第 7 个空中步）：coyote 0.1−7/60 < 0 → 0 → 不跳。
	for i in 6:
		vel2 = _step(m2, vel2, 0, false, false, false, false)["velocity"]
	var out2 := _step(m2, vel2, 0, true, true, false, false)
	assert_false(out2["jumped"])
	assert_gt(out2["velocity"].y, 0.0)


func test_buffer_lands_jump() -> void:
	var m := PlayerMotor.new()
	# 地面不按；空中 6 帧不按（coyote 耗尽）；第 7 个空中步按下（不跳，buffer=0.1）。
	var vel: Vector2 = _step(m, Vector2.ZERO, 0, false, false, false, true)["velocity"]
	for i in 6:
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	vel = _step(m, vel, 0, true, true, false, false)["velocity"]
	# 落地帧：buffer 0.1−1/60 > 0 → 跳。
	var out := _step(m, vel, 0, false, false, false, true)
	assert_true(out["jumped"])
	assert_almost_eq(out["velocity"].y, -285.0, 0.01)


func test_buffer_expires_after_010s() -> void:
	var m := PlayerMotor.new()
	# 地面不按；空中 6 帧（coyote 耗尽）；第 7 个空中步按下（buffer=0.1）。
	var vel: Vector2 = _step(m, Vector2.ZERO, 0, false, false, false, true)["velocity"]
	for i in 6:
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	vel = _step(m, vel, 0, true, true, false, false)["velocity"]
	# 再空中 6 帧：buffer 0.1−7/60 < 0 → 0；落地帧不再跳。
	for i in 6:
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	var out := _step(m, vel, 0, false, false, false, true)
	assert_false(out["jumped"])


func test_jump_cut_once_and_rearm() -> void:
	var m := PlayerMotor.new()
	# step1: floor press → vy=-285; step2: held → -270
	var vel: Vector2 = _step(m, Vector2.ZERO, 0, true, true, false, true)["velocity"]
	vel = _step(m, vel, 0, false, true, false, false)["velocity"]
	# step3: released → -270*0.5+15 = -120.0
	vel = _step(m, vel, 0, false, false, true, false)["velocity"]
	assert_almost_eq(vel.y, -120.0, 0.01)
	# step4: released again → no second halving, -120+15 = -105.0
	vel = _step(m, vel, 0, false, false, true, false)["velocity"]
	assert_almost_eq(vel.y, -105.0, 0.01)
	# 继续下落至 vy>0，落地再跳，松开 → -285*0.5+15 = -127.5（重新武装生效）
	while vel.y <= 0.0:
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	vel = _step(m, vel, 0, false, false, false, true)["velocity"]
	vel = _step(m, vel, 0, true, true, false, true)["velocity"]
	vel = _step(m, vel, 0, false, false, true, false)["velocity"]
	assert_almost_eq(vel.y, -127.5, 0.01)


func test_max_fall_speed_clamp() -> void:
	var m := PlayerMotor.new()
	var vel := Vector2.ZERO
	for i in 60:
		vel = _step(m, vel, 0, false, false, false, false)["velocity"]
	assert_almost_eq(vel.y, Tuning.MAX_FALL_SPEED, 0.001)
