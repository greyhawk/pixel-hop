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

## §8 M5: 生命 / 无敌 / 死亡 / 胜利状态。
var hp := Tuning.MAX_HP
var dead := false
var victory := false
var _iframe_timer := 0.0
var _hurt_lock := 0.0
var _death_timer := 0.0
var _fade_started := false
var _stomp_chain := 0

var _sprite: AnimatedSprite2D
var _motor := PlayerMotor.new()
var _drop_timer := 0.0
var _was_on_floor := true
## M8: 受击闪白材质与跑动尘土。
var _flash_mat: ShaderMaterial = null
var _dust: CPUParticles2D = null


func _ready() -> void:
	if input_source == null:
		input_source = InputSource.KeyboardInputSource.new()
	_sprite = $Sprite
	_build_frames()
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("idle")
	# M8: 受击闪白 + 跑动尘土。
	_setup_flash()
	_setup_dust()


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
	if dead:
		_death_step(delta)
		return
	input_source.begin_frame()
	var locked := victory or _hurt_lock > 0.0
	var dir := int(roundf(input_source.get_axis())) if not locked else 0
	var pressed := input_source.jump_pressed() if not locked else false
	var released := input_source.jump_released() if not locked else false
	var down := input_source.down_held() if not locked else false
	if _hurt_lock > 0.0:
		_hurt_lock -= delta
	if _iframe_timer > 0.0:
		_iframe_timer -= delta
		if _iframe_timer <= 0.0:
			_iframe_timer = 0.0
			_sprite.visible = true
		else:
			# §8: 无敌期间每 IFRAME_BLINK 秒切换一次可见。
			_sprite.visible = fmod(_iframe_timer, Tuning.IFRAME_BLINK * 2.0) < Tuning.IFRAME_BLINK
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
	# 4. 落地 / 起跳事件 + M8 尘土
	var on_floor := is_on_floor()
	# M8: 起跳尘土（离开地面向上瞬间）。
	if _was_on_floor and not on_floor and velocity.y < 0.0:
		_spawn_jump_puff()
	# M8: 跑动尘土（地面、非死亡、横向速度 > DUST_MIN_VX）。
	_set_running_dust(on_floor and not dead and absf(velocity.x) > Tuning.DUST_MIN_VX)
	if not _was_on_floor and on_floor and vy_before >= 0.0:
		landed.emit(vy_before)
		_stomp_chain = 0
		if victory:
			_sprite.play("victory")
		elif vy_before >= Tuning.LAND_PUFF_MIN_VY:
			_sprite.play("land")
			_spawn_land_puff()
			# M8: 硬落地震屏（下落速度 >= 300，§8 注释）。
			if vy_before >= 300.0:
				Game.feedback(Tuning.SHAKE_HARD_LAND)
	_was_on_floor = on_floor
	# 5. 朝向与动画
	_update_facing(dir)
	_update_animation()


## M6 重生：重置运动学、碰撞与 M5 伤害/死亡状态。
func reset_state() -> void:
	_motor.reset()
	_drop_timer = 0.0
	collision_mask = FULL_MASK
	_was_on_floor = true
	velocity = Vector2.ZERO
	hp = Tuning.MAX_HP
	dead = false
	victory = false
	_iframe_timer = 0.0
	_hurt_lock = 0.0
	_death_timer = 0.0
	_fade_started = false
	_stomp_chain = 0
	# M8: 重置受击闪白与尘土。
	if _flash_mat != null:
		_flash_mat.set_shader_parameter("flash_amount", 0.0)
	if _dust != null:
		_dust.emitting = false
	visible = true
	_sprite.visible = true
	_sprite.play("idle")


## §8: 受击。无敌帧内 / 死亡 / 胜利时忽略。
## 击退方向远离伤害源（±KNOCKBACK.x, KNOCKBACK.y），锁定控制 HURT_LOCK，
## 无敌 IFRAMES（期间仍可踩敌）。hp <= 0 → die。
func damage(source: Vector2, is_spike: bool) -> void:
	if dead or victory or _iframe_timer > 0.0:
		return
	hp -= 1
	# M6: 同步到 GameState（两边同为 3、随重生/重开一起重置，不会漂移）。
	if Game.state != null:
		Game.state.apply_damage()
	_hurt_lock = Tuning.HURT_LOCK
	_iframe_timer = Tuning.IFRAMES
	_sprite.visible = true
	var dir_sign := signf(global_position.x - source.x)
	if dir_sign == 0.0:
		dir_sign = float(facing)
	velocity = Vector2(dir_sign * Tuning.KNOCKBACK.x, Tuning.KNOCKBACK.y)
	Audio.play_sfx("sfx_spike" if is_spike else "sfx_hurt")
	hurt.emit()
	# M8: 受击闪白 + 火花；死亡由 die 统一震屏，否则受击震屏。
	_flash_hit()
	OneShotFx.spawn_named(get_parent(), global_position, "hit_spark")
	if hp <= 0:
		die(false)
	else:
		Game.feedback(Tuning.SHAKE_HURT)


