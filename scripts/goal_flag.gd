class_name GoalFlag
extends Node2D
## §8: 终点旗。根 = 杆脚（站立地面）。
## 玩家进入 Trigger → 输入锁定 + GROUND_DECEL 衰减（player.set_victory）、
## 旗面 0.6 s TRANS_SINE 从离地 12 px 升到杆顶、stop_bgm + sfx_flag、
## 0.2 s 后 jingle_level_complete，发 completed（结算面板 0.8 s = M6/M7）。

signal completed

const CLOTH_START_Y := -17.0
const CLOTH_TOP_Y := -43.0

var _done := false
var _confetti: CPUParticles2D


func _ready() -> void:
	var trigger := $Trigger as Area2D
	trigger.monitorable = false
	trigger.body_entered.connect(_on_body_entered)
	var cloth := $Cloth as AnimatedSprite2D
	cloth.position = Vector2(6, CLOTH_START_Y)
	_build_cloth_frames(cloth)
	_build_confetti()


## §6.2: flag_cloth_sheet.png 为 48×10 的 4 帧横排（12×10/帧），手动切图。
func _build_cloth_frames(cloth: AnimatedSprite2D) -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("wave")
	frames.set_animation_speed("wave", 8.0)
	frames.set_animation_loop("wave", true)
	var atlas := load("res://assets/sprites/items/flag_cloth_sheet.png") as Texture2D
	for i in 4:
		var tex := AtlasTexture.new()
		tex.atlas = atlas
		tex.region = Rect2i(i * 12, 0, 12, 10)
		frames.add_frame("wave", tex)
	cloth.sprite_frames = frames
	cloth.play("wave")


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or _done:
		return
	_done = true
	Audio.stop_bgm()
	Audio.play_sfx("sfx_flag")
	get_tree().create_timer(Tuning.JINGLE_DELAY).timeout.connect(
		func() -> void: Audio.play_sfx("jingle_level_complete")
	)
	player.set_victory()
	_raise_cloth()
	_emit_confetti()
	completed.emit()


## §8: 旗面 0.6 s TRANS_SINE 从杆底升到杆顶（帧顶对齐 y=-48）。
func _raise_cloth() -> void:
	var cloth := $Cloth as AnimatedSprite2D
	var tween := create_tween()
	tween.tween_property(cloth, "position:y", CLOTH_TOP_Y, Tuning.FLAG_RAISE) \
		.set_trans(Tween.TRANS_SINE)


## §10.10 一次性彩带喷发：杆顶向上、24 粒、重力回落。
func _emit_confetti() -> void:
	if _confetti != null:
		_confetti.restart()


## 构建一次性彩带粒子（_ready 调用）。杆脚为原点，喷发点 (0,-48)=杆顶。
func _build_confetti() -> void:
	var c := CPUParticles2D.new()
	c.position = Vector2(0, -48)
	c.emitting = false
	c.one_shot = true
	c.amount = 24
	c.lifetime = 1.0
	c.direction = Vector2(0, -1)
	c.spread = 30.0
	c.initial_velocity_min = 80.0
	c.initial_velocity_max = 120.0
	c.gravity = Vector2(0, 200)
	var tex := load("res://assets/sprites/fx/confetti_px.png") as Texture2D
	if tex != null:
		c.texture = tex
	c.color_ramp = OneShotFx.confetti_ramp()
	add_child(c)
	_confetti = c
