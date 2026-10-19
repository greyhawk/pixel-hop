extends CanvasLayer
## Black-curtain scene transition (layer 20, spec §11).

var is_busy := false
var _color: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 20
	_color = ColorRect.new()
	_color.color = Color(0.102, 0.110, 0.173)  # #1a1c2c
	_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color.modulate.a = 0.0
	_color.z_index = 100
	add_child(_color)


## Fades out, switches scene, fades in. Ignores calls while busy.
func change_scene(path: String) -> void:
	if is_busy:
		return
	is_busy = true
	_tween = create_tween()
	_tween.tween_property(_color, "modulate:a", 1.0, Tuning.FADE_TIME)
	await _tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_tween = create_tween()
	_tween.tween_property(_color, "modulate:a", 0.0, Tuning.FADE_TIME)
	await _tween.finished
	is_busy = false
