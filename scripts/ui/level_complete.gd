extends CanvasLayer
## §10.6 关卡完成面板（layer 15）：成绩 + 金币计数（0.04 s/步、
## sfx_tick 音高 +0.03/步）+ 全收集徽章；末关为"全部通关"变体
## （总金币 = best_coins_1..3 之和，单按钮返回标题）。
## 由 level.gd 在旗杆事件后 add_child 并 setup()。

const PANEL_PATH := "res://assets/sprites/ui/ui_panel.png"
const COIN_ICON_PATH := "res://assets/sprites/ui/ui_coin.png"
const MASK_COLOR := Color(0x1a1c2c, 0.5)
const TITLE_COLOR := Color("#ffcd75")
const STAT_COLOR := Color("#f4f4f4")
const PERFECT_COLOR := Color("#a7f070")

const _COIN_ICON := preload(COIN_ICON_PATH)

var level_index := 1
var coins := 0
var total := 0
var time := 0.0
var deaths := 0

var _is_last := false
var _title_label: Label
var _coin_label: Label
var _time_label: Label
var _deaths_label: Label
var _perfect_label: Label
var _menu: MenuList
var _countup := 0
var _acc := 0.0
var _confetti: CPUParticles2D


func _ready() -> void:
	layer = 15
	_build_ui()
	# 默认（1-1 空成绩）——level.gd 会在 add_child 后调用 setup() 覆盖。
	setup(1, 0, int(Levels.META[1]["coins"]), 0.0, 0)


## 由 level.gd 调用（add_child 之后）：写入成绩并重建面板内容。
func setup(idx: int, coin_count: int, coin_total: int, t: float, d: int) -> void:
	level_index = idx
	coins = coin_count
	total = coin_total
	time = t
	deaths = d
	_is_last = idx >= Levels.MAPS.size()
	_countup = 0
	_acc = 0.0
	_refresh_text()


func _process(_delta: float) -> void:
	if _is_last or _menu == null:
		return
	if _countup >= coins:
		return
	_acc += _delta
	while _acc >= Tuning.COUNTUP_STEP and _countup < coins:
		_acc -= Tuning.COUNTUP_STEP
		_countup += 1
		Audio.play_sfx("sfx_tick", 1.0 + float(_countup) * Tuning.TICK_PITCH_STEP)
		_refresh_coin_label()


func _refresh_text() -> void:
	if _confetti != null:
		_confetti.emitting = _is_last
	_title_label.text = Strings.CLEAR_TITLE if not _is_last else Strings.ALL_CLEAR_TITLE
	_refresh_coin_label()
	var secs := int(floorf(maxf(time, 0.0)))
	_time_label.text = Strings.CLEAR_TIME % [secs / 60, secs % 60]
	_deaths_label.text = Strings.CLEAR_MISTAKES % deaths
	_perfect_label.visible = not _is_last and coins == total
	if _is_last:
		_menu.build([Strings.ALL_CLEAR_QUIT], [], false, 14.0, true, Tuning.RESULT_INPUT_GRACE)
	else:
		_menu.build([Strings.CLEAR_NEXT, Strings.CLEAR_REPLAY, Strings.CLEAR_TO_TITLE], [], true, 14.0, true, Tuning.RESULT_INPUT_GRACE)


func _refresh_coin_label() -> void:
	if _is_last:
		_coin_label.text = Strings.ALL_CLEAR_COINS % [total_coins_all(), total_possible()]
	else:
		_coin_label.text = Strings.CLEAR_COINS % [_countup, total]


func total_coins_all() -> int:
	# best_coins_for 未通关为 -1；防御性取 max（未通关的关不计入）。
	var sum := 0
	for i in Levels.MAPS.size():
		sum += int(maxf(float(Game.save.best_coins_for(i + 1)), 0.0))
	return sum

func total_possible() -> int:
	var sum := 0
	for i in Levels.MAPS.size():
		sum += int(Levels.META[i + 1]["coins"])
	return sum

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
	panel.position = Vector2(64, 30)
	panel.size = Vector2(192, 120)
	var sb := StyleBoxTexture.new()
	sb.texture = load(PANEL_PATH)
	sb.texture_margin_left = 4.0
	sb.texture_margin_right = 4.0
	sb.texture_margin_top = 4.0
	sb.texture_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", sb)
	ui.add_child(panel)

	_title_label = Label.new()
	_title_label.position = Vector2(64, 38)
	_title_label.size = Vector2(192, 32)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT_SIZE)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	ui.add_child(_title_label)

	var coin_icon := TextureRect.new()
	coin_icon.texture = _COIN_ICON
	coin_icon.position = Vector2(88, 72)
	coin_icon.custom_minimum_size = Vector2(8, 8)
	ui.add_child(coin_icon)

	_coin_label = Label.new()
	_coin_label.position = Vector2(100, 72)
	_coin_label.size = Vector2(140, 16)
	_coin_label.add_theme_color_override("font_color", STAT_COLOR)
	ui.add_child(_coin_label)

	_time_label = Label.new()
	_time_label.position = Vector2(88, 86)
	_time_label.size = Vector2(140, 16)
	_time_label.add_theme_color_override("font_color", STAT_COLOR)
	ui.add_child(_time_label)

	_deaths_label = Label.new()
	_deaths_label.position = Vector2(88, 100)
	_deaths_label.size = Vector2(140, 16)
	_deaths_label.add_theme_color_override("font_color", STAT_COLOR)
	ui.add_child(_deaths_label)

	_perfect_label = Label.new()
	_perfect_label.text = Strings.CLEAR_PERFECT
	_perfect_label.position = Vector2(200, 72)
	_perfect_label.size = Vector2(80, 16)
	_perfect_label.add_theme_color_override("font_color", PERFECT_COLOR)
	_perfect_label.visible = false
	ui.add_child(_perfect_label)

	_menu = MenuList.new()
	_menu.position = Vector2(160, 124)
	ui.add_child(_menu)
	_menu.accepted.connect(_do_action)
	# M8/§10.10: 末关连续彩带雨（emitting 由 _refresh_text 按 _is_last 开关）。
	var confetti := CPUParticles2D.new()
	confetti.position = Vector2(160, 10)
	confetti.emitting = false
	confetti.one_shot = false
	confetti.amount = 40
	confetti.lifetime = 1.2
	confetti.direction = Vector2(0, 1)
	confetti.spread = 40.0
	confetti.initial_velocity_min = 40.0
	confetti.initial_velocity_max = 90.0
	confetti.gravity = Vector2(0, 120)
	var ctex := load("res://assets/sprites/fx/confetti_px.png") as Texture2D
	if ctex != null:
		confetti.texture = ctex
	confetti.color_ramp = OneShotFx.confetti_ramp()
	add_child(confetti)
	_confetti = confetti


func _do_action(idx: int) -> void:
	if Game.smoke_mode:
		print("COMPLETE ACTION: %s" % ["next", "replay", "title"][clampi(idx, 0, 2)])
		return
	if _is_last:
		Game.go_title()
		return
	match idx:
		0:
			Game.start_level(level_index + 1)
		1:
			Game.restart_level()
		2:
			Game.go_title()
