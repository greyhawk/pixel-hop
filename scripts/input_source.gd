class_name InputSource
extends RefCounted
## §9.3：输入抽象。Player 每物理帧先调 `begin_frame()`（消除场景树顺序依赖），
## 再读方向 / jump 边沿与按住状态 / 下压。
##  - KeyboardInputSource：真实键盘（Game / Title）
##  - ScriptedInput：smoke 与未来回放用的可编程帧序列

## 每物理帧开始调用（键盘源为空操作；ScriptedInput 在此推进一帧）。
func begin_frame() -> void:
	pass


## 水平输入轴 ∈ [-1, 1]。
func get_axis() -> float:
	return 0.0


## 本帧按下边沿（跳帧判定）。
func jump_pressed() -> bool:
	return false


## 本帧松开边沿（跳跃截断）。
func jump_released() -> bool:
	return false


## 是否按住（drop-through 条件）。
func jump_held() -> bool:
	return false


## 是否按住下压。
func down_held() -> bool:
	return false


class KeyboardInputSource:
	extends InputSource

	func get_axis() -> float:
		return Input.get_axis("move_left", "move_right")

	func jump_pressed() -> bool:
		return Input.is_action_just_pressed("jump")

	func jump_released() -> bool:
		return Input.is_action_just_released("jump")

	func jump_held() -> bool:
		return Input.is_action_pressed("jump")

	func down_held() -> bool:
		return Input.is_action_pressed("move_down")


class ScriptedInput:
	extends InputSource
	## 帧序列：queue_frame(dir, jump, down)，jump ∈ "none" | "down" | "tap" | "up"；
	## down = 本帧按住 move_down（drop-through 用）。序列用完后保持最后一帧状态（无新边沿）。

	var _frames: Array[Dictionary] = []
	var _i := 0
	var _held := false
	var _axis := 0.0
	var _pressed := false
	var _released := false
	var _down := false

	func queue_frame(dir: int, jump: String = "none", down := false) -> void:
		_frames.append({"dir": dir, "jump": jump, "down": down})

	func begin_frame() -> void:
		if _i >= _frames.size():
			return
		var f: Dictionary = _frames[_i]
		_i += 1
		_axis = float(f["dir"])
		_down = bool(f["down"])
		_pressed = false
		_released = false
		match f["jump"]:
			"down":
				_held = true
				_pressed = true
			"tap":
				_pressed = true
				_released = true
			"up":
				if _held:
					_released = true
				_held = false

	func get_axis() -> float:
		return _axis

	func jump_pressed() -> bool:
		return _pressed

	func jump_released() -> bool:
		return _released

	func jump_held() -> bool:
		return _held

	func down_held() -> bool:
		return _down
