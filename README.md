# 像素跳跳（pixel-hop）

Godot 4.7.2 像素平台小游戏：3 个关卡、16×16 瓦片、320×180 内部分辨率、中文界面。

## 字体（Font Attribution）

UI 文本使用 **Fusion Pixel Font 12px proportional**（zh-hans 子集，版本 2026.10.16），
作者 **TakWolf**，采用 **SIL Open Font License 1.1（OFL 1.1）** 授权。

- 字体文件：`assets/fonts/fusion-pixel-12px-proportional-zh_hans.ttf`
- 许可证全文：`assets/fonts/OFL.txt`（适用于该 TTF）

该字体由三个 OFL 字体合并而成，原始许可证文件一并保留：

- `assets/fonts/LICENSES/ark-pixel/OFL.txt`（ark-pixel）
- `assets/fonts/LICENSES/cubic-11/OFL.txt`（cubic-11）
- `assets/fonts/LICENSES/galmuri/LICENSE.txt`（galmuri）

主题（`scripts/ui/ui_theme.gd`）在 `load()` 后用代码关闭抗锯齿、提示、
亚像素定位、mipmap 与 MSDF，保证 12px 字形在 16×16 网格上保持锐利。
若字体文件缺失，主题退回引擎默认字体并 `push_warning`（不报错）。

## M5：物品 / 敌人 / 伤害 / 死亡

关卡实体（`level_builder.gd` 按地图字符实例化）：金币（`o`，旋转动画、
拾取上浮 + 连续拾取音高链）、Walker（`E`，可踩）、Spiky（`S`，不可踩）、
尖刺（`^`）、指示牌（`h`，进入触发 `entered` 信号，文案按列序取自
`Strings.SIGN_TEXTS`）、终点旗（`F`，布面升起 + 关卡完成信号）。

伤害：受击扣 1 HP、0.25s 受击硬直、1.0s 无敌帧（闪烁）、按方向击退；
尖刺伤害不可被踩踏化解。踩敌弹跳（按住跳更高、连踩音高递增）在无敌帧
期间仍然生效。死亡：落坑立即隐藏身体；HP 归零上抛 + 淡出黑幕并发出
`died` 信号；`Level` 持有本关 `lives` 计数器并在玩家死亡时冻结镜头。
音频接口（`autoload/audio.gd`）为静默 no-op，按规格时机调用 `play_sfx`。

占位视觉：尖刺与指示牌尚无 §6.2 正式美术，使用 Polygon2D 多边形占位
（尖刺 `#b13e53` 双三角、指示牌棕色板 + 立柱），后续替换为精灵图。

## M6：流程与存档

**关卡数据迁出 autoload**：`Levels` 不再是 autoload，改为
`scripts/levels/levels.gd` 的 `class_name Levels`（RefCounted，纯数据），
所有 `Levels.X` 引用经全局类名解析；`project.godot` 中对应行已移除。

**GameState**（`scripts/game_state.gd`）：运行时状态集中于此（M5 中散落在
Player/Level 的 HP / 命数收敛到这里）：`lives` / `hp` / `current_level` /
`coins_this_level` / `coins_total_this_level` / `deaths_this_level` /
`level_time`，信号 `hp_changed` / `lives_changed` / `coins_changed`。
方法：`start_new_game` / `start_level`（进关：HP 回满、金币清零、总数取
`Levels.META`、计时与失误清零、命数保持）/ `apply_damage()`（返回是否致命）/
`on_death()`（返回 `"respawn"` 或 `"game_over"`）/ `on_level_complete()` /
`restart_level_from_pause()` / `retry_after_game_over()` / `collect_coin()`。
**D23**：暂停重开不扣命、不清空 `deaths_this_level`（面板要显示本关总失误）；
Game Over 重试则命数=3 且全部清零。玩家 `damage()` 同步调用
`Game.state.apply_damage()`（两边同为 3 并随重生/重开一起重置）。

