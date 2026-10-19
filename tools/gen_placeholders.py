#!/usr/bin/env python3
"""Generate all placeholder art per spec §6.2 (Pixel Hop).

Pure Python 3 stdlib. Writes RGBA-8 PNGs (zlib + struct, no third-party).
Every pixel uses only the §6.1 16-color palette (+ full transparency).

Self-check at the end: re-reads every generated file, verifies width/height
from IHDR and that every non-transparent pixel is in the palette.
Exit 0 on success, 1 on any mismatch.
"""
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(ROOT, "..", "assets"))

# --- §6.1 palette -----------------------------------------------------------
OUT    = (0x1a, 0x1c, 0x2c)  # 00 outline / text shadow / masks / game over bg
DARK   = (0x4a, 0x2e, 0x35)  # 01 dirt shadow
DIRT   = (0x7a, 0x48, 0x41)  # 02 dirt / wood / flag pole / platforms
WALKER = (0x5d, 0x27, 0x5d)  # 03 walker body
DANGER = (0xb1, 0x3e, 0x53)  # 04 spiky / spikes / hearts / game over title
PLAYER = (0xef, 0x7d, 0x57)  # 05 player body / coin shadow
GOLD   = (0xff, 0xcd, 0x75)  # 06 coin / face / UI selected / logo / flag cloth
LEAF   = (0xa7, 0xf0, 0x70)  # 07 grass highlight / full collect
GRASS  = (0x38, 0xb7, 0x64)  # 08 grass top
PANEL  = (0x33, 0x3c, 0x57)  # 09 UI panel fill
MIDBLU = (0x56, 0x6c, 0x86)  # 10 mid-ground / disabled text
LTBLU  = (0x94, 0xb0, 0xc2)  # 11 far mountains / spike metal / secondary text
WHITE  = (0xf4, 0xf4, 0xf4)  # 12 body text / clouds / highlights
BLUE   = (0x3b, 0x5d, 0xc9)  # 13 player pants
SKY    = (0x41, 0xa6, 0xf6)  # 14 sky
CYAN   = (0x73, 0xef, 0xf7)  # 15 near-horizon sky / coin sparkle

PAL = {OUT, DARK, DIRT, WALKER, DANGER, PLAYER, GOLD, LEAF, GRASS, PANEL,
       MIDBLU, LTBLU, WHITE, BLUE, SKY, CYAN}


# --- PNG write ---------------------------------------------------------------
def _chunk(tag, data):
    body = tag + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def png_write(path, w, h, px):
    raw = bytearray()
    for row in px:
        raw.append(0)  # filter: none
        for p in row:
            raw += bytes(p)
    data = b"\x89PNG\r\n\x1a\n"
    data += _chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    data += _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += _chunk(b"IEND", b"")
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


