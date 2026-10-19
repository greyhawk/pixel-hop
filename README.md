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
