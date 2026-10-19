class_name UiTheme
## 游戏全局主题（§6.3 / §10.1）。
##
## 默认字体：Fusion Pixel Font 12px（TakWolf，OFL 1.1），字号 12
## （大标题只用 24）。Label 阴影 #1a1c2c，偏移 (1,1)。
## 像素锐化属性在 load 之后用代码设置：Godot 4.7.2 里 FontFile 的
## antialiasing / hinting / subpixel_positioning 是普通 int（0 = NONE），
## 没有暴露具名 GDScript 枚举常量（已实测）。

const FONT_PATH := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hans.ttf"
const DEFAULT_FONT_SIZE := 12
const TITLE_FONT_SIZE := 24
const SHADOW_COLOR := Color("#1a1c2c")
const FALLBACK_WARNING := "Fusion Pixel font missing, using default font"


## 构建全局主题。字体加载失败时警告并退回引擎默认字体（§6.3）。
static func build(font_path: String = FONT_PATH) -> Theme:
	var theme := Theme.new()
	theme.set_color("shadow_color", "Label", SHADOW_COLOR)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	var font: FontFile = null
	if ResourceLoader.exists(font_path):
		font = load(font_path) as FontFile
	if font != null:
		_configure_crisp(font)
		theme.default_font = font
		theme.default_font_size = DEFAULT_FONT_SIZE
	else:
		push_warning(FALLBACK_WARNING)
		theme.default_font = ThemeDB.fallback_font
	return theme


## 像素字体：关掉一切会让 16×16 网格发虚的渲染特性。
static func _configure_crisp(f: FontFile) -> void:
	f.antialiasing = 0 # NONE（.import 默认 1 = gray）
	f.hinting = 0 # NONE（.import 默认 3 = medium）
	f.subpixel_positioning = 0 # NONE
	f.generate_mipmaps = false
	f.multichannel_signed_distance_field = false
