extends GutTest
## Every placeholder asset (spec §6.2) must load in Godot and have the
## exact pixel dimensions the game code will hardcode against (M1).

const ASSETS := [
	["res://assets/sprites/player/player_sheet.png", 96, 112],
	["res://assets/sprites/enemies/walker_sheet.png", 64, 32],
	["res://assets/sprites/enemies/spiky_sheet.png", 64, 16],
	["res://assets/tiles/tileset.png", 128, 64],
	["res://assets/sprites/items/coin_sheet.png", 48, 8],
	["res://assets/sprites/items/flag_pole.png", 16, 48],
	["res://assets/sprites/items/flag_cloth_sheet.png", 48, 10],
	["res://assets/sprites/fx/dust_px.png", 3, 3],
	["res://assets/sprites/fx/fx_jump_puff.png", 64, 8],
	["res://assets/sprites/fx/fx_land_puff.png", 96, 8],
	["res://assets/sprites/fx/fx_poof.png", 80, 16],
	["res://assets/sprites/fx/fx_coin_sparkle.png", 48, 12],
	["res://assets/sprites/fx/fx_hit_spark.png", 36, 12],
	["res://assets/sprites/fx/confetti_px.png", 2, 2],
	["res://assets/sprites/ui/ui_heart_full.png", 8, 8],
	["res://assets/sprites/ui/ui_heart_empty.png", 8, 8],
	["res://assets/sprites/ui/ui_coin.png", 8, 8],
	["res://assets/sprites/ui/ui_life.png", 8, 8],
	["res://assets/sprites/ui/ui_lock.png", 7, 8],
	["res://assets/sprites/ui/ui_cursor.png", 6, 7],
	["res://assets/sprites/ui/ui_panel.png", 24, 24],
	["res://assets/sprites/ui/ui_panel_small.png", 12, 12],
	["res://assets/sprites/ui/ui_bubble_tail.png", 5, 3],
	["res://assets/sprites/ui/ui_keycap.png", 10, 12],
	["res://assets/bg/bg_sky.png", 320, 180],
	["res://assets/bg/bg_far_mountains.png", 320, 96],
	["res://assets/bg/bg_clouds.png", 320, 48],
	["res://assets/bg/bg_mid_hills.png", 320, 64],
]


func test_all_assets_load_with_spec_dimensions() -> void:
	for a in ASSETS:
		var tex: Texture2D = load(a[0])
		assert_not_null(tex, a[0] + " must load")
		if tex == null:
			continue
		assert_eq(tex.get_width(), a[1], a[0] + " width must be " + str(a[1]))
		assert_eq(tex.get_height(), a[2], a[0] + " height must be " + str(a[2]))


func test_asset_list_is_complete() -> void:
	# Guards against a file being renamed/deleted without updating this list:
	# the repo must contain exactly the 28 §6.2 files, no more, no fewer.
	var found := _list_pngs("res://assets")
	assert_eq(found.size(), ASSETS.size(), "assets/ must contain exactly the 28 spec files")
	var expected := []
	for a in ASSETS:
		expected.append(a[0])
	expected.sort()
	found.sort()
	assert_eq(found, expected, "asset file set must match §6.2 exactly")


func _list_pngs(dir_path: String) -> Array:
	var out := []
	var da := DirAccess.open(dir_path)
	if da == null:
		return out
	da.list_dir_begin()
	var entry := da.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			if da.current_is_dir():
				out.append_array(_list_pngs(dir_path.path_join(entry)))
			elif entry.get_extension().to_lower() == "png":
				out.append(dir_path.path_join(entry))
		entry = da.get_next()
	da.list_dir_end()
	return out
