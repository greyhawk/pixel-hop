extends GutTest
## MenuList 键盘菜单覆盖（M7）：双向环绕、跳过禁用项、禁用项不可确认、
## 换文本重测量、纵/横向布局。全部自建实例（不触碰 Game 状态）。

var parent: Control
var menu: MenuList
var accepted_idx := -1


func before_each() -> void:
	parent = Control.new()
	parent.size = Vector2(320, 180)
	parent.theme = UiTheme.build()
	get_tree().root.add_child(parent)
	menu = MenuList.new()
	parent.add_child(menu)
	await get_tree().process_frame


func after_each() -> void:
	parent.queue_free()
	await get_tree().process_frame


func _on_accepted(i: int) -> void:
	accepted_idx = i


func test_wrap_around_both_directions() -> void:
	menu.build(["A", "B", "C"])
	assert_eq(menu.selected_index, 0, "默认选中 0")
	assert_true(menu.press_move(1), "0 → 1")
	assert_true(menu.press_move(1), "1 → 2")
	assert_true(menu.press_move(1), "2 环绕 → 0")
	assert_true(menu.press_move(-1), "0 反向环绕 → 2")
	assert_true(menu.press_move(-1), "2 → 1")


func test_disabled_skip_and_first_enabled_default() -> void:
	menu.build(["A", "B", "C"], [true, false, false])
	assert_eq(menu.selected_index, 1, "默认选中首个可点项 B")
	assert_true(menu.press_move(-1), "上移跳过禁用的 0")
	assert_eq(menu.selected_index, 2, "落到 C（而非禁用的 A）")


func test_accept_disabled_returns_minus_one() -> void:
	menu.build(["A", "B"], [false, true])
	menu.accepted.connect(_on_accepted)
	menu.selected_index = 1
	assert_false(menu.can_accept(), "禁用项 can_accept 为 false")
	assert_eq(menu.press_accept(), -1, "禁用项确认 → -1")
	assert_eq(accepted_idx, -1, "不发射 accepted")


func test_accept_emits_selected() -> void:
	menu.build(["A", "B"])
	menu.accepted.connect(_on_accepted)
	assert_eq(menu.press_accept(), 0, "确认 → 当前索引 0")
	assert_eq(accepted_idx, 0, "发射 accepted(0)")


func test_set_item_text_remeasures() -> void:
	menu.build(["A"])
	var w0 := menu.row_size(0).x
	menu.set_item_text(0, "这是一个比较长的菜单条目文本")
	assert_gt(menu.row_size(0).x, w0, "换长文本后行宽重测变宽")


func test_centered_vertical_layout() -> void:
	menu.build(["甲", "乙", "丙"], [], false, 14.0, true)
	var p0 := menu.row_position(0)
	var p1 := menu.row_position(1)
	assert_eq(p0.y, 0.0, "首行 y=0")
	assert_eq(p1.y, 14.0, "次行 y=pitch")
	assert_lt(p0.x, 0.0, "居中 → x 为负半宽")
	assert_lt(p1.x, 0.0, "居中 → x 为负半宽")


func test_horizontal_layout() -> void:
	menu.build(["甲", "乙"], [], true, 14.0, true)
	var p0 := menu.row_position(0)
	var p1 := menu.row_position(1)
	assert_eq(p0.y, 0.0, "横排两行 y=0")
	assert_eq(p1.y, 0.0, "横排两行 y=0")
	assert_gt(p1.x, p0.x, "第二项 x 在第一项之后")
