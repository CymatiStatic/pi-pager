"""
Generate pi-notify PNG thumbnails using Pillow (no external rendering deps).
Outputs:
  - logo-512.png     (square icon)
  - social-1280x640.png (GitHub social preview)
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, sys

OUT = os.path.dirname(os.path.abspath(__file__))


def gradient(w, h, c1=(99, 102, 241), c2=(168, 85, 247)):
    """Diagonal linear gradient c1 -> c2."""
    img = Image.new("RGB", (w, h), c1)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w + y / h) / 2
            r = int(c1[0] * (1 - t) + c2[0] * t)
            g = int(c1[1] * (1 - t) + c2[1] * t)
            b = int(c1[2] * (1 - t) + c2[2] * t)
            px[x, y] = (r, g, b)
    return img


def rounded_rect(img, radius):
    """Apply rounded corners to an RGB image -> RGBA."""
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    img_rgba = img.convert("RGBA")
    img_rgba.putalpha(mask)
    return img_rgba


def draw_bell(draw, cx, cy, scale=1.0, fill="white", outline=(31, 17, 69), width=6):
    """Draw a stylized bell centered at (cx, cy)."""
    s = scale
    # Bell body (rounded dome + flared bottom)
    # Approximate path with a polygon
    body = [
        (cx - 125*s, cy + 115*s),
        (cx - 125*s, cy + 105*s),
        (cx - 120*s, cy + 93*s),
        (cx - 115*s, cy + 80*s),
        (cx - 115*s, cy - 25*s),
        (cx - 100*s, cy - 80*s),
        (cx - 60*s,  cy - 115*s),
        (cx,         cy - 125*s),
        (cx + 60*s,  cy - 115*s),
        (cx + 100*s, cy - 80*s),
        (cx + 115*s, cy - 25*s),
        (cx + 115*s, cy + 80*s),
        (cx + 120*s, cy + 93*s),
        (cx + 125*s, cy + 105*s),
        (cx + 125*s, cy + 115*s),
    ]
    draw.polygon(body, fill=fill, outline=outline)
    for i in range(int(width*s)):
        draw.line(body + [body[0]], fill=outline, width=1)

    # Handle on top
    hw = int(12 * s); hh = int(18 * s)
    draw.rounded_rectangle(
        (cx - hw, cy - 145*s, cx + hw, cy - 145*s + hh*2),
        radius=int(5*s), fill=fill, outline=outline, width=int(width*s)
    )

    # Clapper (circle at bottom)
    r = int(22 * s)
    draw.ellipse(
        (cx - r, cy + 145*s - r, cx + r, cy + 145*s + r),
        fill=fill, outline=outline, width=int(width*s)
    )


def draw_sound_waves(draw, cx, cy, scale=1.0, color=(255, 255, 255, 220), width=7):
    """Arcs on both sides suggesting ringing."""
    s = scale
    # Inner arcs
    draw.arc((cx - 220*s, cy - 60*s, cx - 140*s, cy + 60*s), 240, 120, fill=color, width=int(width*s))
    draw.arc((cx + 140*s, cy - 60*s, cx + 220*s, cy + 60*s), -60, 60, fill=color, width=int(width*s))
    # Outer arcs
    draw.arc((cx - 280*s, cy - 100*s, cx - 160*s, cy + 100*s), 240, 120, fill=color, width=int(width*s))
    draw.arc((cx + 160*s, cy - 100*s, cx + 280*s, cy + 100*s), -60, 60, fill=color, width=int(width*s))


def make_logo(size=512):
    img = gradient(size, size)
    img = rounded_rect(img, radius=size // 5)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(img)
    d = ImageDraw.Draw(canvas)

    scale = size / 512
    draw_sound_waves(d, size // 2, size // 2, scale=scale, width=7)
    draw_bell(d, size // 2, size // 2, scale=scale, width=5)

    out = os.path.join(OUT, f"logo-{size}.png")
    canvas.save(out, "PNG")
    print(f"wrote {out}")


def get_font(sz, bold=False):
    candidates_bold = [
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    candidates_reg = [
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for p in (candidates_bold if bold else candidates_reg):
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, sz)
            except Exception:
                pass
    return ImageFont.load_default()


def make_social():
    """GitHub social preview: 1280x640, dark, logo + title + tagline."""
    W, H = 1280, 640
    bg = gradient(W, H, c1=(20, 18, 48), c2=(55, 28, 95))
    canvas = bg.convert("RGBA")
    d = ImageDraw.Draw(canvas)

    # Left side: logo tile
    tile_sz = 360
    tile_img = gradient(tile_sz, tile_sz, c1=(99, 102, 241), c2=(168, 85, 247))
    tile_img = rounded_rect(tile_img, radius=tile_sz // 5)
    tile_canvas = Image.new("RGBA", (tile_sz, tile_sz), (0, 0, 0, 0))
    tile_canvas.alpha_composite(tile_img)
    td = ImageDraw.Draw(tile_canvas)
    scale = tile_sz / 512
    draw_sound_waves(td, tile_sz // 2, tile_sz // 2, scale=scale, width=6)
    draw_bell(td, tile_sz // 2, tile_sz // 2, scale=scale, width=4)
    canvas.alpha_composite(tile_canvas, dest=(80, (H - tile_sz) // 2))

    # Right side: text
    title_font   = get_font(96, bold=True)
    tagline_font = get_font(34, bold=False)
    small_font   = get_font(26, bold=False)

    tx = 500
    # Title
    d.text((tx, 180), "pi-notify", fill="white", font=title_font)
    # Tagline
    d.text((tx, 300),
           "Cross-channel alerts for",
           fill=(229, 231, 235), font=tagline_font)
    d.text((tx, 345),
           "agentic AI workflows",
           fill=(229, 231, 235), font=tagline_font)
    # Channel chips (draw on separate transparent layer to get real alpha)
    chips_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chips_img)
    chips = ["Sound", "Toast", "ntfy", "Discord", "Slack", "Telegram", "Pushover"]
    chip_y = 430
    chip_x = tx
    chip_pad = 16
    for c in chips:
        bbox = cd.textbbox((0, 0), c, font=small_font)
        cw = bbox[2] - bbox[0]; ch = bbox[3] - bbox[1]
        if chip_x + cw + chip_pad * 2 > W - 60:
            chip_x = tx
            chip_y += 56
        cd.rounded_rectangle(
            (chip_x, chip_y - 4, chip_x + cw + chip_pad * 2, chip_y + ch + 14),
            radius=20, fill=(99, 102, 241, 90), outline=(180, 180, 255, 200), width=2
        )
        cd.text((chip_x + chip_pad, chip_y + 2), c, fill=(255, 255, 255, 255), font=small_font)
        chip_x += cw + chip_pad * 2 + 12
    canvas.alpha_composite(chips_img)
    # URL footer
    d.text((tx, 560), "github.com/CymatiStatic/pi-notify",
           fill=(200, 200, 255), font=small_font)

    out = os.path.join(OUT, "social-1280x640.png")
    canvas.convert("RGB").save(out, "PNG", optimize=True)
    print(f"wrote {out}")


if __name__ == "__main__":
    make_logo(512)
    make_logo(256)
    make_logo(128)
    make_social()
    print("done")
