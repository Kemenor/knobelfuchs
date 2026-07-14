#!/usr/bin/env python3
"""Generate the Play Store hi-res icon (512x512) and feature graphic (1024x500)
from the app's icon art. Output goes into the en-US listing images dir.

    python3 tool/make_store_graphics.py

Font: tries fc-match (Linux) then the Windows font dir — the feature graphic
is generated art, not UI, so any bold sans is fine.
"""
import os
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

OUT = 'fastlane/metadata/android/en-US/images'
os.makedirs(OUT, exist_ok=True)


def find_font():
    if shutil.which('fc-match'):
        p = subprocess.run(['fc-match', '-f', '%{file}', 'Noto Sans:weight=bold'],
                           capture_output=True, text=True).stdout.strip()
        if p:
            return p
    for cand in (r'C:\Windows\Fonts\segoeuib.ttf', r'C:\Windows\Fonts\arialbd.ttf',
                 '/usr/share/fonts/google-noto/NotoSans-Bold.ttf'):
        if os.path.isfile(cand):
            return cand
    raise SystemExit('no usable bold font found')


FONT = find_font()

# 1) hi-res icon — downscale the real app icon; 32-bit PNG as Play requires.
Image.open('assets/icon/icon_full_emerald.png').convert('RGBA').resize(
    (512, 512), Image.LANCZOS).save(f'{OUT}/icon.png')

# 2) feature graphic — the fox on the triad-emerald gradient with the app name.
W, H = 1024, 500
top, bot = (49, 186, 112), (16, 106, 58)  # emerald #1FA85D, lightened / darkened
bg = Image.new('RGB', (W, H))
px = bg.load()
for y in range(H):
    t = y / (H - 1)
    row = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
    for x in range(W):
        px[x, y] = row
banner = bg.convert('RGBA')

fh = 400
fox = Image.open('assets/icon/icon_foreground.png').convert('RGBA').resize(
    (fh, fh), Image.LANCZOS)
fox_x, fox_y = 30, (H - fh) // 2
banner.alpha_composite(fox, (fox_x, fox_y))

draw = ImageDraw.Draw(banner)
text_x = fox_x + fh + 10
text_w = W - text_x - 50


def fit(text, max_size):
    for s in range(max_size, 8, -2):
        f = ImageFont.truetype(FONT, s)
        if draw.textlength(text, font=f) <= text_w:
            return f
    return ImageFont.truetype(FONT, 10)


def th(f):
    a = f.getbbox('Hg')
    return a[3] - a[1]


title_f = fit('Knobelfuchs', 96)
sub_f = fit('Number puzzles, in peace', 46)
tag_f = fit('no ads · no timer · offline', 30)
gap1, gap2 = 22, 16
block = th(title_f) + gap1 + th(sub_f) + gap2 + th(tag_f)
y = (H - block) // 2 - 10


def line(text, f, fill, y):
    draw.text((text_x + 2, y + 2), text, font=f, fill=(10, 60, 35, 160))
    draw.text((text_x, y), text, font=f, fill=fill)
    return y + th(f)


y = line('Knobelfuchs', title_f, (255, 255, 255, 255), y) + gap1
y = line('Number puzzles, in peace', sub_f, (226, 248, 235, 255), y) + gap2
line('no ads · no timer · offline', tag_f, (198, 236, 214, 255), y)

banner.convert('RGB').save(f'{OUT}/featureGraphic.png')
print('wrote icon.png (512x512) and featureGraphic.png (1024x500)')
