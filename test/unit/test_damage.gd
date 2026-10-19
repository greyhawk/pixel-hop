extends GutTest
## §8: Player 伤害 / 无敌帧 / 击退 / 踩敌弹跳 / 死亡 的节点级单测。
## 实例化玩家场景 + 一块静态地面。同步断言安全（GUT 不在同步调用之间跑帧）；
## 等无敌帧过期用 create_timer。

const PLAYER_SCENE := "res://scenes/player/player.tscn"

var _player: Player
var _floor: StaticBody2D
var _stomped_count := 0


func before_each() -> void:
	_floor = StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400.0, 16.0)
	shape.shape = rect
	_floor.add_child(shape)
	_floor.position = Vector2(80.0, 160.0)  # 地面顶面 y=160
	add_child(_floor)

	_player = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child(_player)
	_player.position = Vector2(80.0, 160.0)
	await get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(_player):
		_player.queue_free()
	if is_instance_valid(_floor):
		_floor.queue_free()


func test_fresh_player_has_full_hp() -> void:
	assert_eq(_player.hp, Tuning.MAX_HP, "新玩家满血")


func test_damage_deals_hp_and_knockback_away_from_source() -> void:
	_player.velocity = Vector2.ZERO
	_player.damage(Vector2(60.0, 160.0), false)  # 伤害源在玩家左侧
	assert_eq(_player.hp, 2, "受击一次 → hp 2")
	assert_almost_eq(_player.velocity.x, Tuning.KNOCKBACK.x, 0.01, "击退远离伤害源（向右）")
	assert_almost_eq(_player.velocity.y, Tuning.KNOCKBACK.y, 0.01, "击退向上")


func test_damage_from_right_knocks_left() -> void:
	_player.velocity = Vector2.ZERO
	_player.damage(Vector2(100.0, 160.0), false)
	assert_almost_eq(_player.velocity.x, -Tuning.KNOCKBACK.x, 0.01, "击退远离伤害源（向左）")


func test_spike_damage_deals_hp() -> void:
	_player.damage(Vector2(60.0, 160.0), true)
	assert_eq(_player.hp, 2, "尖刺伤害同样扣血")


func test_iframes_block_following_hits() -> void:
	_player.damage(Vector2(60.0, 160.0), false)
	_player.damage(Vector2(60.0, 160.0), false)
	assert_eq(_player.hp, 2, "无敌帧内的第二次受击被忽略")


func test_damage_allowed_after_iframe_expiry() -> void:
	_player.damage(Vector2(60.0, 160.0), false)
	await get_tree().create_timer(Tuning.IFRAMES + 0.1).timeout
	_player.damage(Vector2(60.0, 160.0), false)
	assert_eq(_player.hp, 1, "无敌帧结束后再次受击 → hp 1")


func test_third_hit_kills_player() -> void:
	_player.damage(Vector2(60.0, 160.0), false)
	await get_tree().create_timer(Tuning.IFRAMES + 0.1).timeout
	_player.damage(Vector2(60.0, 160.0), false)
	await get_tree().create_timer(Tuning.IFRAMES + 0.1).timeout
	_player.damage(Vector2(60.0, 160.0), false)
	assert_true(_player.dead, "hp 归零 → dead")


func test_stomp_bounce_sets_upward_velocity() -> void:
	_player.velocity = Vector2.ZERO
	_player.stomp_bounce(false)
	assert_almost_eq(_player.velocity.y, Tuning.STOMP_BOUNCE, 0.01, "普通踩踏 -220")
	_player.stomp_bounce(true)
	assert_almost_eq(_player.velocity.y, Tuning.STOMP_BOUNCE_HELD, 0.01, "按住跳踩踏 -300")


func test_stomp_bounce_emits_stomped() -> void:
	_stomped_count = 0
	_player.stomped.connect(_on_stomped)
	_player.stomp_bounce(false)
	assert_eq(_stomped_count, 1, "stomped 信号发出一次")


func _on_stomped() -> void:
	_stomped_count += 1


func test_victory_ignores_damage() -> void:
	_player.set_victory()
	_player.damage(Vector2(60.0, 160.0), false)
	assert_true(_player.victory, "胜利状态置位")
	assert_eq(_player.hp, Tuning.MAX_HP, "胜利时不再受伤")


func test_pit_death_hides_body_immediately() -> void:
	_player.die(true)
	assert_true(_player.dead, "坑死亡 → dead")
	assert_false(_player.visible, "坑死亡立即隐藏身体")
