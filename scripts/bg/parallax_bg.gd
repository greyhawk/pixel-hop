class_name ParallaxBg
extends Node2D
## §10.9: 4 层视差背景（M8），代码构建（D20）。
## 层 z_index -100..-70，位于 Decor(-10) 与 Terrain(0) 之后（更靠后）。
## 每张 320px 宽，repeat_size.x=320 / repeat_times=3 自动平铺 + 随相机视差；
## repeat_size.y=0（不纵向平铺）。sprite local_x=160 为 320px 纹理中心。
##
## sprite local_y 按「静止相机」（世界中心 (160,102)，玩家落地被 clamp 到
## 关卡底）调校，使每层图片顶部落在规格 screen-top y（天空 0 / 远山 70 /
## 云 10 / 近丘 112）。相机纵向范围仅 [90,102]，故此值对「玩家落地」的
## 常见情形精确成立；跳跃时相机上移，各层按其 scroll_scale.y 产生视差位移
## （这是视差的预期行为，非 bug）。

const TILE_REPEAT := Vector2(320, 0)

## [node 名, 纹理路径, sprite local_y, scroll_scale, autoscroll, z_index]
## autoscroll 单位：像素/秒（4.7.2 已验证）。
const LAYERS: Array = [
	["bg_sky", "res://assets/bg/bg_sky.png", 90.0, Vector2(0, 0), Vector2(0, 0), -100],
	["bg_far_mountains", "res://assets/bg/bg_far_mountains.png", 118.6, Vector2(0.15, 0.05), Vector2(0, 0), -85],
	["bg_clouds", "res://assets/bg/bg_clouds.png", 34.0, Vector2(0.25, 0), Vector2(-6, 0), -90],
	["bg_mid_hills", "res://assets/bg/bg_mid_hills.png", 145.2, Vector2(0.4, 0.1), Vector2(0, 0), -70],
]

func _ready() -> void:
	for L in LAYERS:
		add_child(_build_layer(L[0], L[1], L[2], L[3], L[4], L[5]))


func _build_layer(
	node_name: String,
	tex_path: String,
	local_y: float,
	scroll: Vector2,
	auto: Vector2,
	z: int,
) -> Parallax2D:
	var p := Parallax2D.new()
	p.name = node_name
	p.scroll_scale = scroll
	p.autoscroll = auto
	p.repeat_size = TILE_REPEAT
	p.repeat_times = 3
	p.z_index = z
	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.position = Vector2(160, local_y)
	p.add_child(spr)
	return p
