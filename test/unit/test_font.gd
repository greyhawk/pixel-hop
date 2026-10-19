extends GutTest
## M2 验收：Fusion Pixel 字体 + UiTheme（§6.3 / §12 M2）。

const FONT_PATH := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hans.ttf"


func test_default_font_is_fusion_pixel_at_size_12() -> void:
	var theme := UiTheme.build()
	var font := theme.get_default_font()
	assert_true(font is FontFile, "默认字体必须是加载出来的 FontFile")
	assert_eq(font.resource_path, FONT_PATH, "默认字体必须就是这个 TTF")
	assert_eq(theme.get_default_font_size(), 12, "默认字号必须是 12")


func test_font_covers_every_ui_character() -> void:
	var font := UiTheme.build().get_default_font()
	if not (font is FontFile):
		pending("本检出缺少 Fusion Pixel 字体（§6.3 下载失败分支）")
		return
	for s in Strings.all_strings():
		for i in s.length():
			var c: String = s[i]
			assert_true(
				font.has_char(c.unicode_at(0)),
				"字体缺 U+%04X「%s」（来自 %s）" % [c.unicode_at(0), c, s])
	var sz := font.get_string_size("像素跳跳", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	assert_gt(sz.x, 0.0, "「像素跳跳」渲染宽度必须 > 0")


func test_missing_font_falls_back_with_warning() -> void:
	var theme := UiTheme.build("res://does_not_exist.ttf")
	assert_not_null(theme, "字体缺失时 build() 仍须返回 Theme")
	assert_not_null(theme.get_default_font(), "回退主题必须有可用默认字体")
	assert_push_warning(UiTheme.FALLBACK_WARNING, "字体缺失必须 push_warning（不得 push_error）")
