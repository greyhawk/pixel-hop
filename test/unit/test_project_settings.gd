extends GutTest
## Verifies every project.godot key from spec §4.2 is set exactly.


func test_display_settings() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 320, "viewport width")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 180, "viewport height")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/window_width_override")), 1280, "window override width")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/window_height_override")), 720, "window override height")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/mode")), "viewport", "stretch mode")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/aspect")), "keep", "stretch aspect")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/scale_mode")), "integer", "stretch scale mode")


func test_application_settings() -> void:
	assert_eq(str(ProjectSettings.get_setting("application/config/name")), "Pixel Hop", "project name")
	assert_eq(str(ProjectSettings.get_setting("application/run/main_scene")), "res://scenes/main.tscn", "main scene")


func test_autoloads() -> void:
	assert_eq(str(ProjectSettings.get_setting("autoload/Game")), "*res://autoload/game.gd", "Game autoload")
	assert_eq(str(ProjectSettings.get_setting("autoload/Transition")), "*res://autoload/transition.gd", "Transition autoload")
	assert_eq(str(ProjectSettings.get_setting("autoload/Audio")), "*res://autoload/audio.gd", "Audio autoload")


func test_layer_names() -> void:
	var expected := {
		"layer_names/2d_physics/layer_1": "world_solid",
		"layer_names/2d_physics/layer_2": "world_oneway",
		"layer_names/2d_physics/layer_3": "player",
		"layer_names/2d_physics/layer_4": "enemy",
		"layer_names/2d_physics/layer_5": "pickup",
		"layer_names/2d_physics/layer_6": "hazard",
	}
	for key in expected:
		assert_eq(str(ProjectSettings.get_setting(key)), expected[key], "layer name " + key)


func test_physics_settings() -> void:
	assert_eq(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")), 60, "physics ticks")
	assert_false(bool(ProjectSettings.get_setting("physics/common/physics_interpolation")), "physics interpolation must be off")


func test_rendering_settings() -> void:
	assert_eq(str(ProjectSettings.get_setting("rendering/renderer/rendering_method")), "gl_compatibility", "renderer")
	assert_eq(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")), 0, "Nearest filter")
	assert_true(bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")), "snap transforms")
	assert_false(bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel")), "snap vertices must be off (D4)")
