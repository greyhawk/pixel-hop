extends CanvasLayer
## §10.4 关内暂停菜单（layer 15）：Esc/P 开关（暂停时按 pause 恢复），
## 打开即暂停整棵树并 BGM 降 -10 dB；继续 / 重新开始本关 / 返回标题。

const PANEL_PATH := "res://assets/sprites/ui/ui_panel.png"
const MASK_COLOR := Color(0x1a1c2c, 0.6)
const TITLE_COLOR := Color("#f4f4f4")
const DUCK_DB := -10

var _menu: MenuList
var _enabled := true


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_menu.accepted.connect(_do_action)
	visible = false


## 通关流程（旗杆→结算面板）期间禁用开关，避免结算中误触暂停。
func set_enabled(v: bool) -> void:
	_enabled = v


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event.is_action_pressed("pause"):
		if visible:
			_do_action(0)
		else:
			_open()
		return
	if event.is_action_pressed("ui_cancel") and visible:
		_do_action(0)


func _build_ui() -> void:
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UiTheme.build()
	add_child(ui)

	var mask := ColorRect.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.color = MASK_COLOR
	ui.add_child(mask)

	var panel := Panel.new()
	panel.position = Vector2(80, 40)
	panel.size = Vector2(160, 100)
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_PATH)
	sb.texture_margin_left = 4.0
	sb.texture_margin_right = 4.0
	sb.texture_margin_top = 4.0
	sb.texture_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", sb)
	ui.add_child(panel)

	var title := Label.new()
	title.text = Strings.PAUSE_TITLE
	title.position = Vector2(80, 48)
	title.size = Vector2(160, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	ui.add_child(title)

	_menu = MenuList.new()
	_menu.position = Vector2(160, 68)
	ui.add_child(_menu)
	_menu.build([Strings.PAUSE_RESUME, Strings.PAUSE_RESTART, Strings.PAUSE_QUIT], [], false, 14.0, true)

	var hint := KeyHint.new()
	hint.position = Vector2(80, 122)
	hint.size = Vector2(160, 16)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.set_hint(Strings.HINT_PAUSE)
	ui.add_child(hint)


func _open() -> void:
	visible = true
	get_tree().paused = true
	Audio.play_sfx("sfx_pause")
	Audio.duck_music(DUCK_DB)
	_menu.mark_opened()


func _do_action(idx: int) -> void:
	if Game.smoke_mode:
		print("PAUSE ACTION: %s" % ["resume", "restart", "title"][clampi(idx, 0, 2)])
		return
	get_tree().paused = false
	Audio.duck_music(0)
	match idx:
		0:
			visible = false
			Audio.play_sfx("sfx_ui_back")
		1:
			Game.restart_level()
		2:
			Game.go_title()
