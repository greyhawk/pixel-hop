extends GutTest
## HUD 静态格式覆盖（M7）：金币 %02d/%02d、计时 %02d:%02d。

const Hud = preload("res://scripts/ui/hud.gd")


func test_coin_format() -> void:
	assert_eq(Hud.format_coin_count(0, 11), "00/11", "0/11 → 00/11")
	assert_eq(Hud.format_coin_count(7, 17), "07/17", "7/17 → 07/17")
	assert_eq(Hud.format_coin_count(11, 11), "11/11", "11/11 满额")
	assert_eq(Hud.format_coin_count(99, 99), "99/99", "99/99 上界")


func test_time_format() -> void:
	assert_eq(Hud.format_time(0.0), "00:00", "0s → 00:00")
	assert_eq(Hud.format_time(41.9), "00:41", "41.9s → 00:41（向下取整）")
	assert_eq(Hud.format_time(60.0), "01:00", "60s → 01:00")
	assert_eq(Hud.format_time(3661.0), "61:01", "3661s → 61:01")
	assert_eq(Hud.format_time(-5.0), "00:00", "负值 → 00:00（钳制）")
