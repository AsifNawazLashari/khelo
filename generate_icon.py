#!/usr/bin/env python3
"""
Run this once inside your Codespace before building:
    python3 generate_icons.py

It generates all Android launcher icon PNGs directly from code
(same globe logo as in the app) — no external PNG needed.
"""

import math, os, struct, zlib

# ─── Tiny pure-Python PNG writer (no Pillow needed) ──────────────────────────
def _write_png(path, pixels, w, h):
    def chunk(tag, data):
        c = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', c)
    raw = b''.join(b'\x00' + bytes(row) for row in pixels)
    compressed = zlib.compress(raw, 9)
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    idat = chunk(b'IDAT', compressed)
    iend = chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(sig + ihdr + idat + iend)

# ─── Draw the globe logo into a pixel buffer ─────────────────────────────────
def draw_icon(size):
    # RGB pixel grid  (3 bytes per pixel, no alpha — white background)
    W = H = size
    pixels = [[[255, 255, 255] for _ in range(W)] for _ in range(H)]

    def set_px(x, y, r, g, b, alpha=1.0):
        if 0 <= x < W and 0 <= y < H:
            pr, pg, pb = pixels[y][x]
            pixels[y][x] = [
                int(pr + (r - pr) * alpha),
                int(pg + (g - pg) * alpha),
                int(pb + (b - pb) * alpha),
            ]

    def draw_circle(cx, cy, radius, color_fn, aa=True):
        r2 = radius * radius
        for y in range(max(0, int(cy - radius) - 2), min(H, int(cy + radius) + 2)):
            for x in range(max(0, int(cx - radius) - 2), min(W, int(cx + radius) + 2)):
                dist = math.sqrt((x - cx)**2 + (y - cy)**2)
                if dist < radius:
                    t = dist / radius
                    alpha = min(1.0, max(0.0, (radius - dist)))  # AA edge
                    alpha = min(alpha, 1.0)
                    r, g, b = color_fn(t, x - cx, y - cy)
                    set_px(x, y, r, g, b, alpha)

    def lerp(a, b, t): return a + (b - a) * t

    cx = W * 0.48
    cy = H * 0.52
    R  = W * 0.36

    # ── Rounded square white background ──────────────────────────────────────
    corner = W * 0.22
    for y in range(H):
        for x in range(W):
            dx = min(x, W-1-x)
            dy = min(y, H-1-y)
            if dx < corner and dy < corner:
                dist = math.sqrt((corner-dx)**2 + (corner-dy)**2)
                if dist > corner:
                    pixels[y][x] = [0, 0, 0]  # transparent corners → white bg fine

    # ── Globe body (radial gradient: sky-blue center → cobalt edge) ──────────
    for y in range(H):
        for x in range(W):
            dist = math.sqrt((x - cx)**2 + (y - cy)**2)
            if dist <= R:
                # Slight highlight offset (top-left brighter)
                t = dist / R
                highlight = max(0, 1 - math.sqrt((x-cx*0.7)**2+(y-cy*0.7)**2)/(R*1.2))
                r = int(lerp(56,  29,  t) + highlight * 40)
                g = int(lerp(189, 101, t) + highlight * 30)
                b = int(lerp(248, 192, t) + highlight * 10)
                set_px(x, y, r, g, b)

    # ── Green orbit ellipse (tilted ~-30°) ────────────────────────────────────
    angle_rot = -0.52
    for theta in range(0, 628, 1):  # 0..2pi in 0.01 steps
        a = theta / 100.0
        # Ellipse in local space
        ex = R * 1.18 * math.cos(a)
        ey = R * 1.18 * 0.38 * math.sin(a)
        # Rotate
        rx = ex * math.cos(angle_rot) - ey * math.sin(angle_rot)
        ry = ex * math.sin(angle_rot) + ey * math.cos(angle_rot)
        px_x = cx + rx
        px_y = cy + ry
        thick = max(2, int(W * 0.042))
        for dx in range(-thick, thick+1):
            for dy in range(-thick, thick+1):
                if dx*dx + dy*dy <= thick*thick:
                    set_px(int(px_x+dx), int(px_y+dy), 52, 211, 153)

    # ── Blue orbit ellipse (nearly vertical) ──────────────────────────────────
    for theta in range(0, 628, 1):
        a = theta / 100.0
        ex = R * 1.12 * 0.42 * math.cos(a)
        ey = R * 1.12 * math.sin(a)
        rx = ex * math.cos(0.9) - ey * math.sin(0.9)
        ry = ex * math.sin(0.9) + ey * math.cos(0.9)
        px_x = cx + rx
        px_y = cy + ry
        thick = max(2, int(W * 0.033))
        for dx in range(-thick, thick+1):
            for dy in range(-thick, thick+1):
                if dx*dx + dy*dy <= thick*thick:
                    set_px(int(px_x+dx), int(px_y+dy), 21, 101, 192)

    # ── Letter "A" (rasterised manually as strokes) ───────────────────────────
    fs   = W * 0.20          # font size
    alx  = cx - fs * 0.28   # left of A
    aly  = cy - fs * 0.46   # top of A
    thick = max(1, int(W * 0.032))

    def draw_line_seg(x0, y0, x1, y1, r, g, b, t=None):
        t = t or thick
        steps = int(math.sqrt((x1-x0)**2+(y1-y0)**2)) * 3
        if steps == 0: return
        for i in range(steps+1):
            fx = x0 + (x1-x0)*i/steps
            fy = y0 + (y1-y0)*i/steps
            for dx in range(-t, t+1):
                for dy in range(-t, t+1):
                    if dx*dx+dy*dy <= t*t:
                        set_px(int(fx+dx), int(fy+dy), r, g, b)

    # Left stroke of A
    draw_line_seg(alx,          aly + fs,     cx,           aly,        255,255,255)
    # Right stroke of A
    draw_line_seg(cx,           aly,          alx + fs*0.56, aly + fs,  255,255,255)
    # Crossbar
    draw_line_seg(alx + fs*0.18, aly + fs*0.55, alx + fs*0.38, aly + fs*0.55, 255,255,255)

    # ── Arrow line (top-right) ────────────────────────────────────────────────
    ax1, ay1 = W*0.58, H*0.40
    ax2, ay2 = W*0.85, H*0.16
    at = max(2, int(W*0.038))
    draw_line_seg(ax1, ay1, ax2, ay2, 52, 211, 153, at)

    # Arrow head triangle
    head_size = W * 0.07
    # Two sides of arrowhead
    draw_line_seg(ax2, ay2, ax2 - head_size, ay2,            52, 211, 153, at-1)
    draw_line_seg(ax2, ay2, ax2,             ay2 + head_size, 52, 211, 153, at-1)

    return pixels

# ─── Generate all mipmap sizes ────────────────────────────────────────────────
SIZES = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
}

RES_DIR = 'android/app/src/main/res'

print("Generating launcher icons...\n")
for folder, px in SIZES.items():
    out_dir = os.path.join(RES_DIR, folder)
    os.makedirs(out_dir, exist_ok=True)
    pixels = draw_icon(px)
    for name in ('ic_launcher.png', 'ic_launcher_round.png'):
        path = os.path.join(out_dir, name)
        _write_png(path, pixels, px, px)
        print(f"  ✓ {path}")

print(f"\nDone! All icons written to {RES_DIR}")
print("Now run:  flutter clean && flutter build apk --release")
