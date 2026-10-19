extends GutTest
## §14: level data (autoload/levels.gd) — grid shape, legend, entity
## counts, sign columns, byte-equivalence with tools/maps.json,
## and Levels.validate() rejections.


func test_all_maps_are_12x40_and_validate() -> void:
	for i in 3:
		var idx := i + 1
		var rows: Array = Levels.MAPS[idx]
		assert_eq(rows.size(), Levels.ROWS, "map %d row count" % idx)
		for j in rows.size():
			var row: String = rows[j]
			assert_eq(row.length(), Levels.COLS, "map %d row %d length" % [idx, j])
		assert_true(Levels.validate(rows), "map %d must validate (legend, 1 P, 1 F)" % idx)


func test_entity_counts_match_spec() -> void:
	var coins := [11, 17, 8]
	var walkers := [1, 2, 1]
	var spikies := [0, 0, 2]
	var spikes := [0, 0, 9]
	var total := 0
	for i in 3:
		var idx := i + 1
		var rows: Array = Levels.MAPS[idx]
		var coin_count := _count(rows, "o")
		total += coin_count
		assert_eq(coin_count, coins[i], "map %d coins" % idx)
		assert_eq(_count(rows, "E"), walkers[i], "map %d walkers" % idx)
		assert_eq(_count(rows, "S"), spikies[i], "map %d spikies" % idx)
		assert_eq(_count(rows, "^"), spikes[i], "map %d spikes" % idx)
	assert_eq(total, 36, "total coins must be 36")


func test_level_01_sign_columns() -> void:
	var rows: Array = Levels.MAPS[1]
	var cols: Array[int] = []
	for i in rows.size():
		var row: String = rows[i]
		for c in row.length():
			if row.substr(c, 1) == "h":
				cols.append(c)
	assert_eq(cols, [4, 6, 20, 29, 36], "1-1 sign columns")


func test_maps_match_tools_maps_json() -> void:
	var text := FileAccess.get_file_as_string("res://tools/maps.json")
	assert_true(text.length() > 0, "tools/maps.json must be readable")
	if text.is_empty():
		return
	var parsed: Dictionary = JSON.parse_string(text)
	assert_not_null(parsed, "maps.json must parse as a JSON object")
	if parsed == null:
		return
	var keys := ["level_01_tutorial", "level_02_medium", "level_03_hard"]
	assert_eq(parsed.size(), 3, "maps.json must have exactly 3 levels")
	for i in 3:
		var key: String = keys[i]
		assert_true(key in parsed, "maps.json must contain " + key)
		var lvl: Array = parsed[key]
		var rows: Array = Levels.MAPS[i + 1]
		assert_eq(lvl.size(), rows.size(), key + " row count")
		for j in rows.size():
			var gd_row: String = rows[j]
			var json_row: String = lvl[j]
			assert_eq(gd_row, json_row, key + " row %d must be byte-identical" % j)


func test_validate_rejects_bad_grids() -> void:
	var good: Array = Levels.MAPS[1]
	assert_true(Levels.validate(good), "map 1 must validate")

	var wrong_rows: Array = []
	for i in Levels.ROWS - 1:
		var row: String = good[i]
		wrong_rows.append(row)
	assert_false(Levels.validate(wrong_rows), "11 rows must be rejected")

	var short_row: Array = good.duplicate()
	var first: String = short_row[0]
	short_row[0] = first.left(Levels.COLS - 1)
	assert_false(Levels.validate(short_row), "39-char row must be rejected")

	var illegal: Array = good.duplicate()
	var second: String = illegal[0]
	illegal[0] = second.substr(0, 2) + "x" + second.substr(3, second.length() - 3)
	assert_false(Levels.validate(illegal), "illegal character must be rejected")

	var extra_spawn: Array = good.duplicate()
	var spawn_row: String = extra_spawn[9]
	extra_spawn[9] = spawn_row.replace(".", "P")
	assert_false(Levels.validate(extra_spawn), "more than one P must be rejected")

	var no_flag: Array = good.duplicate()
	var flag_row: String = no_flag[9]
	no_flag[9] = flag_row.replace("F", ".")
	assert_false(Levels.validate(no_flag), "missing F must be rejected")


func _count(rows: Array, ch: String) -> int:
	var n := 0
	for i in rows.size():
		var row: String = rows[i]
		n += row.count(ch)
	return n
