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
	var camera := _build_camera(root, level_index)
	var sign_texts := _collect_sign_texts(rows)
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			var ch: String = row.substr(c, 1)
			_place(terrain, decor, entities, ch, c, r, rows, level_index, sign_texts)
	_place_player(terrain, entities, camera)


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
	sign_texts: Dictionary,
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
			_place_entity(entities, ch, c, r, rows, sign_texts)


## §7.2: real entity scenes (M5). `P` stays a Marker2D ("Spawn") for tests/smoke.
static func _place_entity(
	entities: Node2D,
	ch: String,
	c: int,
	r: int,
	rows: Array,
	sign_texts: Dictionary,
) -> void:
	if ch == "P":
		var marker := Marker2D.new()
		marker.name = "Spawn"
		marker.position = _entity_pos(ch, c, r)
		entities.add_child(marker)
		return
	var node: Node2D
	match ch:
		"o":
			node = preload("res://scenes/items/coin.tscn").instantiate()
		"E":
			node = preload("res://scenes/enemies/enemy_walker.tscn").instantiate()
		"S":
			node = preload("res://scenes/enemies/enemy_spiky.tscn").instantiate()
		"^":
			node = preload("res://scenes/items/spike.tscn").instantiate()
		"h":
			node = preload("res://scenes/items/sign.tscn").instantiate()
		"F":
			node = preload("res://scenes/items/goal_flag.tscn").instantiate()
	node.name = _entity_name(ch, c, r)
	node.position = _entity_pos(ch, c, r)
	match ch:
		"o":
			(node as Coin).column = c
		"E", "S":
			(node as Enemy).map_rows = rows
		"h":
			(node as Sign).text = sign_texts.get("%d_%d" % [c, r], "")
	entities.add_child(node)


## §7.2: 1-1 的 `h` 按列顺序（先列后行）依次取 Levels.SIGN_TEXTS。
static func _collect_sign_texts(rows: Array) -> Dictionary:
	var cells: Array[Vector2i] = []
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			if row.substr(c, 1) == "h":
				cells.append(Vector2i(c, r))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x != b.x:
			return a.x < b.x
		return a.y < b.y,
	)
	var texts := {}
	for i in cells.size():
		var cell: Vector2i = cells[i]
		texts["%d_%d" % [cell.x, cell.y]] = Levels.SIGN_TEXTS[i] if i < Levels.SIGN_TEXTS.size() else ""
	return texts


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


## §7.2: Camera2D (CameraFollow) limited to the level viewport rect from
## Levels.META; follows the Player with drag + look-ahead (§9.6).
static func _build_camera(root: Node2D, level_index: int) -> CameraFollow:
	var meta: Dictionary = Levels.META[level_index]
	var cam_rect: Rect2i = meta["camera"]
	var camera := CameraFollow.new()
	camera.name = "Camera"
	camera.limit_left = cam_rect.position.x
	camera.limit_top = cam_rect.position.y
	camera.limit_right = cam_rect.end.x
	camera.limit_bottom = cam_rect.end.y
	root.add_child(camera)
	return camera


## M4: spawn the Player at the "Spawn" marker (kept for tests/smoke),
## inject the Terrain layer (drop-through / corner probes) and hand it to the camera.
static func _place_player(terrain: TileMapLayer, entities: Node2D, camera: CameraFollow) -> void:
	var spawn: Node2D = entities.get_node_or_null("Spawn")
	if spawn == null:
		return
	var player := preload("res://scenes/player/player.tscn").instantiate() as Player
	player.name = "Player"
	player.position = spawn.position
	player.terrain = terrain
	entities.add_child(player)
	camera.player = player
	camera.snap_to_player()
