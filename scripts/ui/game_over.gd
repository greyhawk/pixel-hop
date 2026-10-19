extends Control
## §10.7 游戏结束界面：深底全屏 + 红色标题 + 提示文本 +
## 两行菜单（重试本关 / 返回标题，0.6 s 确认保护）+ 按键提示。
## 重试本关 → Game.retry_after_game_over()（命数=3、重进当前关，D23）。
## 0.5 s 淡入（本地时长，§10.7）。
const BG_COLOR := Color("#1a1c2c")
const TITLE_COLOR := Color("#b13e53")
const TEXT_COLOR := Color("#94b0c2")
const HINT_COLOR := Color("#8b8ba4")

var _menu: MenuList


func _ready() -> void:
	theme = UiTheme.build()
	_build_ui()
	modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.5)
	Audio.stop_bgm()
	Audio.play_sfx("jingle_game_over")

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = BG_COLOR
	add_child(bg)

	var title := Label.new()
	title.text = Strings.GAMEOVER_TITLE
	title.position = Vector2(0, 52)
	title.size = Vector2(320, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	add_child(title)

	var text := Label.new()
	text.text = Strings.GAMEOVER_TEXT
	text.position = Vector2(0, 84)
	text.size = Vector2(320, 16)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(text)

	_menu = MenuList.new()
	_menu.position = Vector2(160, 112)
	add_child(_menu)
	_menu.build([Strings.GAMEOVER_RETRY, Strings.GAMEOVER_QUIT], [], false, 14.0, true, Tuning.RESULT_INPUT_GRACE)
	_menu.accepted.connect(_do_action)

	var hint := KeyHint.new()
	hint.position = Vector2(0, 152)
	hint.size = Vector2(320, 16)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.set_hint(Strings.HINT_TITLE)
	hint.set_hint_color(HINT_COLOR)
	add_child(hint)


func _do_action(idx: int) -> void:
	if Game.smoke_mode:
		print("GAMEOVER ACTION: %s" % ["retry", "quit"][clampi(idx, 0, 1)])
		return
	if idx == 0:
		Game.retry_after_game_over()
	else:
		Game.go_title()
