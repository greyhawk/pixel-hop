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
