class_name Spike
extends Area2D
## §8: 尖刺。根 = 瓦片左上角；伤害区为瓦片下半部 12×8 @(8,12)。
## 玩家接触 → damage(源=尖刺中心, is_spike=true)（sfx_spike / 白闪 = M8）。
## 视觉 = Polygon2D 占位（两齿锯齿，§6.2 之外不加 PNG，见 README）。


func _ready() -> void:
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null:
		return
	player.damage(global_position + Vector2(8, 12), true)
