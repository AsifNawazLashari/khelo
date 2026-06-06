#!/usr/bin/env python3
import os, sys
try:
    from PIL import Image, ImageDraw
except ImportError:
    os.system("pip install Pillow --break-system-packages -q")
    from PIL import Image, ImageDraw

ICON_SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.png")
MIPMAP_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "android","app","src","main","res")
SIZES = {"mipmap-mdpi":48,"mipmap-hdpi":72,"mipmap-xhdpi":96,"mipmap-xxhdpi":144,"mipmap-xxxhdpi":192}

def remove_white_bg(img, threshold=235):
    img = img.convert("RGBA")
    data = [(r,g,b,0) if r>threshold and g>threshold and b>threshold else (r,g,b,a) for r,g,b,a in img.getdata()]
    img.putdata(data)
    return img

def make_square_padded(img, pad_pct=0.08):
    w,h = img.size
    side = max(w,h)
    c = Image.new("RGBA",(side,side),(255,255,255,0))
    c.paste(img,((side-w)//2,(side-h)//2),img)
    pad = int(side*pad_pct)
    inner = side - pad*2
    r = c.resize((inner,inner),Image.LANCZOS)
    out = Image.new("RGBA",(side,side),(255,255,255,0))
    out.paste(r,(pad,pad),r)
    return out

def rounded(img, r_pct=0.2):
    s = img.size[0]
    mask = Image.new("L",(s,s),0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,s-1,s-1],radius=int(s*r_pct),fill=255)
    bg = Image.new("RGBA",(s,s),(255,255,255,255))
    bg.paste(img,(0,0),img)
    bg.putalpha(mask)
    return bg

src = Image.open(ICON_SRC).convert("RGBA")
print(f"Source: {src.size}")
src = remove_white_bg(src)
src = make_square_padded(src)
base = src.resize((1024,1024),Image.LANCZOS)

for folder,size in SIZES.items():
    d = os.path.join(MIPMAP_BASE,folder)
    os.makedirs(d,exist_ok=True)
    icon = rounded(base.resize((size,size),Image.LANCZOS))
    out = os.path.join(d,"ic_launcher.png")
    icon.save(out,"PNG")
    print(f"  ✓ {folder:22s} {size}x{size} → {out}")

print("\nDone! Run: flutter clean && flutter build apk")