**SaveData**（`scripts/save_data.gd`）：ConfigFile 存 `user://save.cfg`，
路径可注入（测试用临时路径）。`progress`：`unlocked_level`、`best_coins_1..3`
（-1 = 未通关，只升不降）；`settings`：`fullscreen`。`complete_level(level,
coins)` 解锁下一关（上限 3）并即时落盘；文件缺失时取默认值不报错。

**流程**（`autoload/game.gd`）：死亡 → `Level` 路由 `on_death()`：respawn 走
`Game.respawn()`（重进当前关，`Level._ready` 经 `Game.respawn_pending` 给新
玩家 1.0s 重生无敌帧 + 播放 `sfx_respawn`），game_over 走 `Game.go_game_over()`。
通关 → `Level._on_flag_completed`：`state.on_level_complete()` +
`save.complete_level()`，等 0.8s 后自动进下一关；第 3 关通关回标题。
暂停「重开本关」→ `Game.restart_level()`；Game Over「重试本关」→
`Game.retry_after_game_over()`（命数=3、重进当前关）。
`Level.level_index` 默认 0 为哨兵值，`_ready` 时从 `Game.state.current_level`
解析（测试/冒烟直接赋值绕过）。

**计时**（§9.7）：`Level._process` 在玩家存活且未通关时累加
`Game.state.level_time`；死亡 / 过关 / 重开 / 重试均清零。

**Game Over 界面**（`scenes/ui/game_over.tscn`）：M6 最小可工作版——
黑背景 + 标题 + 文本 + 两行菜单（重试本关 / 返回标题），↑↓ 选择、Enter 确认，
0.6s（`RESULT_INPUT_GRACE`）内忽略输入，进入时播放 `jingle_game_over`。
0.5s 淡入、面板装饰等 §10.7 完整样式 = M7（UiTheme 已在用）。

**测试**：`test/unit/test_game_state.gd`（状态机全路径 + 信号计数/取值）、
`test/unit/test_save_data.gd`（缺文件默认值、往返、解锁、best 历史最高、
临时路径清理）。冒烟（`smoke_run.gd`）新增：GameState 默认值与
respawn→game_over 序列、SaveData 临时路径往返、`game_over.tscn` 实例化。

**假设与占位**：通关结算面板（§10.6，含金币/用时/失误明细与菜单）= M7，
当前仅 0.8s 延时后自动进下一关；`Audio.play_bgm` 仍是 no-op（M8 接 BGM）；
重生无敌帧复用受击闪烁动画 1.0s。


## M7：界面

**主题与菜单**：全部 UI 运行时构建（无 .tscn 控件树），统一 `UiTheme.build()`
（Fusion Pixel 12px 中文字体，标题 24 号，阴影 `#1a1c2c` 偏移 (1,1)）。
`MenuList`（`scripts/ui/menu_list.gd`）：Label 条目 + 1px 水平抖动光标
（周期 0.4s）、双向环绕且跳过禁用项、选中 `#ffcd75` / 普通 `#f4f4f4` /
禁用 `#566c86`；确认宽限期 `Tuning.MENU_INPUT_GRACE = 0.15s`
（§10.1 固定值，替换 M6 占位 0.25s），结算菜单用 `RESULT_INPUT_GRACE = 0.6s`
（§10.7）。公开入口 `press_move(dir)` / `press_accept()`（绕过宽限，供冒烟与单测）。

**场景根节点类型**：`hud.tscn` = CanvasLayer(10) 根 + 全矩形 Control 子节点
（`hud.gd` 继承 Control，须挂 Control 上）；`level_select` / `pause_menu` /
`level_complete` 三个弹窗 = 裸 CanvasLayer(15) 根、脚本挂根（脚本继承
CanvasLayer，不能挂 Control；主题化 Control 子节点在 `_ready` 运行时构建）；
`title_screen.tscn` = Node2D 根（视差滚动层）；`game_over.tscn` = 全矩形
Control 根（子节点全部代码构建）。

