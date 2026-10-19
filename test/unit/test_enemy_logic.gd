extends GutTest
## §7.2 / §8: EnemyLogic 纯函数单测——巡逻转向四条件与踩踏判定。
## 无场景依赖，直接调用静态方法。


func test_should_turn_on_wall() -> void:
	assert_true(EnemyLogic.should_turn(true, false, ".", false), "撞墙 → 掉头")


func test_should_turn_without_ground_ahead() -> void:
	assert_true(EnemyLogic.should_turn(false, false, ".", false), "前方无地面 → 掉头")


func test_should_turn_with_spike_ahead() -> void:
	assert_true(EnemyLogic.should_turn(false, true, "^", false), "前方一格是尖刺 → 掉头")


func test_should_turn_on_enemy_contact() -> void:
	assert_true(EnemyLogic.should_turn(false, true, ".", true), "撞上另一敌人 → 掉头")


func test_no_turn_in_open_terrain() -> void:
	assert_false(EnemyLogic.should_turn(false, true, ".", false), "开阔地面 → 继续直行")


func test_is_stomp_falling_onto_top() -> void:
	# 脚底 150 == 敌人顶 150，下落中 → 踩踏。
	assert_true(EnemyLogic.is_stomp(80.0, 150.0, 150.0), "垂直落到顶 → 踩踏")


func test_is_stomp_within_tolerance() -> void:
	# 脚底 155 ≤ 150 + 6（STOMP_TOLERANCE）→ 仍算踩踏。
	assert_true(EnemyLogic.is_stomp(80.0, 155.0, 150.0), "脚底低于顶 5px（≤6）→ 踩踏")


func test_is_stomp_at_tolerance_boundary() -> void:
	assert_true(EnemyLogic.is_stomp(80.0, 156.0, 150.0), "脚底恰在 顶+6 边界 → 踩踏")


func test_is_stomp_from_side_not_stomp() -> void:
	assert_false(EnemyLogic.is_stomp(80.0, 157.0, 150.0), "脚底低于顶 7px → 侧撞，不踩")


func test_is_stomp_requires_falling() -> void:
	assert_false(EnemyLogic.is_stomp(-50.0, 150.0, 150.0), "上升中 → 不踩")
	assert_false(EnemyLogic.is_stomp(0.0, 150.0, 150.0), "vy == 0 → 不踩")
