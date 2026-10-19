extends GutTest
## §14: TilesetFactory autotile lookups — every §7.3 table row, corner
## precedence, posmod alt variant, one-way variants, and
## LevelBuilder.solid_at / oneway_at out-of-bounds rules.


func test_ground_row0_not_up() -> void:
	# !up: R only -> top_left; L+R -> top; L only -> top_right; none -> top_single.
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, false, false, true, true, true), Vector2i(0, 0), "top_left")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, false, true, true, true, true), Vector2i(1, 0), "top")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, false, true, false, true, true), Vector2i(2, 0), "top_right")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, false, false, false, true, true), Vector2i(3, 0), "top_single")


func test_ground_row1_up() -> void:
	# up, no corners: none -> column; !L -> left; !R -> right.
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, false, false, true, true), Vector2i(3, 1), "column")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, false, true, true, true), Vector2i(0, 1), "left")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, true, false, true, true), Vector2i(2, 1), "right")


func test_ground_corners() -> void:
	# Inner corners beat row 1; corner_tl takes precedence over corner_tr.
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, true, false, false, true), Vector2i(1, 3), "corner_tl without right")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, true, true, false, true), Vector2i(1, 3), "corner_tl with right")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, false, true, true, false), Vector2i(2, 3), "corner_tr")
	assert_eq(TilesetFactory.pick_ground_tile(5, 5, true, true, true, false, false), Vector2i(1, 3), "corner_tl before corner_tr")


func test_inner_alt_formula() -> void:
	# up+L+R: posmod(c*7+r*13, 4) == 0 -> inner_alt (0,3), else inner (1,1).
	assert_eq(TilesetFactory.pick_ground_tile(0, 0, true, true, true, true, true), Vector2i(0, 3), "alt at c=0 r=0 (0 % 4 == 0)")
	assert_eq(TilesetFactory.pick_ground_tile(1, 1, true, true, true, true, true), Vector2i(0, 3), "alt at c=1 r=1 (20 % 4 == 0)")
	assert_eq(TilesetFactory.pick_ground_tile(1, 0, true, true, true, true, true), Vector2i(1, 1), "inner at c=1 r=0 (7 % 4 == 3)")
	assert_eq(TilesetFactory.pick_ground_tile(4, 7, true, true, true, true, true), Vector2i(1, 1), "inner at c=4 r=7 (119 % 4 == 3)")


func test_oneway_variants() -> void:
	assert_eq(TilesetFactory.pick_oneway_tile(false, true), Vector2i(4, 0), "left end")
	assert_eq(TilesetFactory.pick_oneway_tile(true, true), Vector2i(5, 0), "mid")
	assert_eq(TilesetFactory.pick_oneway_tile(true, false), Vector2i(6, 0), "right end")
	assert_eq(TilesetFactory.pick_oneway_tile(false, false), Vector2i(7, 0), "single")


func test_level_01_row8_oneway_stretch() -> void:
	var rows: Array = Levels.MAPS[1]
	var expected := [Vector2i(4, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(6, 0)]
	for i in 4:
		var c := 31 + i
		var picked := TilesetFactory.pick_oneway_tile(
			LevelBuilder.oneway_at(rows, c - 1, 8),
			LevelBuilder.oneway_at(rows, c + 1, 8),
		)
		assert_eq(picked, expected[i], "row 8 col %d one-way tile" % c)


func test_solid_at_oob_rules() -> void:
	var small: Array = ["..#.."]
	assert_true(LevelBuilder.solid_at(small, 2, 0), "# is solid")
	assert_false(LevelBuilder.solid_at(small, 1, 0), ". is empty")
	assert_true(LevelBuilder.solid_at(small, -1, 0), "left OOB counts as solid")
	assert_true(LevelBuilder.solid_at(small, Levels.COLS, 0), "right OOB counts as solid")
	assert_false(LevelBuilder.solid_at(small, 1, -1), "top OOB counts as empty")
	assert_false(LevelBuilder.solid_at(small, 1, 1), "below the map counts as empty")


func test_oneway_at_oob_rules() -> void:
	var small: Array = ["..=.."]
	assert_true(LevelBuilder.oneway_at(small, 2, 0), "= is oneway")
	assert_false(LevelBuilder.oneway_at(small, 1, 0), ". is not oneway")
	assert_false(LevelBuilder.oneway_at(small, -1, 0), "left OOB is not oneway")
	assert_false(LevelBuilder.oneway_at(small, Levels.COLS, 0), "right OOB is not oneway")
	assert_false(LevelBuilder.oneway_at(small, 2, -1), "top OOB is not oneway")
	assert_false(LevelBuilder.oneway_at(small, 2, 1), "bottom OOB is not oneway")


func test_decor_variant_formula() -> void:
	var rows: Array = Levels.MAPS[1]
	var cols := [10, 18, 23]
	var expected := [Vector2i(3, 2), Vector2i(3, 2), Vector2i(2, 2)]
	for i in cols.size():
		var c: int = cols[i]
		var row: String = rows[9]
		assert_eq(row.substr(c, 1), "d", "col %d row 9 must be d" % c)
		assert_eq(Vector2i((c * 7 + 1) % 4, 2), expected[i], "decor variant at col %d" % c)
