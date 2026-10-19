extends GutTest
## §14: LevelBuilder scene output — terrain extent, one-way atlas
## coords, interior solid + decor tiles, spawn/flag positions,
## entity counts by name prefix, world walls, camera limits.
## Each test builds a fresh Level into the tree; after_each frees them.

var _levels: Array = []


func after_each() -> void:
	for i in _levels.size():
		var level: Level = _levels[i]
		if is_instance_valid(level):
			level.queue_free()
	_levels = []


func _build(idx: int) -> Level:
	var level: Level = Level.new()
	level.level_index = idx
	add_child(level)
	_levels.append(level)
	return level


func test_level_01_terrain_extent() -> void:
	var level := _build(1)
	var terrain: TileMapLayer = level.get_node("Terrain")
	var used: Rect2i = terrain.get_used_rect()
	# 1-1 terrain lives in rows 8-11 and spans the full 40 columns.
	assert_eq(used.size.x, Levels.COLS, "terrain must span 40 columns")
	assert_eq(used.position, Vector2i(0, 8), "terrain top-left corner")
	assert_eq(used.size.y, 4, "terrain must span rows 8-11")


func test_level_01_oneway_tiles_placed() -> void:
	var level := _build(1)
	var terrain: TileMapLayer = level.get_node("Terrain")
	var expected := [Vector2i(4, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(6, 0)]
	for i in 4:
		var c := 31 + i
		var coords: Vector2i = terrain.get_cell_atlas_coords(Vector2i(c, 8))
		assert_eq(coords, expected[i], "row 8 col %d atlas coords" % c)


func test_level_01_interior_solid_tile() -> void:
	var level := _build(1)
	var terrain: TileMapLayer = level.get_node("Terrain")
	# Row 11 is fully buried (up/left/right solid); posmod(c*7+11*13, 4) == 0
	# -> inner_alt (0,3), otherwise inner (1,1).
	var alt: Vector2i = terrain.get_cell_atlas_coords(Vector2i(19, 11))
	assert_eq(alt, Vector2i(0, 3), "(19,11) posmod(276,4)==0 -> inner_alt (0,3)")
	var inner: Vector2i = terrain.get_cell_atlas_coords(Vector2i(20, 11))
	assert_eq(inner, Vector2i(1, 1), "(20,11) posmod(283,4)==3 -> inner (1,1)")


func test_level_01_decor_variants() -> void:
	var level := _build(1)
	var decor: TileMapLayer = level.get_node("Decor")
	var cols := [10, 18, 23]
	var expected := [Vector2i(3, 2), Vector2i(3, 2), Vector2i(2, 2)]
	for i in cols.size():
		var c: int = cols[i]
		var coords: Vector2i = decor.get_cell_atlas_coords(Vector2i(c, 9))
		assert_eq(coords, expected[i], "decor variant at col %d" % c)


func test_level_01_spawn_and_flag() -> void:
	var level := _build(1)
	var spawn: Marker2D = level.get_node("Entities/Spawn")
	assert_eq(spawn.position, Vector2(40, 160), "1-1 spawn (P col 2 row 9)")
	var flag: Node2D = level.get_node("Entities/Flag")
	assert_eq(flag.position, Vector2(616, 160), "1-1 flag (F col 38 row 9)")


func test_levels_02_03_spawn() -> void:
	var l2 := _build(2)
	var s2: Marker2D = l2.get_node("Entities/Spawn")
	assert_eq(s2.position, Vector2(24, 160), "1-2 spawn (P col 1 row 9)")
	var l3 := _build(3)
	var s3: Marker2D = l3.get_node("Entities/Spawn")
	assert_eq(s3.position, Vector2(24, 160), "1-3 spawn (P col 1 row 9)")


func test_entity_counts_match_map() -> void:
	var expected := {
		1: {"Coin": 11, "Walker": 1, "Spiky": 0, "Spike": 0, "Sign": 5},
		2: {"Coin": 17, "Walker": 2, "Spiky": 0, "Spike": 0, "Sign": 0},
		3: {"Coin": 8, "Walker": 1, "Spiky": 2, "Spike": 9, "Sign": 0},
	}
	var prefixes := ["Coin", "Walker", "Spiky", "Spike", "Sign"]
	for i in 3:
		var idx := i + 1
		var level := _build(idx)
		var entities: Node2D = level.get_node("Entities")
		var names: PackedStringArray = []
		for e in entities.get_child_count():
			names.append(entities.get_child(e).name)
		var counts: Dictionary = expected[idx]
		for j in prefixes.size():
			var prefix: String = prefixes[j]
			var n := 0
			for k in names.size():
				if names[k].begins_with(prefix):
					n += 1
			assert_eq(n, counts[prefix], "level %d %s count" % [idx, prefix])


func test_world_walls() -> void:
	var level := _build(1)
	var bounds: Node2D = level.get_node("Bounds")
	assert_eq(bounds.get_child_count(), 2, "two world walls")
	var xs: Array[float] = []
	for i in 2:
		var wall: StaticBody2D = bounds.get_child(i) as StaticBody2D
		assert_not_null(wall, "wall %d must be a StaticBody2D" % i)
		assert_eq(wall.collision_layer, 1, "wall %d on world_solid layer" % i)
		assert_eq(wall.collision_mask, 0, "wall %d masks nothing" % i)
		var shape_node: CollisionShape2D = wall.get_child(0) as CollisionShape2D
		assert_not_null(shape_node, "wall %d must have a shape" % i)
		var shape: RectangleShape2D = shape_node.shape as RectangleShape2D
		assert_not_null(shape, "wall %d shape must be a rectangle" % i)
		assert_eq(shape.size, Vector2(16, 256), "wall %d size" % i)
		xs.append(wall.position.x)
	xs.sort()
	assert_eq(xs[0], -8, "left wall x")
	assert_eq(xs[1], 648, "right wall x")


func test_camera_limits() -> void:
	for i in 3:
		var idx := i + 1
		var level := _build(idx)
		var camera: Camera2D = level.get_node("Camera")
		assert_eq(camera.limit_left, 0, "level %d limit_left" % idx)
		assert_eq(camera.limit_top, 0, "level %d limit_top" % idx)
		assert_eq(camera.limit_right, 640, "level %d limit_right" % idx)
		assert_eq(camera.limit_bottom, 192, "level %d limit_bottom" % idx)
