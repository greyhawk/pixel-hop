#!/usr/bin/env bash
# 下载 Fusion Pixel Font 12px proportional（zh_hans）+ 许可证；失败时只警告，退出码始终为 0。
set -u
VER=2026.10.16
ZIP=fusion-pixel-font-12px-proportional-ttf-v${VER}.zip
URL=https://github.com/TakWolf/fusion-pixel-font/releases/download/${VER}/${ZIP}
ZIP_SHA256=6dd1c8415c829a94aff70e0d24c9a154037bd9bc42cfea77448eac0a2a81c00f
TTF_SHA256=60f62ae34b95eea47e5986dd425bcd51c4f785165bf06befade60a059f036066
DEST=assets/fonts
TTF=fusion-pixel-12px-proportional-zh_hans.ttf
mkdir -p "$DEST"
if [ -f "$DEST/$TTF" ] && echo "$TTF_SHA256  $DEST/$TTF" | sha256sum -c --quiet - 2>/dev/null; then
  echo "font already present: $DEST/$TTF"; exit 0
fi
tmp="$(mktemp -d)"
if curl -fsSL --retry 3 -o "$tmp/$ZIP" "$URL" \
   && echo "$ZIP_SHA256  $tmp/$ZIP" | sha256sum -c --quiet - \
   && unzip -o -q "$tmp/$ZIP" "$TTF" OFL.txt 'LICENSES/*' -d "$tmp/x" \
   && echo "$TTF_SHA256  $tmp/x/$TTF" | sha256sum -c --quiet -; then
  cp "$tmp/x/$TTF" "$tmp/x/OFL.txt" "$DEST/"
  rm -rf "$DEST/LICENSES" && cp -r "$tmp/x/LICENSES" "$DEST/LICENSES"
  echo "font OK: $DEST/$TTF"
else
  echo "WARNING: Fusion Pixel font download/verify failed; UI falls back to the default font"
fi
rm -rf "$tmp"
exit 0
