class_name LevelBuilder
## §7: Builds the level scene tree from Levels.MAPS[level_index]:
## Terrain/Decor TileMapLayers (autotiled per §7.3), entity placeholders,
## world walls, and a Camera2D limited to the level viewport rect.

const TILE := 16


## Builds all children of `root` (the Level scene root, a Node2D).
static func build(root: Node2D, level_index: int) -> void:
	var rows: Array = Levels.MAPS[level_index]
	if not Levels.validate(rows):
		push_error("LevelBuilder.build: invalid map for level %d" % level_index)
		return
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = TilesetFactory.build_tileset()
	root.add_child(terrain)
	var decor := TileMapLayer.new()
	decor.name = "Decor"
	decor.tile_set = terrain.tile_set
	decor.z_index = -10
	root.add_child(decor)
	var entities := Node2D.new()
	entities.name = "Entities"
	root.add_child(entities)
	_build_bounds(root)
	_build_camera(root, level_index)
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			var ch: String = row.substr(c, 1)
			_place(terrain, decor, entities, ch, c, r, rows, level_index)


## §7.3: `#` is solid; out of bounds: left/right count as solid,
## top/bottom count as empty.
static func solid_at(rows: Array, c: int, r: int) -> bool:
	if r < 0 or r >= rows.size():
		return false
	if c < 0 or c >= Levels.COLS:
		return true
	var row: String = rows[r]
	return row.substr(c, 1) == "#"


## §7.3: `=` is a one-way tile; out of bounds: false.
static func oneway_at(rows: Array, c: int, r: int) -> bool:
	if r < 0 or r >= rows.size():
		return false
	if c < 0 or c >= Levels.COLS:
		return false
	var row: String = rows[r]
	return row.substr(c, 1) == "="


static func _place(
	terrain: TileMapLayer,
	decor: TileMapLayer,
	entities: Node2D,
	ch: String,
	c: int,
	r: int,
	rows: Array,
	level_index: int,
) -> void:
	match ch:
		"#":
			terrain.set_cell(
				Vector2i(c, r),
				TilesetFactory.LAYER_SOLID,
				TilesetFactory.pick_ground_tile(
					c,
					r,
					solid_at(rows, c, r - 1),
					solid_at(rows, c - 1, r),
					solid_at(rows, c + 1, r),
					solid_at(rows, c - 1, r - 1),
					solid_at(rows, c + 1, r - 1),
				),
			)
		"=":
			terrain.set_cell(
				Vector2i(c, r),
				TilesetFactory.LAYER_ONEWAY,
				TilesetFactory.pick_oneway_tile(
					oneway_at(rows, c - 1, r),
					oneway_at(rows, c + 1, r),
				),
			)
		"d":
			# §7.2: 4 alternating decoration variants (0..3,2).
			decor.set_cell(Vector2i(c, r), 0, Vector2i((c * 7 + level_index) % 4, 2))
		"o", "E", "S", "^", "h", "P", "F":
			_place_entity(entities, ch, c, r)


## §7.2: entity placeholder = Marker2D (real scenes land in M4/M5).
static func _place_entity(entities: Node2D, ch: String, c: int, r: int) -> void:
	var marker := Marker2D.new()
	marker.name = _entity_name(ch, c, r)
	marker.position = _entity_pos(ch, c, r)
	entities.add_child(marker)


static func _entity_name(ch: String, c: int, r: int) -> String:
	match ch:
		"o":
			return "Coin_%d_%d" % [c, r]
		"E":
			return "Walker_%d_%d" % [c, r]
		"S":
			return "Spiky_%d_%d" % [c, r]
		"^":
			return "Spike_%d_%d" % [c, r]
		"h":
			return "Sign_%d_%d" % [c, r]
		"P":
			return "Spawn"
		"F":
			return "Flag"
	return "Cell_%d_%d" % [c, r]


## §7.2: `o` is cell-center; `^` is tile top-left;
## E/S/h/P/F stand at the tile's bottom edge (feet).
static func _entity_pos(ch: String, c: int, r: int) -> Vector2:
	match ch:
		"o":
			return Vector2(c * TILE + 8, r * TILE + 8)
		"^":
			return Vector2(c * TILE, r * TILE)
		_:
			return Vector2(c * TILE + 8, (r + 1) * TILE)


## §7.2: two StaticBody2D walls whose collision faces sit exactly
## at x=0 and x=640 (world_solid layer, no mask).
static func _build_bounds(root: Node2D) -> void:
	var bounds := Node2D.new()
	bounds.name = "Bounds"
	root.add_child(bounds)
	_place_wall(bounds, -8)
	_place_wall(bounds, 648)


static func _place_wall(parent: Node2D, x: int) -> void:
	var wall := StaticBody2D.new()
	wall.position = Vector2(x, 96)
	wall.collision_layer = 1
	wall.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 256)
	shape_node.shape = shape
	wall.add_child(shape_node)
	parent.add_child(wall)


## §7.2: Camera2D limited to the level viewport rect from Levels.META.
static func _build_camera(root: Node2D, level_index: int) -> void:
	var meta: Dictionary = Levels.META[level_index]
	var cam_rect: Rect2i = meta["camera"]
	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.limit_left = cam_rect.position.x
	camera.limit_top = cam_rect.position.y
	camera.limit_right = cam_rect.end.x
	camera.limit_bottom = cam_rect.end.y
	root.add_child(camera)
