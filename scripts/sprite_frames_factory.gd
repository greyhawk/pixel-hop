class_name SpriteFramesFactory
extends RefCounted
## 从精灵表按行/列范围批量构建 SpriteFrames（16 px 单元，AtlasTexture 无复制）。
## M4 玩家使用；M5 敌人复用。

## `anims`：Array，每行 [name: String, row: int, col0: int, count: int, fps: float, loop: bool]。
static func build(sheet_path: String, anims: Array) -> SpriteFrames:
	var sheet := load(sheet_path) as Texture2D
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for a in anims:
		var name: String = a[0]
		var row: int = a[1]
		var col0: int = a[2]
		var count: int = a[3]
		var fps: float = a[4]
		var loop: bool = a[5]
		frames.add_animation(name)
		frames.set_animation_speed(name, fps)
		frames.set_animation_loop(name, loop)
		for i in count:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2i((col0 + i) * Tuning.TILE, row * Tuning.TILE, Tuning.TILE, Tuning.TILE)
			frames.add_frame(name, at)
	return frames
