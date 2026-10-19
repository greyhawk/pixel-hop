class_name Coin
extends Area2D
## §8: 金币。玩家进入 Area2D 即拾取：
## - sfx_coin（连续拾取 0.5 s 内音高 +0.05/枚，上限 1.3，超时重置 1.0）
## - 上浮 10 px（0.25 s TRANS_QUAD / EASE_OUT）+ 0.15 s 淡出后移除
## - 悬浮呼吸：±1 px、周期 1.2 s、相位 column * 0.3，结果取整
## （+1 飘字 / 粒子 = M8。）

signal collected

## 建造器注入的地图列号（bob 相位）。
@export var column := 0

## 连续拾取音高链（§8 0.5 s 窗口），跨实例共享。
static var _last_pickup_t := -INF
static var _chain_pitch := 1.0

var _taken := false
var _t := 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	monitorable = false
	_sprite = $Sprite as AnimatedSprite2D
	_build_spin_frames()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	var phase := TAU * (_t + float(column) * 0.3) / Tuning.COIN_BOB_PERIOD
	_sprite.offset.y = float(int(roundf(sin(phase) * Tuning.COIN_BOB_AMPL)))


## §6.2: coin_sheet.png 为 48×8 的 6 帧横排（非 16 px 格），手动切图。
## 帧率 12 fps 为占位假定（规格未指定，见 README）。
func _build_spin_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 12.0)
	frames.set_animation_loop("spin", true)
	var atlas := load("res://assets/sprites/items/coin_sheet.png") as Texture2D
	for i in 6:
		var tex := AtlasTexture.new()
		tex.atlas = atlas
		tex.region = Rect2i(i * 8, 0, 8, 8)
		frames.add_frame("spin", tex)
	_sprite.sprite_frames = frames
	_sprite.play("spin")


## 拾取音高：窗口内递增，否则重置。
static func _next_pitch() -> float:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_pickup_t <= Tuning.COIN_PITCH_WINDOW:
		_chain_pitch = minf(_chain_pitch + Tuning.COIN_PITCH_STEP, Tuning.COIN_PITCH_MAX)
	else:
		_chain_pitch = 1.0
	_last_pickup_t = now
	return _chain_pitch


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or _taken:
		return
	_taken = true
	set_deferred("monitoring", false)
	Audio.play_sfx("sfx_coin", _next_pitch())
	collected.emit()
	var tween := create_tween()
	tween.tween_property(_sprite, "offset:y", -Tuning.COIN_RISE, Tuning.COIN_RISE_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, Tuning.COIN_FADE_TIME) \
		.set_delay(Tuning.COIN_RISE_TIME - Tuning.COIN_FADE_TIME)
	tween.tween_callback(queue_free)
