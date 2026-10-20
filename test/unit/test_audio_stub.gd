extends GutTest
## Audio must be a silent no-op: callable, no errors, and the repo must
## contain no audio files (spec §10.11 / §1.2).


func test_audio_stub_is_silent_noop() -> void:
	# Game code (M6+) calls these exact names; pin the interface so a
	# rename/typo in the stub breaks the build, not M6.
	assert_true(Audio.has_method("play_sfx"), "Audio.play_sfx must exist")
	assert_true(Audio.has_method("play_bgm"), "Audio.play_bgm must exist")
	assert_true(Audio.has_method("stop_bgm"), "Audio.stop_bgm must exist")
	assert_true(Audio.has_method("duck_music"), "Audio.duck_music must exist")
	# Calls must be side-effect-free no-ops; GUT's error tracker fails this
	# test if any of them raises (play_sfx's second arg is optional).
	Audio.play_sfx("sfx_jump")
	Audio.play_sfx("sfx_coin", 1.2)
	Audio.play_bgm("bgm_level")
	Audio.stop_bgm()
	Audio.duck_music(-10.0)


func test_no_audio_files_in_repo() -> void:
	assert_eq(_count_audio_files("res://assets"), 0, "assets/ must contain no .wav/.ogg")
	assert_eq(_count_audio_files("res://scenes"), 0, "scenes/ must contain no .wav/.ogg")


func _count_audio_files(dir_path: String) -> int:
	var da := DirAccess.open(dir_path)
	if da == null:
		return 0
	var count := 0
	da.list_dir_begin()
	var entry := da.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			if da.current_is_dir():
				count += _count_audio_files(dir_path.path_join(entry))
			else:
				var ext := entry.get_extension().to_lower()
				if ext == "wav" or ext == "ogg":
					count += 1
		entry = da.get_next()
	da.list_dir_end()
	return count
