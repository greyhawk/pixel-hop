class_name SignBubble
extends Node2D
## §10.8 木牌气泡：ui_panel_small 9-slice + 12px 文字自动换行（宽 140 px）
## + 底部中央小尾巴。玩家进入木牌触发器时 0.15 s 淡入 / 放大弹出，
## 离开即隐藏。

const PANEL_PATH := "res://assets/sprites/ui/ui_panel_small.png"
const TAIL_PATH := "res://assets/sprites/ui/ui_bubble_tail.png"
const PANEL_MARGIN := 4.0
const TEXT_MAX_WIDTH := 140.0

var _panel: PanelContainer
var _label: Label
var _tail: Sprite2D
var _tween: Tween


func _ready() -> void:
	_build()
	visible = false


## 显示气泡（0.15 s 淡入 + 0.8→1 放大）。不叫 show/hide：
## 4.7.2 解析器无法在成员访问中解析与 Node 内置方法同名的脚本方法。
func show_bubble(text: String) -> void:
	_label.text = text
	_panel.visible = true
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, Tuning.BUBBLE_TWEEN)
	_tween.parallel().tween_property(self, "scale", Vector2.ONE, Tuning.BUBBLE_TWEEN)
	_place_tail.call_deferred()


func hide_bubble() -> void:
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_PATH)
	sb.texture_margin_left = PANEL_MARGIN
	sb.texture_margin_right = PANEL_MARGIN
	sb.texture_margin_top = PANEL_MARGIN
	sb.texture_margin_bottom = PANEL_MARGIN
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(TEXT_MAX_WIDTH, -1)
	_panel.add_child(_label)

	# 尾巴与面板平级：气泡高度由文字决定，首帧布局后定位到底部中央。
	_tail = Sprite2D.new()
	_tail.texture = load(TAIL_PATH)
	_tail.centered = false
	add_child(_tail)


func _place_tail() -> void:
	if _tail == null or _tail.texture == null or not is_inside_tree():
		return
	var w := _panel.size.x
	var h := _panel.size.y
	_tail.position = Vector2(w / 2.0 - _tail.texture.get_width() / 2.0, h - _tail.texture.get_height() + 1.0)
