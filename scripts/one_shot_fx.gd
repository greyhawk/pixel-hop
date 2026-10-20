class_name OneShotFx
extends Node2D
## §9.6 一次性特效：从横向图集条带（count 帧）播放一次，结束后自动 queue_free。
## 由 OneShotFx.spawn / spawn_named 以世界坐标生成；父节点随相机滚动，特效跟随。
## SpriteFrames 在代码内按图集区域构建（非 16px 专用，勿复用 SpriteFramesFactory）。

## 图集纹理路径（横向 strip）。
var texture_path := ""
## 单帧尺寸（px）。
var frame := Vector2i(16, 16)
## 帧数。
var count := 1
## 播放帧率（帧/秒）。
var fps := 20.0

const SPRITE_PATH := "Sprite"

## §9.6 FX 表：名称 → 纹理 / 单帧尺寸 / 帧数 / 帧率。
const FX := {
	"jump_puff":    {"tex": "res://assets/sprites/fx/fx_jump_puff.png",    "frame": Vector2i(16, 8),  "count": 4, "fps": 20.0},
	"land_puff":    {"tex": "res://assets/sprites/fx/fx_land_puff.png",    "frame": Vector2i(24, 8),  "count": 4, "fps": 20.0},
	"poof":         {"tex": "res://assets/sprites/fx/fx_poof.png",         "frame": Vector2i(16, 16), "count": 5, "fps": 20.0},
	"coin_sparkle": {"tex": "res://assets/sprites/fx/fx_coin_sparkle.png", "frame": Vector2i(12, 12), "count": 4, "fps": 20.0},
	"hit_spark":    {"tex": "res://assets/sprites/fx/fx_hit_spark.png",    "frame": Vector2i(12, 12), "count": 3, "fps": 30.0},
}


func _ready() -> void:
	var sprite := get_node_or_null(SPRITE_PATH) as AnimatedSprite2D
	if sprite == null:
		return
	var tex := load(texture_path) as Texture2D
	if tex == null:
		queue_free()
		return
	sprite.sprite_frames = _build_frames(tex)
	sprite.animation_finished.connect(queue_free)
	sprite.play("fx")


## 用世界坐标在 parent 下生成一个 FX。parent 缺失或 texture_path 为空时返回 null。
static func spawn(parent: Node, world_pos: Vector2, texture_path_in: String, frame_in: Vector2i, count_in: int, fps_in: float, z_index: int = 10) -> Node:
	if parent == null or texture_path_in == "":
		return null
	var scene := load("res://scenes/fx/one_shot_fx.tscn") as PackedScene
	if scene == null:
		return null
	var node := scene.instantiate()
	node.texture_path = texture_path_in
	node.frame = frame_in
	node.count = count_in
	node.fps = fps_in
	node.z_index = z_index
	parent.add_child(node)
	if parent is Node2D:
		node.position = (parent as Node2D).to_local(world_pos)
	else:
		node.position = world_pos
	return node


## 按名称从 FX 表生成。未知名称或 parent 缺失时返回 null。
static func spawn_named(parent: Node, world_pos: Vector2, name: String, z_index: int = 10) -> Node:
	if parent == null or not FX.has(name):
		return null
	var cfg: Dictionary = FX[name]
	return spawn(parent, world_pos, cfg["tex"], cfg["frame"], cfg["count"], cfg["fps"], z_index)


func _build_frames(tex: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("fx")
	frames.set_animation_loop("fx", false)
	frames.set_animation_speed("fx", fps)
	var total := maxi(count, 1)
	for i in total:
		var atex := AtlasTexture.new()
		atex.atlas = tex
		atex.region = Rect2(float(i) * float(frame.x), 0.0, float(frame.x), float(frame.y))
		frames.add_frame("fx", atex)
	return frames


## §10.10 彩带色带：4 色硬边离散（#ffcd75 #ef7d57 #a7f070 #73eff7）。
## 终点旗一次性喷发与末关结算面板连续飘落共用此 ramp。
static func confetti_ramp() -> Gradient:
	var g := Gradient.new()
	g.colors = [
		Color("#ffcd75"), Color("#ffcd75"),
		Color("#ef7d57"), Color("#ef7d57"),
		Color("#a7f070"), Color("#a7f070"),
		Color("#73eff7"), Color("#73eff7"),
	]
	g.offsets = [0.0, 0.25, 0.25, 0.5, 0.5, 0.75, 0.75, 1.0]
	return g
