extends Node
## Boot shell (D17): immediately transition to the title screen.


func _ready() -> void:
	Transition.change_scene(Game.TITLE_SCENE)
