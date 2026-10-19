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