## §8: 踩敌弹跳（-220 / 按住跳 -300）；连续踩踏音高 ×STOMP_PITCH_STEP，落地重置。
## 无敌帧期间仍然可以踩敌（仅死亡/胜利忽略）。
func stomp_bounce(jump_held: bool) -> void:
	if dead or victory:
		return
	velocity.y = Tuning.STOMP_BOUNCE_HELD if jump_held else Tuning.STOMP_BOUNCE
	_stomp_chain += 1
	Audio.play_sfx("sfx_stomp", pow(Tuning.STOMP_PITCH_STEP, _stomp_chain))
	Game.feedback(Tuning.SHAKE_STOMP)
	stomped.emit()


## §8: 到达终点旗——锁定输入，水平速度按 GROUND_DECEL 衰减，落地播 victory。
func set_victory() -> void:
	if dead or victory:
		return
	victory = true
	_stomp_chain = 0


## §8: 死亡。from_pit 直接隐藏身体（无物理）；否则播 death 帧、关碰撞、
## vy = DEATH_POP_VY 上抛，之后只受 GRAVITY_UP。t=DEATH_FADE_AT 拉黑幕 + 发 died。
func die(from_pit: bool) -> void:
	if dead or victory:
		return
	dead = true
	# M8: 死亡震屏/hitstop（§15.4）。
	Game.feedback(Tuning.SHAKE_DEATH)
	_death_timer = 0.0
	_iframe_timer = 0.0
	_hurt_lock = 0.0
	_sprite.visible = true
	Audio.play_sfx("sfx_death")
	Audio.stop_bgm()
	if from_pit:
		visible = false
	else:
		velocity = Vector2(0.0, Tuning.DEATH_POP_VY)
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		_sprite.play("death")


## §8: 死亡物理——只受重力上抛/下落，无输入、无碰撞（mask 已清零）。
func _death_step(delta: float) -> void:
	_death_timer += delta
	if visible:
		velocity.y = minf(velocity.y + Tuning.GRAVITY_UP * delta, Tuning.ENEMY_MAX_FALL)
		move_and_slide()
	if not _fade_started and _death_timer >= Tuning.DEATH_FADE_AT:
		_fade_started = true
		Transition.fade_to_black(Tuning.DEATH_FADE)
		died.emit()


func _update_facing(dir: int) -> void:
	var d := dir
	if d == 0:
		d = signf(velocity.x) if absf(velocity.x) > 1.0 else 0.0
	if d != 0.0:
		facing = int(d)
	_sprite.flip_h = facing < 0


func _update_animation() -> void:
	if dead:
		return
	if _sprite.animation == "land":
		return
	if victory and _sprite.animation == "victory":
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

## M8: 受击闪白——给 Sprite 套 flash.gdshader，flash_amount 1→0 衰减。
func _setup_flash() -> void:
	var shader := load("res://shaders/flash.gdshader") as Shader
	if shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("flash_amount", 0.0)
	_flash_mat = mat
	_sprite.material = mat


func _flash_hit() -> void:
	if _flash_mat == null:
		return
	_flash_mat.set_shader_parameter("flash_amount", 1.0)
	var tw := create_tween()
	tw.tween_method(_set_flash, 1.0, 0.0, Tuning.HURT_FLASH)


func _set_flash(v: float) -> void:
	if _flash_mat != null:
		_flash_mat.set_shader_parameter("flash_amount", v)


## M8: 跑动尘土（CPUParticles2D，地面 + 横向速度 > DUST_MIN_VX 时发射）。
func _setup_dust() -> void:
	var particles := CPUParticles2D.new()
	particles.name = "Dust"
	particles.emitting = false
	particles.one_shot = false
	particles.amount = 6
	particles.lifetime = 0.3
	particles.direction = Vector2(-1.0, -0.6)
	particles.spread = 20.0
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 24.0
	particles.gravity = Vector2(0.0, 120.0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	var tex := load("res://assets/sprites/fx/dust_px.png") as Texture2D
	if tex != null:
		particles.texture = tex
	add_child(particles)
	_dust = particles


func _set_running_dust(active: bool) -> void:
	if _dust == null:
		return
	_dust.emitting = active
	if active:
		_dust.direction = Vector2(-float(facing), -0.6)


func _spawn_jump_puff() -> void:
	OneShotFx.spawn_named(get_parent(), global_position, "jump_puff")


func _spawn_land_puff() -> void:
	OneShotFx.spawn_named(get_parent(), global_position, "land_puff")
