class_name Sign
extends Node2D
## §7.2: 提示牌。根 = 牌脚（站立地面）。
## 玩家进入 Trigger 发 entered / 离开发 exited（气泡 UI = M7 订阅）。
## 视觉 = Polygon2D 占位（木板 + 立柱），建造器注入 text（§7.2 按列顺序）。

signal entered
signal exited

@export var text := ""


func _ready() -> void:
	var trigger := $Trigger as Area2D
	trigger.monitorable = false
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		entered.emit()


func _on_body_exited(body: Node) -> void:
	if body is Player:
		exited.emit()
