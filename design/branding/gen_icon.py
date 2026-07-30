OUT = "design/branding"
from PIL import Image, ImageDraw, ImageFilter

SS = 4
S = 1024 * SS

SAND    = (0xE7, 0xD5, 0xB6, 255)
SAND_HI = (0xF3, 0xE7, 0xCF, 255)
BASALT_D = (0x3A, 0x3A, 0x38, 255)
BASALT_L = (0x57, 0x55, 0x50, 255)
OCRE     = (0xB0, 0x74, 0x3F, 255)
TIARE    = (0xFC, 0xF7, 0xE6, 255)

# Pierres de bas en haut : (largeur, hauteur, couleur, décalage x) en fractions de B.
STONES = [
    (0.64, 0.205, BASALT_L, 0.000),
    (0.52, 0.190, OCRE,     0.032),
    (0.415, 0.170, BASALT_D, -0.038),
    (0.30, 0.150, BASALT_L,  0.018),
]

# Palette éclaircie pour le fond nuit (les pierres basalte y seraient invisibles).
STONES_DARK = [
    (0.64, 0.205, (0x8C, 0x88, 0x7E, 255), 0.000),
    (0.52, 0.190, (0xCB, 0x92, 0x5C, 255), 0.032),
    (0.415, 0.170, (0x6C, 0x68, 0x60, 255), -0.038),
    (0.30, 0.150, (0x9A, 0x96, 0x8A, 255), 0.018),
]


def _ellipse(draw, cx, cy, w, h, color):
    draw.ellipse([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], fill=color)


def draw_cairn(base, cx, cy_center, B, stones=STONES, shadow=True):
    """Dessine un cairn centré sur (cx, cy_center), largeur ~B."""
    total_h = B * 0.86
    y_bottom = cy_center + total_h / 2

    if shadow:
        sh = Image.new("RGBA", base.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        _ellipse(sd, cx, y_bottom + B * 0.015, B * 0.62, B * 0.09, (60, 45, 25, 70))
        sh = sh.filter(ImageFilter.GaussianBlur(B * 0.02))
        base.alpha_composite(sh)

    draw = ImageDraw.Draw(base)
    hi = Image.new("RGBA", base.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi)

    yb = y_bottom
    for wf, hf, color, xo in stones:
        w, h = wf * B, hf * B
        x = cx + xo * B
        cyi = yb - h / 2
        _ellipse(draw, x, cyi, w, h, color)
        # reflet doux en haut-gauche
        hd.ellipse(
            [x - w * 0.34, cyi - h * 0.30, x + w * 0.06, cyi + h * 0.04],
            fill=(TIARE[0], TIARE[1], TIARE[2], 60),
        )
        yb = cyi - h * 0.14

    hi = hi.filter(ImageFilter.GaussianBlur(B * 0.01))
    base.alpha_composite(hi)


def radial_bg():
    img = Image.new("RGBA", (S, S), SAND)
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    # halo centré derrière le cairn
    gd.ellipse([S * 0.16, S * 0.08, S * 0.84, S * 0.80], fill=SAND_HI)
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.11))
    img.alpha_composite(glow)
    return img


def save(img, path):
    img.resize((1024, 1024), Image.LANCZOS).save(path)


# Icône pleine (iOS / legacy) : fond sable + cairn.
full = radial_bg()
draw_cairn(full, S / 2, S * 0.46, S * 0.74)
save(full, OUT + "/icon.png")

# Calque avant (icône adaptative Android + splash) : transparent + cairn (zone sûre ~56%).
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw_cairn(fg, S / 2, S * 0.48, S * 0.72)
save(fg, OUT + "/icon_foreground.png")

# Splash clair : cairn sur fond transparent (le sable vient de native_splash).
sp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw_cairn(sp, S / 2, S * 0.50, S * 0.46)
save(sp, OUT + "/splash.png")

# Splash sombre : palette éclaircie, sans ombre (invisible sur la nuit).
spd = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw_cairn(spd, S / 2, S * 0.50, S * 0.46, stones=STONES_DARK, shadow=False)
save(spd, OUT + "/splash_dark.png")

print("ok")