**标题界面**（§10.1）：视差 ×2 份拼接的远景 + 地面草条（tileset 图集运行时
合成）、LOGO「像素跳跳」+ 副标题、4 项菜单（开始游戏 / 选择关卡 / 全屏：关 /
退出游戏）、KeyHint、版本 v0.1。选关界面（§10.2）：192×120 面板，3 行
「名称 + 关卡号 + 最佳金币」（未通关 `--/N`，§9.7），未解锁行灰显 + 锁图标、
不可选；进入关卡 = `Game.start_new_game(idx+1)`（D24 命数=3）。

**HUD**（§10.3）：心形血条（`ui_heart_full/empty` ×3，受击 0.08s×3 闪烁）、
命数（`ui_life` 图标 + `命 ×%d`）、金币（`ui_coin` 图标 + 0.1s 弹跳 +
`%02d/%02d`）、计时 `%02d:%02d`、关卡名横幅（1.5s 淡入淡出）、toast 预留
（`show_toast` 公开入口，M7 无调用方）。

**暂停 / 结算 / 选关联动**：Esc 或 P 开暂停（`pause_menu`，0.15s 宽限；
Esc 分支同时处理开与关防双触发；`set_enabled(false)` 只屏蔽输入不隐藏——
过关流程中禁用）。过关（§9.7/§10.6）：旗触发 → 关内暂停禁用 → 状态机 +
存档（best 历史最高，只升不降）→ 保留 0.8s `COMPLETE_PANEL_DELAY` 节拍 →
`level_complete` 结算面板（金币 countup 0.04s/tick、全收集行 `#a7f070`、
用时、失误、按钮横排 默认「下一关」；第 3 关变体：`总金币 N / 36` + 单按钮
「返回标题」，彩带 = M8）。M6 的自动进下一关已删除，改由面板驱动
（下一关 / 重玩 / 标题）。`setup()` 经由未类型化变量动态调用
（Godot 静态分析不允许在基类类型上调用脚本方法）。

**Game Over**（§10.7，M6 最小版 → 完整样式）：黑底 `#1a1c2c` 从黑幕 0.5s
淡入（根节点 modulate 补间）；「游戏结束」24 号 `#b13e53` y=52、「命数用尽了……」
12 号 `#94b0c2` y=84、菜单 y=112/126（重试本关 / 返回标题）、0.6s 后接受输入；
`stop_bgm()` + `play_sfx("jingle_game_over")`——§10.7「不播 BGM」：jingle 为
一次性音效，关卡 BGM 不得继续。

**路牌气泡**（§10.4）：`SignBubble` = PanelContainer 自适应尺寸 +
`call_deferred` 摆放三角尾（`ui_bubble_tail`，避开测量时机问题）；
`sign.gd` 每 2.5s 弹出 2s（错开 1s 初相位）。

**KeyHint**：`set_hint_color` API（默认 `#94b0c2`，Game Over 用 `#8b8ba4`）；
按键名用 `[ ]` 方括号字面文本（无键帽贴图排版依赖）。

**全屏**（D12）：F11 切换 + 持久化 `SaveData.fullscreen`（`settings/fullscreen`）
+ 启动时恢复；标题菜单项文本随状态切换「全屏：关/开」；冒烟模式跳过切换。

**测试**：`test/unit/test_hud_format.gd`（金币/计时格式，含取整与钳制）、
`test/unit/test_menu_list.gd`（环绕、跳过禁用、默认首个可点项、禁用项确认
`-1` 不发射、换文本重测、纵向居中/横向布局）。冒烟新增 `_check_ui_scenes()`：
6 个 UI 场景逐个实例化 → 断言「有主题 Control + Fusion Pixel 字体」→
对每个 MenuList 驱动一次「移动 + 确认」（各 dispatcher 冒烟下只打印
`TITLE/SELECT/PAUSE/COMPLETE/GAMEOVER ACTION: …`，不切场景）。

**假设与占位**：无新增 Strings 键（M7 文案全部复用 `scripts/ui/strings.gd`）；
彩带 / 尘土 / 烟 / 火花 / hitstop / 屏幕震动 / 真音频 = M8（`Audio` 仍 no-op）；
`show_toast` 为 §10.3 预留入口，M7 无调用方。
