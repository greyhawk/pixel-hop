extends CanvasLayer
## §10.5 选关弹窗：盖在标题上（layer 15）。行 = 3 关，锁定时 #566c86
## + 行末 ui_lock 小锁；金币列来自 SaveData.best_coins_for（-1 → "--"）。

signal closed

const PANEL_PATH := "res://assets/sprites/ui/ui_panel.png"
const LOCK_PATH := "res://assets/sprites/ui/ui_lock.png"
const MASK_COLOR := Color(0x1a1c2c, 0.6)
const TITLE_COLOR := Color("#f4f4f4")

const _LOCK := preload(LOCK_PATH)

var _menu: MenuList
var _ui: Control


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_menu.accepted.connect(_do_action)
	_menu.mark_opened()


## Esc 关闭弹窗（标题菜单仍在下方，只是禁用了输入）。
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()


func close() -> void:
	Audio.play_sfx("sfx_ui_back")
	closed.emit()
	queue_free()


func _build_ui() -> void:
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = UiTheme.build()
	add_child(_ui)

	var mask := ColorRect.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.color = MASK_COLOR
	_ui.add_child(mask)

	var panel := Panel.new()
	panel.position = Vector2(60, 36)
	panel.size = Vector2(200, 108)
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_PATH)
	sb.texture_margin_left = 4.0
	sb.texture_margin_right = 4.0
	sb.texture_margin_top = 4.0
	sb.texture_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", sb)
	_ui.add_child(panel)

	var title := Label.new()
	title.text = Strings.SELECT_TITLE
	title.position = Vector2(60, 44)
	title.size = Vector2(200, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	_ui.add_child(title)

	_menu = MenuList.new()
	_menu.position = Vector2(84, 66)
	_ui.add_child(_menu)
	_menu.build(_rows(), _locked_flags(), false, 16.0, false)
	_build_lock_icons()

	var hint := KeyHint.new()
	hint.position = Vector2(60, 126)
	hint.size = Vector2(200, 16)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.set_hint(Strings.HINT_SELECT)
	_ui.add_child(hint)


func _rows() -> Array:
	var out: Array = []
	for i in Levels.MAPS.size():
		var meta: Dictionary = Levels.META[i + 1]
		var best := Game.save.best_coins_for(i + 1)
		var best_s: String = str(best) if best >= 0 else "--"
		out.append("%s  %s    金币 %s/%d" % [meta["id"], meta["name"], best_s, meta["coins"]])
	return out


func _locked_flags() -> Array:
	var out: Array = []
	for i in Levels.MAPS.size():
		out.append(i + 1 > Game.save.unlocked_level)
	return out


func _build_lock_icons() -> void:
	for i in Levels.MAPS.size():
		if not _locked_flags()[i]:
			continue
		var t := TextureRect.new()
		t.texture = _LOCK
		t.custom_minimum_size = Vector2(8, 8)
		var p := _menu.row_position(i)
		t.position = Vector2(84.0 + _menu.row_size(i).x + 4.0, 66.0 + 16.0 * float(i))
		_ui.add_child(t)


func _do_action(idx: int) -> void:
	if Game.smoke_mode:
		print("SELECT ACTION: level %d" % (idx + 1))
		return
	# 选关入口 = 新游戏（命数=3），从第 idx+1 关开始（D24）。
	Game.start_new_game(idx + 1)
