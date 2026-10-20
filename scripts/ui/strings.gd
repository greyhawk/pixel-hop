class_name Strings
## 游戏内所有用户可见文本（§7.2 提示牌 + §10 各界面）。
## 集中在此，M2 字体测试用它证明 TTF 覆盖游戏会渲染的每一个字符。

# —— §10.2 标题界面
const LOGO := "像素跳跳"
const SUBTITLE := "PIXEL HOP"
const MENU_START := "开始游戏"
const MENU_SELECT_LEVELS := "选择关卡"
const MENU_FULLSCREEN_OFF := "全屏：关"
const MENU_FULLSCREEN_ON := "全屏：开"
const MENU_QUIT := "退出游戏"
const HINT_TITLE := "[↑][↓] 选择　[Enter] 确认"
const VERSION := "v0.1"

# —— §10.3 选关界面
const SELECT_TITLE := "选择关卡"
const HINT_SELECT := "[Enter] 开始　[Esc] 返回"

# —— §7.2 META 关卡名（index 1..3）
const LEVEL_NAMES: Array = ["新手草原", "断崖小径", "尖刺山谷"]

# —— §10.4 HUD
const HUD_LIVES := "命 ×%d"
const HUD_COINS := "金币 %02d/%02d"
const HUD_TIME := "%02d:%02d"
const HUD_BANNER := "%s %s"

# —— §10.5 暂停
const PAUSE_TITLE := "暂停"
const PAUSE_RESUME := "继续游戏"
const PAUSE_RESTART := "重新开始本关"
const PAUSE_QUIT := "返回标题"
const HINT_PAUSE := "[Esc] 继续"

# —— §10.6 过关结算
const CLEAR_TITLE := "关卡完成！"
const CLEAR_COINS := "金币  %d / %d"
const CLEAR_PERFECT := "全收集！"
const CLEAR_TIME := "用时  %02d:%02d"
const CLEAR_MISTAKES := "失误  %d"
const CLEAR_NEXT := "下一关"
const CLEAR_REPLAY := "重玩"
const CLEAR_TO_TITLE := "标题"
const ALL_CLEAR_TITLE := "全部通关！"
const ALL_CLEAR_COINS := "总金币  %d / %d"
const ALL_CLEAR_QUIT := "返回标题"

# —— §10.7 游戏结束
const GAMEOVER_TITLE := "游戏结束"
const GAMEOVER_TEXT := "命数用尽了……"
const GAMEOVER_RETRY := "重试本关"
const GAMEOVER_QUIT := "返回标题"

# —— §7.2 1-1 提示牌文本（按列顺序对应 5 个 `h`）
const SIGN_TEXTS: Array = [
	"[A][D] 或 [←][→] 移动",
	"[Space] 跳跃，按住跳得更高",
	"从上方踩敌人可以消灭它",
	"单向平台：可从下方跳上，[↓]+[Space] 落下",
	"碰到旗帜就过关！",
]

# 动态显示的示例行：覆盖所有会渲染的数字/标点字符
const _SAMPLES: Array = [
	"1-1  新手草原    金币 11/11",
	"1-2  断崖小径    金币 17/17",
	"1-3  尖刺山谷    金币 8/8",
	"1-1  新手草原    金币 --/11",
	"命 ×3",
	"金币 07/17",
	"00:42",
	"1-1 新手草原",
	"金币  9 / 11",
	"用时  00:42",
	"失误  1",
	"总金币  36 / 36",
]


## 返回所有用户可见字符串（含示例行），供字体覆盖测试遍历。
static func all_strings() -> Array:
	var out: Array = [
		LOGO, SUBTITLE, MENU_START, MENU_SELECT_LEVELS,
		MENU_FULLSCREEN_OFF, MENU_FULLSCREEN_ON, MENU_QUIT,
		HINT_TITLE, VERSION,
		SELECT_TITLE, HINT_SELECT,
		HUD_LIVES, HUD_COINS, HUD_TIME, HUD_BANNER,
		PAUSE_TITLE, PAUSE_RESUME, PAUSE_RESTART, PAUSE_QUIT, HINT_PAUSE,
		CLEAR_TITLE, CLEAR_COINS, CLEAR_PERFECT, CLEAR_TIME,
		CLEAR_MISTAKES, CLEAR_NEXT, CLEAR_REPLAY, CLEAR_TO_TITLE,
		ALL_CLEAR_TITLE, ALL_CLEAR_COINS, ALL_CLEAR_QUIT,
		GAMEOVER_TITLE, GAMEOVER_TEXT, GAMEOVER_RETRY, GAMEOVER_QUIT,
	]
	out.append_array(LEVEL_NAMES)
	out.append_array(SIGN_TEXTS)
	out.append_array(_SAMPLES)
	return out
