class_name Enemy
extends CharacterBody2D
## §7.2 / §8: 巡逻敌人（Walker 可踩 / Spiky 不可踩）。
## 节点原点 = 脚底中心；身体向上延伸 body_height。
## 转向输入全部来自 EnemyLogic 纯函数；本脚本只负责采集条件与执行。
## 贴图由 SpriteFramesFactory 在 _ready 中从整图构建（与玩家一致）。

@export var stompable := true
@export var speed := Tuning.WALKER_SPEED
@export var body_height := 10.0
@export var sheet_path: String = "res://assets/sprites/enemies/walker_sheet.png"

## 关卡地图行（建造器注入），用于「前方一格是 ^」判断。
var map_rows: Array = []

var facing := -1
var squashed := false

var _sprite: AnimatedSprite2D
var _probe: RayCast2D
var _damage_area: Area2D
var _body: CollisionShape2D
var _squash_tween: Tween


func _ready() -> void:
	_sprite = $Sprite as AnimatedSprite2D
	_probe = $GroundProbe as RayCast2D
	_damage_area = $Damage as Area2D
	_body = $Body as CollisionShape2D
	_build_frames()
	_damage_area.body_entered.connect(_on_damage_body_entered)
	_update_probe_origin()
	_sprite.flip_h = facing < 0


## §5.3: 从整图构建动画帧。Walker：walk 4 帧 + squashed 1 帧；Spiky：walk 4 帧。
func _build_frames() -> void:
	var anims := [
		["walk", 0, 0, 4, 8.0, true],
	]
	if stompable:
		anims.append(["squashed", 1, 0, 1, 1.0, false])
	_sprite.sprite_frames = SpriteFramesFactory.build(sheet_path, anims)
	_sprite.play("walk")


func _physics_process(delta: float) -> void:
	if squashed:
		return
	velocity.y = minf(velocity.y + Tuning.ENEMY_GRAVITY * delta, Tuning.ENEMY_MAX_FALL)
	if _maybe_turn():
		facing = -facing
		_update_probe_origin()
		_sprite.flip_h = facing < 0
	velocity.x = float(facing) * speed
	move_and_slide()


## 采集转向条件并调用纯逻辑；返回是否掉头。
func _maybe_turn() -> bool:
	var on_wall := is_on_wall()
	var ground_ahead := _probe.is_colliding()
	var tile_ahead := _tile_ahead_char()
	# 敌人接触已通过 collision_mask 含敌人位折叠进 is_on_wall；
	# 保留 4 参数静态以便单测逐项验证 §7.2 的四个条件。
	return EnemyLogic.should_turn(on_wall, ground_ahead, tile_ahead, false)


## §7.2: 前方格字符。脚底中心沿 facing 方向 12 px（身体半宽 6 越过一格内）。
func _tile_ahead_char() -> String:
	if map_rows.is_empty():
		return "."
	var col := int(floor((global_position.x + facing * 12.0) / 16.0))
	var row := int(floor((global_position.y - 8.0) / 16.0))
	if row < 0 or row >= map_rows.size() or col < 0 or col >= map_rows[row].length():
		return "."
	return (map_rows[row] as String).substr(col, 1)


## 探针在脚底前侧 (facing*8, +2)，向下 4 px（ENEMY_GROUND_PROBE / _LEN）。
func _update_probe_origin() -> void:
	_probe.position = Vector2(facing * Tuning.ENEMY_GROUND_PROBE.x, Tuning.ENEMY_GROUND_PROBE.y)


## 玩家接触（仅敌人自身区域，mask = 玩家位）。
func _on_damage_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or squashed:
		return
	if not stompable:
		# §8: Spiky 不可踩——受伤 + 向上弹起 SPIKY_BOUNCE。
		player.damage(global_position, true)
		player.velocity.y = Tuning.SPIKY_BOUNCE
		return
	# §7.2 / §8: 踩踏判定用玩家脚底与敌人碰撞顶（玩家身体 (0,-7)：脚底 = 节点 y）。
	var player_feet := player.global_position.y
	if EnemyLogic.is_stomp(player.velocity.y, player_feet, global_position.y - body_height):
		_stomp(player)
	else:
		player.damage(global_position, false)


## §8: 踩扁：停物理、播 squashed，WALKER_SQUASH_TIME 后消失。
func _stomp(player: Player) -> void:
	squashed = true
	_damage_area.monitoring = false
	_damage_area.monitorable = false
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_sprite.play("squashed")
	player.stomp_bounce(player.input_source.jump_held())
	_squash_tween = create_tween()
	_squash_tween.tween_interval(Tuning.WALKER_SQUASH_TIME)
	_squash_tween.tween_callback(queue_free)
