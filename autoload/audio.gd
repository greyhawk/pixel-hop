extends Node
## Silent no-op audio interface (spec §10.11). This phase has NO audio files,
## buses, or playback — game code calls these at the right moments.

func play_sfx(_name: String, _pitch: float = 1.0) -> void:
	print_verbose("Audio.play_sfx(%s)" % _name)


func play_bgm(_name: String) -> void:
	print_verbose("Audio.play_bgm(%s)" % _name)


func stop_bgm() -> void:
	print_verbose("Audio.stop_bgm()")


func duck_music(_db: float) -> void:
	print_verbose("Audio.duck_music(%.0f)" % _db)
