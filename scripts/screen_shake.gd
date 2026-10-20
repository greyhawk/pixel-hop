class_name ScreenShake
extends Node2D
## §9.6 屏幕震动：shake(振幅, 时长) 后每 SHAKE_RESAMPLE(1/30 s) 重采样一次
## 随机整数偏移；剩余时长按线性衰减，当前偏移幅值 <= 当前峰值振幅。
## 多次叠加取最大振幅（及最长剩余时长）。偏移镜像到相机的 CameraFollow.offset。
## offset / amplitude 暴露为公开字段，便于无相机环境下做解析断言（§15.4）。

## 由 Level 注入的目标相机（可空：测试或无相机时不镜像）。
var camera: CameraFollow = null
## 当前峰值振幅（px）。测试读取，验证“叠加取最大”。
var amplitude: float = 0.0
## 当前整数偏移（px）。每个分量均为整数且 |v| <= amplitude。测试断言用。
var offset: Vector2 = Vector2.ZERO

var _duration: float = 0.0
var _remaining: float = 0.0
var _resample_acc: float = 0.0


func shake(amplitude_in: float, duration_in: float) -> void:
	if duration_in <= 0.0:
		return
	var amp := float(amplitude_in)
	var dur := float(duration_in)
	if amp >= amplitude:
		# 新振幅更大（或首次）：整体取新参数。
		amplitude = amp
		_duration = dur
		_remaining = dur
	elif dur > _remaining:
		# 振幅更小但剩余更久：保留峰值，延长剩余。
		_remaining = dur
		_duration = maxf(_duration, dur)
	_resample_acc = 0.0
	_apply()


func _apply() -> void:
	if _remaining <= 0.0:
		amplitude = 0.0
		_duration = 0.0
		offset = Vector2.ZERO
		_mirror_camera()
		return
	var a := int(roundf(amplitude * _remaining / _duration))
	a = clampi(a, 0, int(roundf(amplitude)))
	offset = Vector2(randi_range(-a, a), randi_range(-a, a))
	_mirror_camera()


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = 0.0
		_apply()
		return
	_resample_acc += delta
	while _resample_acc >= Tuning.SHAKE_RESAMPLE:
		_resample_acc -= Tuning.SHAKE_RESAMPLE
		_apply()


func _mirror_camera() -> void:
	if camera != null and is_instance_valid(camera):
		camera.offset = offset
