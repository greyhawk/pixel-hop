class_name KeyHint
extends HBoxContainer
## §10.1 按键提示行：解析 `[A][B] 文字`——方括号变键帽
## （ui_keycap 9-slice、内 12px `#1a1c2c` 字），其余为普通文字。
## 源文本中的全角空格即间距。

const KEYCAP_PATH := "res://assets/sprites/ui/ui_keycap.png"
const KEYCAP_MARGIN := 2.0
const KEYCAP_TEXT_COLOR := Color("#1a1c2c")

var _cap_tex: Texture2D
var _text_color := Color("#94b0c2")


func _ready() -> void:
	_cap_tex = load(KEYCAP_PATH)


func set_hint_color(c: Color) -> void:
	_text_color = c


## text 形如 "[↑][↓] 选择    [Enter] 确认"；整行重建。
func set_hint(text: String) -> void:
	for c in get_children():
		c.queue_free()
	var plain := ""
	var cap_text := ""
	var in_cap := false
	for ch in text:
		if ch == "[":
			if plain != "":
				_append_plain(plain)
				plain = ""
			in_cap = true
			cap_text = ""
		elif ch == "]":
			_append_cap(cap_text)
			in_cap = false
		elif in_cap:
			cap_text += ch
		else:
			plain += ch
	if plain != "":
		_append_plain(plain)


func _append_plain(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", _text_color)
	add_child(lbl)


func _append_cap(text: String) -> void:
	var panel := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = _cap_tex
	sb.texture_margin_left = KEYCAP_MARGIN
	sb.texture_margin_right = KEYCAP_MARGIN
	sb.texture_margin_top = KEYCAP_MARGIN
	sb.texture_margin_bottom = KEYCAP_MARGIN
	panel.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", KEYCAP_TEXT_COLOR)
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 0)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)
	add_child(panel)
