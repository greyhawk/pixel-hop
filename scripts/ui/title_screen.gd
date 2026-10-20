extends Node2D
## §10.2 标题界面：视差背景（5 层各双拷贝 320px 横滚）+
## Logo（24px 金色，2 s 周期轻浮动）+ 副标题 + MenuList（4 项）+ 按键提示 + 版本号。
## 全屏项文本随当前窗口模式切换（§10.2）。
const BG_PATHS := [
	"res://assets/bg/bg_sky.png",
	"res://assets/bg/bg_clouds.png",
	"res://assets/bg/bg_far_mountains.png",
	"res://assets/bg/bg_mid_hills.png",
]
const BG_Y := [0, 10, 70, 112]
const TILESET_PATH := "res://assets/tiles/tileset.png"
const LOGO_COLOR := Color("#ffcd75")
const SUBTITLE_COLOR := Color("#f4f4f4")
const VERSION_COLOR := Color("#566c86")

var _bg: Node2D
var _logo: Label
var _menu: MenuList
var _t := 0.0


func _ready() -> void:
	Audio.play_bgm("bgm_title")
	_build_bg()
	_build_ui()
	print("MAIN BOOT OK")


func _process(delta: float) -> void:
	_t += delta
	_bg.position.x -= Tuning.TITLE_SCROLL_SPEED * delta
	if _bg.position.x <= -320.0:
		_bg.position.x += 320.0
	_logo.position.y = 28.0 + int(round(sin(_t * TAU / 2.0)))


func _build_bg() -> void:
	_bg = Node2D.new()
	add_child(_bg)
	for i in BG_PATHS.size():
		var tex := load(BG_PATHS[i]) as Texture2D
		_add_layer(tex, Vector2(0, BG_Y[i]))
		_add_layer(tex, Vector2(320, BG_Y[i]))
	_add_layer(_grass_texture(), Vector2(0, 148))
	_add_layer(_grass_texture(), Vector2(320, 148))


func _add_layer(tex: Texture2D, at: Vector2) -> void:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.position = at
	_bg.add_child(rect)


## 底部草地条：tileset (1,0) 草皮 + (3,1) 填充，20 格 × 16 px。
func _grass_texture() -> ImageTexture:
	var ts := _tileset_image()
	var grass := Image.create(320, 32, false, Image.FORMAT_RGBA8)
	for x in 20:
		grass.blit_rect(ts, Rect2i(16, 0, 16, 16), Vector2i(x * 16, 0))
		grass.blit_rect(ts, Rect2i(48, 16, 16, 16), Vector2i(x * 16, 16))
	return ImageTexture.create_from_image(grass)


func _tileset_image() -> Image:
	var res := load(TILESET_PATH)
	if res is Image:
		return res
	return (res as Texture2D).get_image()


func _build_ui() -> void:
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UiTheme.build()
	add_child(ui)

	_logo = Label.new()
	_logo.text = Strings.LOGO
	_logo.position = Vector2(0, 28)
	_logo.size = Vector2(320, 32)
	_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT_SIZE)
	_logo.add_theme_color_override("font_color", LOGO_COLOR)
	_logo.add_theme_color_override("font_shadow_color", Color("#1a1c2c", 0.8))
	_logo.add_theme_constant_override("shadow_offset_x", 2)
	_logo.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(_logo)

	var subtitle := Label.new()
	subtitle.text = Strings.SUBTITLE
	subtitle.position = Vector2(0, 58)
	subtitle.size = Vector2(320, 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", SUBTITLE_COLOR)
	ui.add_child(subtitle)

	_menu = MenuList.new()
	_menu.position = Vector2(160, 88)
	ui.add_child(_menu)
	_menu.build([Strings.MENU_START, Strings.MENU_SELECT_LEVELS, _fullscreen_text(), Strings.MENU_QUIT], [], false, 14.0, true)
	_menu.accepted.connect(_do_action)

	var hint := KeyHint.new()
	hint.position = Vector2(0, 164)
	hint.size = Vector2(320, 16)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.set_hint(Strings.HINT_TITLE)
	ui.add_child(hint)

	var version := Label.new()
	version.text = Strings.VERSION
	version.anchor_left = 1.0
	version.anchor_top = 1.0
	version.anchor_right = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = -30.0
	version.offset_top = -14.0
	version.offset_right = -4.0
	version.offset_bottom = -2.0
	version.add_theme_color_override("font_color", VERSION_COLOR)
	ui.add_child(version)


func _fullscreen_text() -> String:
	var mode := DisplayServer.window_get_mode()
	return Strings.MENU_FULLSCREEN_ON if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else Strings.MENU_FULLSCREEN_OFF


func _do_action(idx: int) -> void:
	if Game.smoke_mode:
		print("TITLE ACTION: %s" % ["start", "select", "fullscreen", "quit"][clampi(idx, 0, 3)])
		return
	match idx:
		0:
			Game.start_new_game(1)
		1:
			_open_select()
		2:
			Game.toggle_fullscreen()
			_menu.set_item_text(2, _fullscreen_text())
		3:
			get_tree().quit()


var _select: CanvasLayer


func _open_select() -> void:
	if _select != null:
		return
	_menu.input_enabled = false
	_select = (load("res://scenes/ui/level_select.tscn") as PackedScene).instantiate()
	add_child(_select)
	_select.closed.connect(func() -> void:
		_menu.input_enabled = true
		_select = null)
