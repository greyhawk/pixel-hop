extends Control
## §10.3 HUD（CanvasLayer layer=10）：心形血条 / 命数 / 金币 / 计时 /
## 关卡名横幅 / toast。全部运行时构建（UiTheme + assets/sprites/ui/*），
## 订阅 GameState 信号；金币 / 计时格式为 static，单测覆盖。

const HEART_FULL_PATH := "res://assets/sprites/ui/ui_heart_full.png"
const HEART_EMPTY_PATH := "res://assets/sprites/ui/ui_heart_empty.png"
const LIFE_ICON_PATH := "res://assets/sprites/ui/ui_life.png"
const COIN_ICON_PATH := "res://assets/sprites/ui/ui_coin.png"

const HEART_BLINK_TIME := 0.08
const HEART_BLINK_CYCLES := 3
const COIN_BOUNCE_TIME := 0.1
const METER_COLOR := Color("#94b0c2")
const BANNER_BG := Color(0x1a1c2c, 0.6)
const BANNER_COLOR := Color("#f4f4f4")

const _HEART_FULL := preload(HEART_FULL_PATH)
const _HEART_EMPTY := preload(HEART_EMPTY_PATH)
const _LIFE_ICON := preload(LIFE_ICON_PATH)
const _COIN_ICON := preload(COIN_ICON_PATH)

var _hearts: Array[TextureRect] = []
var _hearts_row: HBoxContainer
var _lives_label: Label
var _coin_label: Label
var _coin_icon: TextureRect
var _timer_label: Label
var _banner_rect: ColorRect
var _banner_label: Label
var _toast_label: Label
var _banner_tween: Tween
var _banner_active := false
var _prev_hp := -1
var _prev_coins := -1
var _coin_base_y := 0.0


func _ready() -> void:
	theme = UiTheme.build()
	_build_heart_row()
	_build_lives()
	_build_coins()
	_build_timer()
	_build_banner()
	_build_toast()
	if Game.state != null:
		Game.state.hp_changed.connect(_on_hp_changed)
		Game.state.lives_changed.connect(_on_lives_changed)
		Game.state.coins_changed.connect(_on_coins_changed)
		_on_hp_changed(Game.state.hp)
		_on_lives_changed(Game.state.lives)
		_on_coins_changed(Game.state.coins_this_level)
		if Game.state.current_level in Levels.META:
			_show_banner(Levels.META[Game.state.current_level])


func _process(_delta: float) -> void:
	if _timer_label != null and Game.state != null:
		_timer_label.text = format_time(Game.state.level_time)


## §10.3 通用 toast 入口（M7 无调用方，保留备用）。
func show_toast(text: String) -> void:
	if _toast_label == null:
		return
	_toast_label.text = text
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(Tuning.TOAST_SHOW)
	tw.tween_property(_toast_label, "modulate:a", 0.0, Tuning.TOAST_FADE)
	tw.tween_callback(_toast_label.hide)


# --- 静态格式化（单测对象） ---

static func format_coin_count(current: int, total: int) -> String:
	return "%02d/%02d" % [current, total]


static func format_time(seconds: float) -> String:
	var s := int(floorf(maxf(seconds, 0.0)))
	return "%02d:%02d" % [s / 60, s % 60]


# --- 构建 ---

func _build_heart_row() -> void:
	_hearts_row = HBoxContainer.new()
	_hearts_row.position = Vector2(6, 6)
	_hearts_row.add_theme_constant_override("separation", 2)
	add_child(_hearts_row)
	for i in Tuning.MAX_HP:
		var t := TextureRect.new()
		t.texture = _HEART_FULL
		t.custom_minimum_size = Vector2(8, 8)
		_hearts_row.add_child(t)
		_hearts.append(t)


func _build_lives() -> void:
	var icon := TextureRect.new()
	icon.texture = _LIFE_ICON
	icon.position = Vector2(6, 18)
	icon.custom_minimum_size = Vector2(8, 8)
	add_child(icon)
	_lives_label = Label.new()
	_lives_label.position = Vector2(16, 16)
	_lives_label.size = Vector2(30, 16)
	_lives_label.add_theme_color_override("font_color", METER_COLOR)
	add_child(_lives_label)


