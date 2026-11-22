"""Génère les icônes Android (adaptative + ancienne forme) et l'icône Play Store."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
import os, shutil

S = 1024
FONT = '/usr/share/fonts/opentype/inter/InterDisplay-BlackItalic.otf'


def background():
    im = Image.new('RGBA', (S, S), (5, 10, 26, 255))
    for (cx, cy, r, c, a) in [(170, 210, 800, (31, 150, 205), 0.95), (880, 910, 800, (215, 32, 66), 0.85), (560, 520, 520, (12, 28, 60), 0.5)]:
        gl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        g = Image.radial_gradient('L').resize((r * 2, r * 2))
        g = ImageChops.invert(g).point(lambda v, a=a: int(v * a))
        col = Image.new('RGBA', (r * 2, r * 2), c + (255,))
        col.putalpha(g)
        gl.paste(col, (cx - r, cy - r), col)
        im = Image.alpha_composite(im, gl)
    return im


def vgrad(size, top, bottom):
    w, h = size
    g = Image.new('RGBA', size)
    d = ImageDraw.Draw(g)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return g


def foreground():
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    font = ImageFont.truetype(FONT, 560)
    bw = font.getbbox('B'); fw = font.getbbox('F')
    gap = -30
    total = (bw[2] - bw[0]) + (fw[2] - fw[0]) + gap
    x0 = (S - total) / 2 - bw[0]
    y = S * 0.50 - (bw[3] + bw[1]) / 2 + 10

    def letter(ch, x, top, bottom, glow=None):
        mask = Image.new('L', (S, S), 0)
        ImageDraw.Draw(mask).text((x, y), ch, font=font, fill=255)
        layers = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        if glow:
            gm = mask.filter(ImageFilter.GaussianBlur(26)).point(lambda v: min(255, int(v * 1.4)))
            gl = Image.new('RGBA', (S, S), glow + (255,)); gl.putalpha(gm); layers.alpha_composite(gl)
        sh = mask.filter(ImageFilter.GaussianBlur(10))
        shl = Image.new('RGBA', (S, S), (0, 0, 0, 255)); shl.putalpha(sh.point(lambda v: int(v * 0.55)))
        layers.alpha_composite(shl, (0, 10))
        fill = vgrad((S, S), top, bottom); fill.putalpha(mask)
        layers.alpha_composite(fill)
        return layers

    im.alpha_composite(letter('B', x0, (250, 252, 253), (140, 152, 160)))
    xf = x0 + (bw[2] - bw[0]) + gap
    im.alpha_composite(letter('F', xf, (150, 255, 200), (25, 165, 95), glow=(40, 220, 130)))
    arrow = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(arrow)
    pts = [(285, 742), (450, 690), (560, 610), (700, 470), (760, 405)]
    d.line(pts, fill=(60, 230, 140, 255), width=34, joint='curve')
    for p in pts:
        d.ellipse([p[0] - 17, p[1] - 17, p[0] + 17, p[1] + 17], fill=(60, 230, 140, 255))
    d.polygon([(832, 330), (732, 352), (802, 432)], fill=(60, 230, 140, 255))
    im.alpha_composite(arrow.filter(ImageFilter.GaussianBlur(14)))
    im.alpha_composite(arrow)
    return im


bg = background(); fg = foreground()


def rounded_mask(size, radius):
    m = Image.new('L', (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def legacy(size):
    z = 1.12
    fgz = fg.resize((int(S * z), int(S * z)), Image.LANCZOS)
    off = (S - fgz.width) // 2
    comp = bg.copy()
    comp.alpha_composite(fgz.crop((-off, -off, -off + S, -off + S)))
    ImageDraw.Draw(comp).rounded_rectangle([40, 40, S - 41, S - 41], radius=190, outline=(60, 230, 140, 255), width=30)
    comp.putalpha(rounded_mask(S, int(S * 0.22)))
    return comp.resize((size, size), Image.LANCZOS)


dens = {'mdpi': (48, 108), 'hdpi': (72, 162), 'xhdpi': (96, 216), 'xxhdpi': (144, 324), 'xxxhdpi': (192, 432)}
root = 'android_icons'
shutil.rmtree(root, ignore_errors=True)
for k, (l, f) in dens.items():
    p = f'{root}/mipmap-{k}'; os.makedirs(p, exist_ok=True)
    legacy(l).save(f'{p}/ic_launcher.png')
    fg.resize((f, f), Image.LANCZOS).save(f'{p}/ic_launcher_foreground.png')
    bg.convert('RGB').resize((f, f), Image.LANCZOS).save(f'{p}/ic_launcher_background.png')
os.makedirs(f'{root}/mipmap-anydpi-v26', exist_ok=True)
open(f'{root}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''')
os.makedirs('store', exist_ok=True)
legacy(512).save('store/icon-512.png')


def adaptive(size, shape):
    im = Image.alpha_composite(bg, fg).resize((size, size), Image.LANCZOS)
    m = Image.new('L', (size, size), 0); dd = ImageDraw.Draw(m)
    if shape == 'circle':
        dd.ellipse([0, 0, size - 1, size - 1], fill=255)
    else:
        dd.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.30), fill=255)
    im.putalpha(m)
    return im


sheet = Image.new('RGB', (1000, 430), (40, 44, 42))
f = ImageFont.truetype('/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf', 22)
d = ImageDraw.Draw(sheet)
a = adaptive(280, 'circle'); sheet.paste(a, (40, 40), a)
a = adaptive(280, 'squircle'); sheet.paste(a, (350, 40), a)
lg = legacy(280); sheet.paste(lg, (660, 40), lg)
for txt, x in (('Icône ronde', 40), ('Icône arrondie', 350), ('Ancienne forme (Android 7)', 660)):
    d.text((x, 345), txt, fill=(200, 205, 202), font=f)
for sz, x in ((96, 40), (60, 160), (48, 250)):
    a = adaptive(sz, 'squircle'); sheet.paste(a, (x, 385 - sz // 2 - 0), a) if sz <= 48 else None
sheet.save('/mnt/user-data/outputs/apercu_icone.png')
print('ok')
