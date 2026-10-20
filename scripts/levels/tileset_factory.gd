class_name TilesetFactory
## §7.3: 运行时构建 TileSet（源 textures/tileset.png）。
## Godot 4.7.2 探针确认：碰撞多边形点为瓦片中心原点（16×16 瓦片 → ±8），
## 左上角原点会整块偏移半格。
## TileSet 物理层映射 project.godot 的 world_solid（1）/ world_oneway（2）。

const TILESET_PATH := "res://assets/tiles/tileset.png"
const TILE_SIZE := Vector2i(16, 16)
const LAYER_SOLID := 0
const LAYER_ONEWAY := 1
const SOLID_PHYSICS_LAYER := 1  # world_solid
const ONEWAY_PHYSICS_LAYER := 2  # world_oneway
const ONEWAY_MARGIN := 4


static func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = TILE_SIZE
	ts.add_physics_layer()
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(LAYER_SOLID, SOLID_PHYSICS_LAYER)
	ts.set_physics_layer_collision_layer(LAYER_ONEWAY, ONEWAY_PHYSICS_LAYER)
	var src := TileSetAtlasSource.new()
	src.texture = load(TILESET_PATH)
	src.texture_region_size = TILE_SIZE
	src.separation = Vector2i.ZERO
	src.margins = Vector2i.ZERO
	ts.add_source(src)
	var solid_coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
	]
	for ac in solid_coords:
		src.create_tile(ac)
		var td: TileData = src.get_tile_data(ac, 0)
		td.add_collision_polygon(LAYER_SOLID)
		td.set_collision_polygon_points(LAYER_SOLID, 0, _full_poly())
	for c in 4:
		var ac := Vector2i(4 + c, 0)
		src.create_tile(ac)
		var td: TileData = src.get_tile_data(ac, 0)
		td.add_collision_polygon(LAYER_ONEWAY)
		td.set_collision_polygon_points(LAYER_ONEWAY, 0, _strip_poly())
		td.set_collision_polygon_one_way(LAYER_ONEWAY, 0, true)
		td.set_collision_polygon_one_way_margin(LAYER_ONEWAY, 0, ONEWAY_MARGIN)
	# 装饰（无碰撞）：(0..3,2) 是 `d` 的变体 0..3。
	for c in 4:
		src.create_tile(Vector2i(c, 2))
	return ts


## 全 16×16 实心碰撞，中心原点。
static func _full_poly() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
	])


## 顶部 16×4 单向碰撞条，中心原点。
static func _strip_poly() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, -4), Vector2(-8, -4),
	])


## §7.3 autotile：7 邻居标志 → 图集坐标。
## up = solid(c,r-1)，L = solid(c-1,r)，R = solid(c+1,r)；
## OOB 由调用方处理（左右出界按实心，顶部出界按空）。
## 判定顺序：!up → 第 0 行；up → 先内拐角（tl 优先 tr）→ 第 1 行 → alt。
static func pick_ground_tile(
		c: int, r: int, up: bool, left: bool, right: bool,
		diag_tl: bool, diag_tr: bool) -> Vector2i:
	if up:
		if left and not diag_tl:
			return Vector2i(1, 3)  # corner_tl
		if right and not diag_tr:
			return Vector2i(2, 3)  # corner_tr
		if not left and not right:
			return Vector2i(3, 1)  # column
		if not left:
			return Vector2i(0, 1)  # left
		if not right:
			return Vector2i(2, 1)  # right
		return Vector2i(0, 3) if posmod(c * 7 + r * 13, 4) == 0 else Vector2i(1, 1)
	if left and right:
		return Vector2i(1, 0)  # top
	if left:
		return Vector2i(2, 0)  # top_right（L，!R）
	if right:
		return Vector2i(0, 0)  # top_left（!L，R）
	return Vector2i(3, 0)  # top_single


## §7.3 autotile：单向板变体由左右邻居是否为 `=` 决定。
static func pick_oneway_tile(left_oneway: bool, right_oneway: bool) -> Vector2i:
	if not left_oneway and not right_oneway:
		return Vector2i(7, 0)  # oneway_single
	if left_oneway and right_oneway:
		return Vector2i(5, 0)  # oneway_mid
	if left_oneway:
		return Vector2i(6, 0)  # oneway_right（右端：左是 `=`，右不是）
	return Vector2i(4, 0)  # oneway_left（左端：左不是 `=`，右是）
