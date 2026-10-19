class_name MenuList
extends Control
## §10.1 键盘驱动菜单：条目为运行时 Label，双向环绕（跳过禁用项），
## 确认带打开宽限期（Tuning.MENU_INPUT_GRACE / RESULT_INPUT_GRACE）。
##
## 公开入口（smoke / 单测无真实输入也能驱动）：press_move(dir)、press_accept()。
## dir：纵向 -1 上 / +1 下；横向 -1 左 / +1 右。

signal accepted(index: int)

var items: Array[String] = []
var disabled: Array[bool] = []
var selected_index := 0
## 关闭后不再响应键盘（弹窗叠层时只让顶层菜单接收）。
var input_enabled := true
var horizontal := false
var pitch := 14.0
var h_gap := 16.0
var centered := false

const SELECTED_COLOR := Color("#ffcd75")
const NORMAL_COLOR := Color("#f4f4f4")
const DISABLED_COLOR := Color("#566c86")
const CURSOR_PATH := "res://assets/sprites/ui/ui_cursor.png"
const CURSOR_OFFSET := -10.0
const CURSOR_Y_OFFSET := 2.0
const CURSOR_PERIOD := 0.4

var _labels: Array[Label] = []
var _sizes: Array[Vector2] = []
var _cursor: TextureRect
var _time := 0.0
var _opened_at := -10_000_000
var _grace := Tuning.MENU_INPUT_GRACE


func _ready() -> void:
	_cursor = TextureRect.new()
	_cursor.texture = load(CURSOR_PATH)
	_cursor.visible = false
	_cursor.z_index = 10
	add_child(_cursor)


## 构建（或重建）条目并布局。grace 用 ms 前的 ticks 计时，宽限期后 ui_accept 才生效。
func build(items_arr: Array, disabled_arr: Array = [], horizontal_ := false, pitch_ := 14.0, centered_ := false, grace := Tuning.MENU_INPUT_GRACE) -> void:
	items = []
	for t in items_arr:
		items.append(str(t))
	disabled = []
	for i in items.size():
		disabled.append(bool(disabled_arr[i]) if i < disabled_arr.size() else false)
	horizontal = horizontal_
	pitch = pitch_
	centered = centered_
	_grace = grace
	selected_index = _first_enabled()
	for c in get_children():
		if c != _cursor:
			c.queue_free()
	_labels.clear()
	_sizes.clear()
	for i in items.size():
		var lbl := Label.new()
		lbl.text = items[i]
		_labels.append(lbl)
		_sizes.append(Vector2.ZERO)
		add_child(lbl)
	refresh_styles()
	_layout()
	mark_opened()


## 菜单（重新）可见时调用：重新开始确认宽限期计时。
func mark_opened() -> void:
	_opened_at = Time.get_ticks_msec()


func can_accept() -> bool:
	return selected_index < items.size() and not disabled[selected_index]


## 移动选择（立即生效、无宽限）。返回选择是否变化。
func press_move(dir: int) -> bool:
	var n := items.size()
	if n == 0:
		return false
	var from := selected_index
	var i := selected_index
	for _step in n:
		i = wrapi(i + dir, 0, n)
		if not disabled[i]:
			break
	if i != from:
		selected_index = i
		refresh_styles()
		Audio.play_sfx("sfx_ui_move")
	return i != from


## 确认（绕过宽限期，供 smoke / 单测）。禁用条目返回 -1 且不发射。
func press_accept() -> int:
	if not can_accept():
		return -1
	Audio.play_sfx("sfx_ui_confirm")
	accepted.emit(selected_index)
	return selected_index


func set_item_text(index: int, text: String) -> void:
	if index < 0 or index >= items.size():
		return
	items[index] = text
	_labels[index].text = text
	_layout()


func row_size(index: int) -> Vector2:
	if index < 0 or index >= _sizes.size():
		return Vector2.ZERO
	return _sizes[index]


func row_position(index: int) -> Vector2:
	if index < 0 or index >= _labels.size() or _labels[index] == null:
		return Vector2.ZERO
	return _labels[index].position


func _first_enabled() -> int:
	var i := 0
	while i < items.size() and disabled[i]:
		i += 1
	return mini(i, maxi(items.size() - 1, 0))


func _layout() -> void:
	var font := get_theme_font("font")
	var fs := get_theme_font_size("font_size")
	for i in _labels.size():
		if _labels[i] == null:
			continue
		_sizes[i] = Vector2(font.get_string_size(items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 16.0)
	if horizontal:
		var total := 0.0
		for s in _sizes:
			total += s.x
		if _sizes.size() > 1:
			total += h_gap * (_sizes.size() - 1)
		var x := -total / 2.0 if centered else 0.0
		for i in _labels.size():
			_labels[i].position = Vector2(x, 0.0)
			_labels[i].size = _sizes[i]
			x += _sizes[i].x + h_gap
	else:
		for i in _labels.size():
			_labels[i].position = Vector2(-_sizes[i].x / 2.0 if centered else 0.0, float(i) * pitch)
			_labels[i].size = _sizes[i]


func refresh_styles() -> void:
	for i in _labels.size():
		if _labels[i] == null:
			continue
		var c := NORMAL_COLOR
		if i < disabled.size() and disabled[i]:
			c = DISABLED_COLOR
		elif i == selected_index:
			c = SELECTED_COLOR
		_labels[i].add_theme_color_override("font_color", c)


func _process(_delta: float) -> void:
	_time += _delta
	if _cursor == null or items.is_empty() or not visible:
		return
	var idx := selected_index
	if idx < 0 or idx >= _labels.size() or _labels[idx] == null:
		return
	# 1 px 水平抖动，周期 0.4 s（0/1 交替）。
	var wobble := int(round(0.5 - 0.5 * cos(_time * TAU / CURSOR_PERIOD)))
	if horizontal:
		_cursor.position = Vector2(_labels[idx].position.x + CURSOR_OFFSET, _labels[idx].position.y + CURSOR_Y_OFFSET + float(wobble))
	else:
		_cursor.position = Vector2(_labels[idx].position.x + CURSOR_OFFSET + float(wobble), _labels[idx].position.y + CURSOR_Y_OFFSET)
	_cursor.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not visible or items.is_empty():
		return
	var dir := 0
	if horizontal:
		if event.is_action_pressed("ui_left"):
			dir = -1
		elif event.is_action_pressed("ui_right"):
			dir = +1
	else:
		if event.is_action_pressed("ui_up"):
			dir = -1
		elif event.is_action_pressed("ui_down"):
			dir = +1
	if dir != 0:
		press_move(dir)
	elif event.is_action_pressed("ui_accept") \
			and Time.get_ticks_msec() - _opened_at >= int(_grace * 1000.0):
		press_accept()