# --- PNG read (for self-check) -----------------------------------------------
def png_read(path):
    d = open(path, "rb").read()
    assert d[:8] == b"\x89PNG\r\n\x1a\n", "bad signature " + path
    off = 8
    w = h = None
    idat = b""
    while off < len(d):
        ln = struct.unpack(">I", d[off:off + 4])[0]
        tag = d[off + 4:off + 8]
        body = d[off + 8:off + 8 + ln]
        if tag == b"IHDR":
            w, h, bd, ct = struct.unpack(">IIBB", body[:10])
            assert bd == 8 and ct == 6, "expected RGBA8: " + path
        elif tag == b"IDAT":
            idat += body
        off += 12 + ln
    raw = zlib.decompress(idat)
    bpp = 4
    stride = w * bpp
    rows = []
    pos = 0
    for y in range(h):
        f = raw[pos]
        pos += 1
        row = list(raw[pos:pos + stride])
        pos += stride
        if f == 1:
            for i in range(bpp, stride):
                row[i] = (row[i] + row[i - bpp]) & 255
        elif f == 2:
            for i in range(stride):
                row[i] = (row[i] + rows[y - 1][i]) & 255
        elif f == 3:
            for i in range(stride):
                a = row[i - bpp] if i >= bpp else 0
                row[i] = (row[i] + (a + rows[y - 1][i]) // 2) & 255
        elif f == 4:
            for i in range(stride):
                a = row[i - bpp] if i >= bpp else 0
                b = rows[y - 1][i]
                c = rows[y - 1][i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                row[i] = (row[i] + pr) & 255
        elif f != 0:
            raise ValueError("unsupported filter %d in %s" % (f, path))
        rows.append(row)
    out = []
    for y in range(h):
        out.append([tuple(rows[y][x * 4:x * 4 + 4]) for x in range(w)])
    return w, h, out


# --- pixel helper --------------------------------------------------------------
class Img:
    def __init__(self, w, h, fill=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.px = [[fill] * w for _ in range(h)]

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            if len(c) == 3:
                c = (c[0], c[1], c[2], 255)
            self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        if len(c) == 3:
            c = (c[0], c[1], c[2], 255)
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                self.px[y][x] = c


    def diamond(self, cx, cy, r, c):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if abs(x - cx) + abs(y - cy) <= r:
                    self.set(x, y, c)

    def save(self, rel):
        path = os.path.join(ASSETS, rel)
        png_write(path, self.w, self.h, self.px)
        return rel


def outline_shape(im, shape, ox, oy, c=OUT):
    """Set OUT outline around 1-px shape cells (ox,oy) origin."""
    cells = set(shape)
    for (x, y) in list(cells):
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if (x + dx, y + dy) not in cells:
                    im.set(ox + x + dx, oy + y + dy, c)


def blob_cells(x0, y0, w, h, round_corners=True):
    cells = set()
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if round_corners and (x in (x0, x0 + w - 1) and y in (y0, y0 + h - 1)):
                continue
            cells.add((x, y))
    return cells


def fill_outline(im, ox, oy, cells, fill, oc=OUT):
    outline_shape(im, cells, ox, oy, oc)
    for (x, y) in cells:
        im.set(ox + x, oy + y, fill)


# --- player sheet 96×112 (6 cols × 7 rows, 16px) --------------------------------
def _player_frame(im, cx, cy, top, bot, w, eye_y, outline_c=OUT, eyes="o",
                  face=True, arms=False, pants=True, bob_feet=0):
    ox, oy = cx * 16, cy * 16
    x0, x1 = ox + 3, ox + 3 + w - 1
    cells = blob_cells(x0, oy + top, w, bot - top + 1)
    fill_outline(im, 0, 0, cells, PLAYER, outline_c)
    # pants (bottom 4 rows)
    if pants:
        for (x, y) in cells:
            if y >= oy + bot - 3:
                im.set(x, y, BLUE)
    # face band
    if face:
        for y in range(oy + top + 1, oy + top + 7):
            for x in range(x0 + 1, x1):
                if (x, y) in cells:
                    im.set(x, y, GOLD)
    # eyes (1px black)
    ex0, ex1 = ox + 6, ox + 9
    if eyes == "o":
        im.set(ex0, oy + eye_y, OUT)
        im.set(ex1, oy + eye_y, OUT)
    elif eyes == "x":
        im.set(ex0 - 1, oy + eye_y - 1, OUT); im.set(ex0, oy + eye_y, OUT)
        im.set(ex0, oy + eye_y - 1, OUT); im.set(ex0 - 1, oy + eye_y, OUT)
        im.set(ex1 + 1, oy + eye_y - 1, OUT); im.set(ex1, oy + eye_y, OUT)
        im.set(ex1, oy + eye_y - 1, OUT); im.set(ex1 + 1, oy + eye_y, OUT)
    if arms:
        im.set(ox + 2, oy + top, PLAYER)
        im.set(ox + 2, oy + top + 1, PLAYER)
        im.set(ox + 13, oy + top, PLAYER)
        im.set(ox + 13, oy + top + 1, PLAYER)
    if bob_feet:
        im.set(ox + 4 if bob_feet > 0 else ox + 10, oy + bot, BLUE)


def gen_player_sheet():
    im = Img(96, 112)
    # r0 idle ×4 (frame 3: 1px squash)
    for f in range(3):
        _player_frame(im, f, 0, 2, 15, 10, 6)
    _player_frame(im, 3, 0, 3, 15, 10, 7)
    # r1 run ×6 (1px bob / feet alternate)
    for f in range(6):
        top = 2 if f % 2 == 0 else 3
        _player_frame(im, f, 1, top, 15, 10 if f % 2 == 0 else 11, 6 if f % 2 == 0 else 7, bob_feet=1 if f % 2 == 0 else -1)
    # r2 jump (col 0, arms up) + fall (col 1)
    _player_frame(im, 0, 2, 2, 15, 10, 5, arms=True)
    _player_frame(im, 1, 2, 3, 15, 10, 5)
    # r3 land ×2 (squash, recovery)
    _player_frame(im, 0, 3, 5, 15, 12, 9)
    _player_frame(im, 1, 3, 3, 15, 10, 7)
    # r4 hurt ×2 (white outline)
    _player_frame(im, 0, 4, 2, 15, 10, 6, outline_c=WHITE, eyes="x")
    _player_frame(im, 1, 4, 3, 15, 10, 7, outline_c=WHITE, eyes="x")
    # r5 death ×1
    _player_frame(im, 0, 5, 2, 15, 10, 6, eyes="x")
    # r6 victory ×2 (arms up, 2nd frame 1px hop)
    _player_frame(im, 0, 6, 2, 15, 10, 5, arms=True)
    _player_frame(im, 1, 6, 1, 14, 10, 4, arms=True)
    return im.save("sprites/player/player_sheet.png")


# --- walker sheet 64×32 --------------------------------------------------------
def _semicircle_cells(w=12, h=10):
    """Bottom-anchored semicircle in a 16×16 cell (x 2..13, bottom y15)."""
    cells = set()
    for y in range(16 - h, 16):
        if y == 16 - h:
            x0, x1 = 5, 10
        elif y == 16 - h + 1:
            x0, x1 = 3, 12
        else:
            x0, x1 = 2, 13
        for x in range(x0, x1 + 1):
            cells.add((x, y))
    return cells


def gen_walker_sheet():
    im = Img(64, 32)
    for f in range(4):
        ox, oy = f * 16, 0
        h = 10 if f % 2 == 0 else 9
        cells = _semicircle_cells(12, h)
        fill_outline(im, ox, oy, cells, WALKER)
        im.set(ox + 5, oy + 10, WHITE)
        im.set(ox + 6, oy + 10, WHITE)
        im.set(ox + 9, oy + 10, WHITE)
        im.set(ox + 10, oy + 10, WHITE)
    # squashed (1 frame) in bottom 8px
    ox, oy = 0, 16
    cells = set()
    for y in range(12, 16):
        for x in range(2, 14):
            cells.add((x, y))
    fill_outline(im, ox, oy, cells, WALKER)
    im.set(ox + 5, oy + 13, WHITE)
    im.set(ox + 9, oy + 13, WHITE)
    return im.save("sprites/enemies/walker_sheet.png")


# --- spiky sheet 64×16 -----------------------------------------------------------
def gen_spiky_sheet():
    im = Img(64, 16)
    for f in range(4):
        ox, oy = f * 16, 0
        dx = 1 if f % 2 else 0
        # body: red semicircle 12×11 (y5..15)
        body = set()
        for y in range(5, 16):
            x0, x1 = (5, 10) if y == 5 else ((3, 12) if y == 6 else (2, 13))
            for x in range(x0 + dx, x1 + 1 + dx):
                body.add((x, y))
        # spikes: 3 light-blue triangles on top, tips single px (pointed)
        spikes = set()
        for tx in (4 + dx, 8 + dx, 11 + dx):
            for k, row in enumerate((1, 3, 5)):
                for x in range(tx - row // 2, tx + row // 2 + 1):
                    spikes.add((x, 2 + k))
        fill_outline(im, ox, oy, body, DANGER)
        fill_outline(im, ox, oy, spikes, LTBLU)
        im.set(ox + 5 + dx, oy + 10, WHITE)
        im.set(ox + 9 + dx, oy + 10, WHITE)
    return im.save("sprites/enemies/spiky_sheet.png")


# --- tileset 128×64 (8×4 grid) ----------------------------------------------------
def _grass_top(im, ox, oy):
    for x in range(ox, ox + 16):
        im.set(x, oy, LEAF)
        for y in range(oy + 1, oy + 4):
            im.set(x, y, GRASS)
        for y in range(oy + 4, oy + 16):
            im.set(x, y, DIRT)
    for (sx, sy) in ((3, 7), (9, 10), (12, 6)):
        im.set(ox + sx, oy + sy, DARK)


def _dirt_body(im, ox, oy, speckles):
    for y in range(oy + 1, oy + 16):
        for x in range(ox, ox + 16):
            im.set(x, y, DIRT)
    for (sx, sy) in speckles:
        im.set(ox + sx, oy + sy, DARK)
    for x in range(ox, ox + 16):
        im.set(x, oy + 15, OUT)


def gen_tileset():
    im = Img(128, 64)
    # row 0: ground caps (0-3) + one-way platforms (4-7)
    _grass_top(im, 0, 0)
    for x in range(0, 16):
        im.set(x, 0, LEAF)
    _grass_top(im, 16, 0)
    for x in range(32, 48):
        for y in range(0, 16):
            im.set(x + 15, y, OUT)
    _grass_top(im, 48, 0)
    for x in range(48, 64):
        for y in range(0, 16):
            im.set(x, y, OUT)
    for x in range(0, 16):
        for y in range(0, 16):
            im.set(x, y, OUT) if False else None
    for y in range(0, 16):
        im.set(0, y, OUT)
        im.set(15, y, OUT)
    # one-way planks (4..7,0): 16×4 strip, top of cell
    for i, (ox, cap_l, cap_r) in enumerate(((64, True, False), (80, False, False), (96, False, True), (112, True, True))):
        for y in range(0, 4):
            for x in range(ox, ox + 16):
                im.set(x, y, DIRT)
        im.set(ox + 4, 1, DARK)
        im.set(ox + 10, 2, DARK)
        for x in range(ox, ox + 16):
            im.set(x, 3, OUT)
        if cap_l:
            for y in range(0, 4):
                im.set(ox, y, OUT)
        if cap_r:
            for y in range(0, 4):
                im.set(ox + 15, y, OUT)
    # row 1: solid (up solid)
    _dirt_body(im, 0, 16, ((5, 5), (11, 9)))
    for y in range(17, 32):
        im.set(0, y, OUT)
        im.set(15, y, OUT)
    _dirt_body(im, 16, 16, ((3, 4), (8, 8), (13, 6)))
    _dirt_body(im, 32, 16, ((5, 5), (11, 9)))
    for y in range(17, 32):
        im.set(47, y, OUT)
    _dirt_body(im, 48, 16, ((5, 5), (11, 9)))
    for y in range(17, 32):
        im.set(48, y, OUT)
    # row 2: decor (0..3)
    for x in range(4, 12):
        im.set(x + 0, 14, GRASS); im.set(x + 0, 15, GRASS)
    for x in (5, 8, 10):
        im.set(x, 13, LEAF)
    for x in range(6, 10):
        for y in range(12, 16):
            im.set(x + 16, y, GRASS)
    for x in (7, 9):
        im.set(x + 16, 11, LEAF)
    im.set(8 + 32, 14, LEAF); im.set(8 + 32, 13, LEAF); im.set(8 + 32, 12, LEAF)
    im.set(7 + 32, 11, GOLD); im.set(8 + 32, 11, GOLD); im.set(9 + 32, 11, GOLD)
    im.set(7 + 32, 10, GOLD); im.set(8 + 32, 10, GOLD); im.set(9 + 32, 10, GOLD)
    for x in range(5, 11):
        for y in range(13, 16):
            im.set(x + 48, y, MIDBLU)
    im.set(6 + 48, 13, WHITE)
    im.set(7 + 48, 13, WHITE)
    # row 3: (0,3) alt dirt variant
    _dirt_body(im, 0, 48, ((2, 3), (7, 6), (12, 4), (9, 11)))
    return im.save("tiles/tileset.png")


# --- coin sheet 48×8 -------------------------------------------------------------
def gen_coin_sheet():
    im = Img(48, 8)
    widths = [8, 6, 4, 2, 4, 6]
    for f, w in enumerate(widths):
        ox = f * 8
        x0, x1 = 4 - w // 2, 3 + w // 2
        cells = set()
        for y in range(0, 8):
            if y in (0, 7) and w >= 4:
                a, b = x0 + 1, x1 - 1
            else:
                a, b = x0, x1
            for x in range(a, b + 1):
                cells.add((x, y))
        fill_outline(im, ox, 0, cells, GOLD)
        if w >= 4:
            im.set(ox + x0 + 1, 1, WHITE)
    return im.save("sprites/items/coin_sheet.png")


# --- flag pole 16×48 ----------------------------------------------------------------
def gen_flag_pole():
    im = Img(16, 48)
    # pole 2px wide, full height
    for y in range(4, 48):
        im.set(6, y, OUT)
        im.set(7, y, DIRT)
        im.set(8, y, DIRT)
        im.set(9, y, OUT)
    # top 4×4 gold ball
    for y in range(0, 4):
        im.set(5, y, OUT)
        im.set(10, y, OUT)
        for x in range(6, 10):
            im.set(x, y, GOLD)
    for x in range(6, 10):
        im.set(x, 4, OUT)
    # base 10×4
    for x in range(2, 14):
        im.set(x, 43, OUT)
    for y in range(44, 48):
        im.set(2, y, OUT)
        im.set(13, y, OUT)
        for x in range(3, 13):
            im.set(x, y, DIRT)
    for x in range(3, 13):
        im.set(x, 47, OUT)
    return im.save("sprites/items/flag_pole.png")


# --- flag cloth sheet 48×10 --------------------------------------------------------
def gen_flag_cloth():
    im = Img(48, 10)
    indents = [0, 1, 2, 1]
    for f, ind in enumerate(indents):
        ox = f * 12
        w = 12 - ind
        for x in range(0, w):
            im.set(ox + x, 0, OUT)
            im.set(ox + x, 9, OUT)
        for y in range(0, 10):
            im.set(ox, y, OUT)
            im.set(ox + w - 1, y, OUT)
        im.rect(ox + 1, 1, ox + w - 2, 8, GOLD)
    return im.save("sprites/items/flag_cloth_sheet.png")


# --- FX ---------------------------------------------------------------------------
def gen_dust():
    im = Img(3, 3)
    for y in range(3):
        for x in range(3):
            if (x, y) in ((0, 0), (2, 0), (0, 2), (2, 2)):
                continue
            im.set(x, y, LTBLU)
    return im.save("sprites/fx/dust_px.png")


def gen_jump_puff():
    im = Img(64, 8)
    dots = [(4, 6, 4, 7), (3, 5, 5, 6, 7, 7), (2, 4, 4, 5, 6, 7, 8, 6), (1, 3, 3, 4, 5, 6, 7, 8, 9, 5, 11, 4)]
    for f, pts in enumerate(dots):
        ox = f * 16
        it = iter(pts)
        for x, y in zip(it, it):
            im.set(ox + x, y, LTBLU)
    return im.save("sprites/fx/fx_jump_puff.png")


def gen_land_puff():
    im = Img(96, 8)
    widths = [6, 10, 14, 18]
    for f, w in enumerate(widths):
        ox = f * 24
        x0, x1 = 12 - w // 2, 11 + w // 2
        for x in range(x0, x1 + 1):
            im.set(ox + x, 7, LTBLU)
        for x in range(x0 + 1, x1):
            im.set(ox + x, 6, LTBLU)
    return im.save("sprites/fx/fx_land_puff.png")


def gen_poof():
    im = Img(80, 16)
    radii = [1, 2, 3, 4, 5]
    for f, r in enumerate(radii):
        ox = f * 16
        im.diamond(ox + 8, 8, r, WHITE)
    return im.save("sprites/fx/fx_poof.png")


def gen_coin_sparkle():
    im = Img(48, 12)
    arms = [2, 4, 5, 2]
    for f, a in enumerate(arms):
        ox, oy = f * 12, 6
        for d in ((a, 0), (-a, 0), (0, a), (0, -a)):
            im.set(ox + 6 + d[0], oy + d[1], CYAN)
        for d in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            im.set(ox + 6 + d[0], oy + d[1], GOLD)
        im.set(ox + 6, oy, GOLD)
    return im.save("sprites/fx/fx_coin_sparkle.png")


def gen_hit_spark():
    im = Img(36, 12)
    arms = [4, 2, 1]
    for f, a in enumerate(arms):
        ox, oy = f * 12, 6
        for d in ((a, 0), (-a, 0), (0, a), (0, -a), (a, a), (-a, a), (a, -a), (-a, -a)):
            im.set(ox + 6 + d[0], oy + d[1], DANGER)
        im.set(ox + 6, oy, WHITE)
    return im.save("sprites/fx/fx_hit_spark.png")


def gen_confetti():
    im = Img(2, 2)
    im.set(0, 0, DANGER)
    im.set(1, 0, GOLD)
    im.set(0, 1, LEAF)
    im.set(1, 1, BLUE)
    return im.save("sprites/fx/confetti_px.png")


# --- UI -----------------------------------------------------------------------------
HEART = [
    ".XX..XX.",
    ".XXXXXX.",
    "XXXXXXXX",
    "XXXXXXXX",
    ".XXXXXX.",
    "..XXXX..",
    "...XX...",
    "....X...",
]


def _heart(im, fill, highlight):
    for y, row in enumerate(HEART):
        cells = set()
        for x, ch in enumerate(row):
            if ch == "X":
                cells.add((x, y))
        fill_outline(im, 0, 0, cells, fill)
    if highlight:
        im.set(2, 1, WHITE)
        im.set(3, 1, WHITE)
        im.set(1, 2, WHITE)


def gen_heart_full():
    im = Img(8, 8)
    _heart(im, DANGER, True)
    return im.save("sprites/ui/ui_heart_full.png")


def gen_heart_empty():
    im = Img(8, 8)
    _heart(im, PANEL, False)
    return im.save("sprites/ui/ui_heart_empty.png")


def gen_ui_coin():
    im = Img(8, 8)
    src, _, px = png_read(os.path.join(ASSETS, "sprites/items/coin_sheet.png"))
    for y in range(8):
        for x in range(8):
            im.set(x, y, px[y][x])
    return im.save("sprites/ui/ui_coin.png")


def gen_ui_life():
    im = Img(8, 8)
    cells = blob_cells(1, 0, 6, 6)
    fill_outline(im, 0, 0, cells, PLAYER)
    for y in range(1, 4):
        for x in range(2, 6):
            im.set(x, y, GOLD)
    im.set(3, 2, OUT)
    im.set(5, 2, OUT)
    return im.save("sprites/ui/ui_life.png")


def gen_ui_lock():
    im = Img(7, 8)
    for x in range(2, 5):
        im.set(x, 0, MIDBLU)
    for y in (1, 2):
        im.set(1, y, MIDBLU)
        im.set(5, y, MIDBLU)
    for y in range(3, 8):
        for x in range(1, 6):
            im.set(x, y, MIDBLU)
    im.set(3, 4, (0, 0, 0, 0))
    im.set(3, 5, (0, 0, 0, 0))
    return im.save("sprites/ui/ui_lock.png")


def gen_ui_cursor():
    im = Img(6, 7)
    cols = [7, 7, 5, 5, 3, 1]
    for x, n in enumerate(cols):
        y0 = 3 - n // 2
        for y in range(y0, y0 + n):
            im.set(x, y, GOLD)
    return im.save("sprites/ui/ui_cursor.png")


def gen_ui_panel():
    im = Img(24, 24)
    im.rect(0, 0, 23, 23, OUT)
    im.rect(1, 1, 22, 22, LTBLU)
    im.rect(2, 2, 21, 21, PANEL)
    return im.save("sprites/ui/ui_panel.png")


def gen_ui_panel_small():
    im = Img(12, 12)
    im.rect(0, 0, 11, 11, OUT)
    im.rect(1, 1, 10, 10, WHITE)
    return im.save("sprites/ui/ui_panel_small.png")


def gen_ui_bubble_tail():
    im = Img(5, 3)
    im.rect(0, 0, 4, 0, WHITE)
    im.set(0, 1, OUT); im.set(4, 1, OUT)
    im.set(1, 1, WHITE); im.set(2, 1, WHITE); im.set(3, 1, WHITE)
    im.set(1, 2, OUT); im.set(3, 2, OUT)
    im.set(2, 2, WHITE)
    return im.save("sprites/ui/ui_bubble_tail.png")


def gen_ui_keycap():
    im = Img(10, 12)
    im.rect(0, 0, 9, 11, OUT)
    im.rect(1, 1, 8, 9, WHITE)
    im.rect(1, 10, 8, 10, LTBLU)
    return im.save("sprites/ui/ui_keycap.png")


# --- backgrounds (edge-seamless: pattern period divides 320) ------------------------
def gen_bg_sky():
    im = Img(320, 180)
    for y in range(0, 139):
        for x in range(320):
            im.set(x, y, SKY)
    for x in range(320):
        im.set(x, 139, CYAN if x % 2 else SKY)
        im.set(x, 140, SKY if x % 2 else CYAN)
    for y in range(141, 180):
        for x in range(320):
            im.set(x, y, CYAN)
    return im.save("bg/bg_sky.png")


def _mountain_h(x):
    xp = x % 80  # period 80 → 4 periods across 320
    ha = 40 + abs(xp - 20) * 3 // 2
    hb = 55 + abs(xp - 60) * 12 // 10
    return min(ha, hb, 95)


def gen_bg_far_mountains():
    im = Img(320, 96)
    for x in range(320):
        h = _mountain_h(x)
        for y in range(h, 96):
            if y < h + 3:
                im.set(x, y, WHITE)      # snow cap
            elif (x % 80) > 20 and (x % 80) < 28 and y < h + 9:
                im.set(x, y, MIDBLU)     # shade right of peak A
            else:
                im.set(x, y, LTBLU)
    return im.save("bg/bg_far_mountains.png")


def _cloud(im, cx, cy):
    im.rect(cx, cy, cx + 14, cy + 3, WHITE)
    im.rect(cx + 2, cy - 2, cx + 11, cy - 1, WHITE)
    for (x, y) in ((cx, cy), (cx + 14, cy), (cx, cy + 3), (cx + 14, cy + 3)):
        im.set(x, y, (0, 0, 0, 0))
    im.rect(cx + 1, cy + 3, cx + 13, cy + 3, CYAN)  # bottom shadow


def gen_bg_clouds():
    im = Img(320, 48)
    spots = [(30, 14), (90, 26), (190, 12), (250, 28)]
    for (cx, cy) in spots:
        _cloud(im, cx, cy)
        _cloud(im, cx + 160, cy)
    return im.save("bg/bg_clouds.png")


def _hill_h(x):
    xp = x % 160
    ha = 16 + abs(xp - 40) * 48 // 40
    hb = 28 + abs(xp - 120) * 36 // 40
    return min(ha, hb, 63)


def gen_bg_mid_hills():
    im = Img(320, 64)
    for x in range(320):
        h = _hill_h(x)
        for y in range(h, 64):
            im.set(x, y, MIDBLU)
    for tx in (10, 70, 90, 150):
        h = _hill_h(tx)
        base = min(h, 63)
        im.set(tx, base - 1, PANEL)
        im.set(tx, base - 2, PANEL)
        im.rect(tx - 1, base - 5, tx + 1, base - 3, PANEL)
    return im.save("bg/bg_mid_hills.png")


# --- driver -----------------------------------------------------------------------
GENERATORS = [
    (gen_player_sheet, (96, 112)),
    (gen_walker_sheet, (64, 32)),
    (gen_spiky_sheet, (64, 16)),
    (gen_tileset, (128, 64)),
    (gen_coin_sheet, (48, 8)),
    (gen_flag_pole, (16, 48)),
    (gen_flag_cloth, (48, 10)),
    (gen_dust, (3, 3)),
    (gen_jump_puff, (64, 8)),
    (gen_land_puff, (96, 8)),
    (gen_poof, (80, 16)),
    (gen_coin_sparkle, (48, 12)),
    (gen_hit_spark, (36, 12)),
    (gen_confetti, (2, 2)),
    (gen_heart_full, (8, 8)),
    (gen_heart_empty, (8, 8)),
    (gen_ui_coin, (8, 8)),
    (gen_ui_life, (8, 8)),
    (gen_ui_lock, (7, 8)),
    (gen_ui_cursor, (6, 7)),
    (gen_ui_panel, (24, 24)),
    (gen_ui_panel_small, (12, 12)),
    (gen_ui_bubble_tail, (5, 3)),
    (gen_ui_keycap, (10, 12)),
    (gen_bg_sky, (320, 180)),
    (gen_bg_far_mountains, (320, 96)),
    (gen_bg_clouds, (320, 48)),
    (gen_bg_mid_hills, (320, 64)),
]


def main():
    generated = []
    for gen, size in GENERATORS:
        rel = gen()
        generated.append((rel, size))
    # self-check: re-read every file, verify size + palette
    failures = 0
    for rel, (w, h) in generated:
        path = os.path.join(ASSETS, rel)
        try:
            gw, gh, px = png_read(path)
        except Exception as e:
            print("FAIL %s: unreadable: %s" % (rel, e))
            failures += 1
            continue
        if (gw, gh) != (w, h):
            print("FAIL %s: size %dx%d != expected %dx%d" % (rel, gw, gh, w, h))
            failures += 1
            continue
        for y, row in enumerate(px):
            for x, (r, g, b, a) in enumerate(row):
                if a > 0 and (r, g, b) not in PAL:
                    print("FAIL %s: pixel (%d,%d) rgb(%d,%d,%d) not in palette" % (rel, x, y, r, g, b))
                    failures += 1
                    break
            if failures:
                break
        if not failures:
            print("OK %s %dx%d" % (rel, gw, gh))
    if failures:
        print("gen_placeholders: %d failure(s)" % failures)
        sys.exit(1)
    print("gen_placeholders: all %d files OK" % len(generated))


if __name__ == "__main__":
    main()
