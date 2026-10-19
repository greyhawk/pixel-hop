class_name EnemyLogic
extends RefCounted
## §7.2 / §8: 敌人纯逻辑（无场景依赖，可单测）。
## 敌人本体（enemy.gd）负责采集输入条件并调用这两个静态函数。


## §7.2: 是否掉头。四个条件任一成立即掉头：
## - 撞墙（is_on_wall，含撞上另一个敌人——mask 含敌人位）
## - 脚前下方无地面（悬空/悬崖，射线探针未命中）
## - 前方一格是 ^（尖刺）
## - 与另一敌人接触（调用方通过 is_on_wall 折叠，保留参数供单测逐项验证）
static func should_turn(on_wall: bool, ground_ahead: bool, tile_ahead_char: String, hit_enemy: bool) -> bool:
	if on_wall:
		return true
	if not ground_ahead:
		return true
	if tile_ahead_char == "^":
		return true
	return hit_enemy


## §7.2: 踩踏判定。玩家下落（vy > 0）且脚底不高于敌人碰撞顶 + STOMP_TOLERANCE。
static func is_stomp(player_vy: float, player_feet_y: float, enemy_top_y: float) -> bool:
	return player_vy > 0.0 and player_feet_y <= enemy_top_y + Tuning.STOMP_TOLERANCE