func _build_coins() -> void:
	var row := HBoxContainer.new()
	row.anchor_left = 1.0
	row.anchor_right = 1.0
	row.offset_left = -52.0
	row.offset_top = 4.0
	row.offset_right = -6.0
	row.offset_bottom = 20.0
	row.add_theme_constant_override("separation", 3)
	add_child(row)
	_coin_icon = TextureRect.new()
	_coin_icon.texture = _COIN_ICON
	_coin_icon.custom_minimum_size = Vector2(8, 8)
	row.add_child(_coin_icon)
	_coin_label = Label.new()
	_coin_label.custom_minimum_size = Vector2(40, 16)
	_coin_base_y = 0.0
	row.add_child(_coin_label)


func _build_timer() -> void:
	_timer_label = Label.new()
	_timer_label.anchor_left = 1.0
	_timer_label.anchor_right = 1.0
	_timer_label.offset_left = -52.0
	_timer_label.offset_top = 16.0
	_timer_label.offset_right = -6.0
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_color_override("font_color", METER_COLOR)
	add_child(_timer_label)


func _build_banner() -> void:
	_banner_rect = ColorRect.new()
	_banner_rect.position = Vector2(0, 62)
	_banner_rect.size = Vector2(320, 28)
	_banner_rect.color = BANNER_BG
	_banner_rect.visible = false
	add_child(_banner_rect)
	_banner_label = Label.new()
	_banner_label.position = Vector2(0, 2)
	_banner_label.size = Vector2(320, 32)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT_SIZE)
	_banner_label.add_theme_color_override("font_color", BANNER_COLOR)
	_banner_rect.add_child(_banner_label)


func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.position = Vector2(0, 40)
	_toast_label.size = Vector2(320, 16)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.visible = false
	add_child(_toast_label)


# --- 状态信号 ---

func _show_banner(meta: Dictionary) -> void:
	if _banner_rect == null:
		return
	_banner_label.text = "%s %s" % [meta["id"], meta["name"]]
	_banner_rect.modulate.a = 1.0
	_banner_rect.visible = true
	_banner_active = true
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(Tuning.BANNER_SHOW)
	_banner_tween.tween_property(_banner_rect, "modulate:a", 0.0, Tuning.BANNER_FADE)
	_banner_tween.tween_callback(_hide_banner)


func _hide_banner() -> void:
	_banner_rect.visible = false
	_banner_active = false


func _on_hp_changed(hp: int) -> void:
	for i in _hearts.size():
		_hearts[i].texture = _HEART_FULL if i < hp else _HEART_EMPTY
	# 掉血：丢失的那颗心 满↔空 闪 3 次后停在空（§10.3）。
	if _prev_hp >= 0 and hp < _prev_hp and hp < _hearts.size():
		var heart := _hearts[hp]
		var tw := create_tween()
		for i in HEART_BLINK_CYCLES:
			tw.tween_property(heart, "texture", _HEART_FULL, HEART_BLINK_TIME)
			tw.tween_property(heart, "texture", _HEART_EMPTY, HEART_BLINK_TIME)
	_prev_hp = hp


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = Strings.HUD_LIVES % lives


func _on_coins_changed(coins: int) -> void:
	var total := Game.state.coins_total_this_level if Game.state != null else 0
	_coin_label.text = format_coin_count(coins, total)
	if _prev_coins >= 0 and coins > _prev_coins:
		# 金币增加：数字上弹 2px、图标高亮闪一下（§10.3）。
		_coin_label.position.y = _coin_base_y - 2.0
		_coin_icon.modulate = Color(1.5, 1.5, 1.5)
		var tw := create_tween()
		tw.tween_property(_coin_label, "position:y", _coin_base_y, COIN_BOUNCE_TIME)
		tw.parallel().tween_property(_coin_icon, "modulate", Color.WHITE, COIN_BOUNCE_TIME)
	_prev_coins = coins
