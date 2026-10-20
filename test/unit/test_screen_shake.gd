extends GutTest
## M8: 屏幕震动解析断言（§15.4）。ScreenShake 不入场景树——手动驱动 _process，
## 断言 offset 每个分量为整数、幅值 <= 振幅、超时归零、多次叠加取最大振幅。


func test_shake_offset_integer_and_bounded() -> void:
	var s := ScreenShake.new()
	s.shake(2.0, 0.12)
	assert_eq(s.amplitude, 2.0, "peak amplitude adopted")
	assert_true(s.offset.x == floorf(s.offset.x), "x is integer")
	assert_true(s.offset.y == floorf(s.offset.y), "y is integer")
	assert_true(absf(s.offset.x) <= s.amplitude, "x within amplitude")
	assert_true(absf(s.offset.y) <= s.amplitude, "y within amplitude")
	s.free()


func test_shake_overlap_takes_max_amplitude() -> void:
	var s := ScreenShake.new()
	s.shake(2.0, 0.12)
	s.shake(5.0, 0.3)
	assert_eq(s.amplitude, 5.0, "overlap keeps max amplitude")
	assert_true(absf(s.offset.x) <= 5.0, "x within max amplitude")
	assert_true(absf(s.offset.y) <= 5.0, "y within max amplitude")
	s.free()


func test_shake_times_out_to_zero() -> void:
	var s := ScreenShake.new()
	s.shake(3.0, 0.3)
	for i in 60:
		s._process(1.0 / 60.0)
	assert_eq(s.offset, Vector2.ZERO, "offset zero after timeout")
	assert_eq(s.amplitude, 0.0, "amplitude zero after timeout")
	s.free()
