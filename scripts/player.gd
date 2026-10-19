class_name Player
extends CharacterBody2D
## §9.1：玩家。组合 PlayerMotor（运动学）+ InputSource（输入）+ 单向平台落下 +
## 顶头角落修正 + 落地事件。M5 起接入伤害 / 无敌 / 死亡（信号已声明）。
## 碰撞：layer=4（player），mask=3（solid | oneway）；落下时临时 SOLID_ONLY=1。

signal hurt
signal died
signal stomped
signal landed(vy: float)

const SHEET_PATH := "res://assets/sprites/player/player_sheet.png"
const FULL_MASK := 3
const SOLID_MASK := 1
## 碰撞盒（脚底在原点，§5.2）。
const BODY := Vector2(10.0, 14.0)

## 由 LevelBuilder 注入（solid + oneway 同在 "Terrain" 层，供落下/顶头探针）。
var terrain: TileMapLayer = null
## 由 LevelBuilder / Game 注入；缺省为键盘。
var input_source: InputSource = null
var facing := 1

var _sprite: AnimatedSprite2D
var _motor := PlayerMotor.new()
var _drop_timer := 0.0
var _was_on_floor := true


func _ready() -> void:
	if input_source == null:
		input_source = InputSource.KeyboardInputSource.new()
	_sprite = $Sprite
	_build_frames()
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("idle")


## §5.2 玩家精灵表（6×7×16 px）：row0 idle、row1 run、row2 jump/fall、
## row3 land、row4 hurt、row5 death、row6 victory（M5/M7 起使用）。
func _build_frames() -> void:
	var anims := [
		["idle", 0, 0, 4, 6.0, true],
		["run", 1, 0, 6, 12.0, true],
		["jump", 2, 0, 1, 5.0, false],
		["fall", 2, 1, 1, 5.0, false],
		["land", 3, 0, 2, 15.0, false],
		["hurt", 4, 0, 2, 10.0, true],
		["death", 5, 0, 1, 5.0, false],
		["victory", 6, 0, 2, 4.0, true],
	]
	_sprite.sprite_frames = SpriteFramesFactory.build(SHEET_PATH, anims)


func _physics_process(delta: float) -> void:
	input_source.begin_frame()
	var dir := int(roundf(input_source.get_axis()))
	var pressed := input_source.jump_pressed()
	var released := input_source.jump_released()
	var down := input_source.down_held()
	# 1. 单向平台落下（§9.4）：在地面 + 下压 + 跳按/按住，且脚下是单向
	if _drop_timer <= 0.0:
		if is_on_floor() and down and (pressed or input_source.jump_held()) and _on_one_way():
			_drop_timer = Tuning.DROP_THROUGH_TIME
			collision_mask = SOLID_MASK
			pressed = false
	else:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			collision_mask = FULL_MASK
	# 2. 运动学 + 移动
	var out: Dictionary = _motor.step(velocity, dir, pressed, input_source.jump_held(), released, is_on_floor(), delta)
	velocity = out["velocity"]
	var vy_before := velocity.y
	move_and_slide()
	# 3. 顶头角落修正（§9.5）
	_corner_correction(vy_before)
	# 4. 落地事件（M8 接土星）
	var on_floor := is_on_floor()
	if not _was_on_floor and on_floor and vy_before >= 0.0:
		landed.emit(vy_before)
		if vy_before >= Tuning.LAND_PUFF_MIN_VY:
			_sprite.play("land")
	_was_on_floor = on_floor
	# 5. 朝向与动画
	_update_facing(dir)
	_update_animation()


## M6 重生：重置运动学与碰撞状态。
func reset_state() -> void:
	_motor.reset()
	_drop_timer = 0.0
	collision_mask = FULL_MASK
	_was_on_floor = true
	velocity = Vector2.ZERO


func _update_facing(dir: int) -> void:
	var d := dir
	if d == 0:
		d = signf(velocity.x) if absf(velocity.x) > 1.0 else 0.0
	if d != 0.0:
		facing = int(d)
	_sprite.flip_h = facing < 0


func _update_animation() -> void:
	if _sprite.animation == "land":
		return
	var anim := "idle"
	if not is_on_floor():
		anim = "fall" if velocity.y > Tuning.ANIM_FALL_VY else "jump"
	elif absf(velocity.x) > 10.0:
		anim = "run"
	if _sprite.animation != anim:
		_sprite.play(anim)


func _on_animation_finished() -> void:
	if _sprite.animation == "land":
		_update_animation()


## 脚下（脚底向下探 1 px）是否为单向平台瓦片。
func _on_one_way() -> bool:
	if terrain == null:
		return false
	var cell := Vector2i(
		int(floorf(global_position.x / float(Tuning.TILE))),
		int(floorf((global_position.y + 1.0) / float(Tuning.TILE))),
	)
	var td := terrain.get_cell_tile_data(cell)
	return td != null and td.physics_layer_id == TilesetFactory.LAYER_ONEWAY


## §9.5：顶头时头部与 solid 瓦片重叠 ≤ CORNER_CORRECTION px 则把身体推出角落。
func _corner_correction(vy_before: float) -> void:
	if not is_on_ceiling() or vy_before >= 0.0:
		return
	if terrain == null:
		return
	var px := global_position.x
	var head_top := global_position.y - BODY.y
	var row := int(floorf((head_top - 0.01) / float(Tuning.TILE)))
	var c0 := int(floorf((px - BODY.x * 0.5) / float(Tuning.TILE)))
	var c1 := int(floorf((px + BODY.x * 0.5 - 0.01) / float(Tuning.TILE)))
	for c in range(c0, c1 + 1):
		var td := terrain.get_cell_tile_data(Vector2i(c, row))
		if td == null or td.physics_layer_id != TilesetFactory.LAYER_SOLID:
			continue
		var overlap := minf(px + BODY.x * 0.5, float((c + 1) * Tuning.TILE)) - maxf(px - BODY.x * 0.5, float(c * Tuning.TILE))
		if overlap <= 0.0 or overlap > Tuning.CORNER_CORRECTION:
			continue
		var sign := signf(px - float((c + 0.5) * Tuning.TILE))
		if sign == 0.0:
			sign = float(facing)
		global_position.x += sign * overlap
		velocity.y = vy_before
		break
