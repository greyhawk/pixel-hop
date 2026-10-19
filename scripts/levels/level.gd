class_name Level
extends Node2D
## §7: Level scene root. `level_index` is a Levels.MAPS key (1-3).
## Children (Terrain, Decor, Entities, Bounds, Camera) are built in
## _ready by LevelBuilder — set level_index before add_child.

var level_index: int = 1


func _ready() -> void:
	LevelBuilder.build(self, level_index)
