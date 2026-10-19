extends Control
## §10.7: Game Over 界面（M6 最小可工作版）。
## 黑背景 + 标题 + 文本 + 两行菜单（重试本关 / 返回标题）：
## ↑↓ 移动选择、Enter 确认；0.6 s（RESULT_INPUT_GRACE）内忽略输入。
## 重试本关 → Game.retry_after_game_over()（命数=3、重进当前关，D23）。
## 0.5 s 淡入 / 面板装饰 / 按键提示细节 = M7。
## 文本在 _ready 从 Strings 常量刷新（单一来源）；几何布局在 .tscn。


func _ready() -> void:
	theme = UiTheme.build()
	$Title.text = Strings.GAMEOVER_TITLE
	$Text.text = Strings.GAMEOVER_TEXT
	$Hint.text = Strings.HINT_TITLE
	_apply_selection()
	Audio.play_sfx("jingle_game_over")


var _sel := 0
var _accept_t := 0.0


func _process(delta: float) -> void:
	_accept_t += delta


func _unhandled_input(event: InputEvent) -> void:
	if _accept_t < Tuning.RESULT_INPUT_GRACE:
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		var dir := 1 if event.is_action_pressed("ui_down") else -1
		_sel = (_sel + dir + 2) % 2
		_apply_selection()
	elif event.is_action_pressed("ui_accept"):
		_do_action()


func _do_action() -> void:
	var action := "retry" if _sel == 0 else "quit"
	if Game.smoke_mode:
		print("GAMEOVER ACTION: %s" % action)
		return
	if action == "retry":
		Game.retry_after_game_over()
	else:
		Game.go_title()


func _apply_selection() -> void:
	$Retry.modulate.a = 1.0 if _sel == 0 else 0.6
	$Quit.modulate.a = 1.0 if _sel == 1 else 0.6
