#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path("/Users/christopherbivins/Desktop/Coding Thangs/OneTurn")
ASSETS = ROOT / "Sources/OneTurn/Assets.xcassets/AppIcon.appiconset"
MARKETING = ROOT / "Marketing/AppStore"

ICON_SPECS = [
    ("iphone-20@2x.png", "iphone", "20x20", "2x"),
    ("iphone-20@3x.png", "iphone", "20x20", "3x"),
    ("iphone-29@2x.png", "iphone", "29x29", "2x"),
    ("iphone-29@3x.png", "iphone", "29x29", "3x"),
    ("iphone-40@2x.png", "iphone", "40x40", "2x"),
    ("iphone-40@3x.png", "iphone", "40x40", "3x"),
    ("iphone-60@2x.png", "iphone", "60x60", "2x"),
    ("iphone-60@3x.png", "iphone", "60x60", "3x"),
    ("ipad-20@1x.png", "ipad", "20x20", "1x"),
    ("ipad-20@2x.png", "ipad", "20x20", "2x"),
    ("ipad-29@1x.png", "ipad", "29x29", "1x"),
    ("ipad-29@2x.png", "ipad", "29x29", "2x"),
    ("ipad-40@1x.png", "ipad", "40x40", "1x"),
    ("ipad-40@2x.png", "ipad", "40x40", "2x"),
    ("ipad-76@1x.png", "ipad", "76x76", "1x"),
    ("ipad-76@2x.png", "ipad", "76x76", "2x"),
    ("ipad-83.5@2x.png", "ipad", "83.5x83.5", "2x"),
    ("ios-marketing-1024.png", "ios-marketing", "1024x1024", "1x"),
]


def ensure_dirs() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    MARKETING.mkdir(parents=True, exist_ok=True)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/System/Library/Fonts/Supplemental/Georgia Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Georgia.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (size, size), top)
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(1, size - 1)
        color = tuple(int(top[idx] * (1 - t) + bottom[idx] * t) for idx in range(3))
        draw.line((0, y, size, y), fill=color)
    return image


def glow_circle(size: int, center: tuple[float, float], radius: float, color: tuple[int, int, int, int], blur: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    return image.filter(ImageFilter.GaussianBlur(blur))


def render_icon_master() -> Image.Image:
    size = 1024
    base = vertical_gradient(size, (21, 24, 35), (14, 16, 24)).convert("RGBA")

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    overlay.alpha_composite(glow_circle(size, (300, 260), 230, (210, 137, 101, 70), 90))
    overlay.alpha_composite(glow_circle(size, (760, 770), 280, (104, 185, 208, 72), 120))
    overlay.alpha_composite(glow_circle(size, (540, 520), 180, (255, 245, 228, 34), 80))
    base.alpha_composite(overlay)

    draw = ImageDraw.Draw(base)
    stroke = (241, 234, 223, 255)
    accent = (206, 181, 118, 255)

    board = (144, 144, 880, 880)
    draw.rounded_rectangle(board, radius=210, outline=(255, 255, 255, 46), width=10, fill=(255, 255, 255, 18))

    path = [
        (260, 690),
        (260, 392),
        (524, 392),
        (524, 616),
        (760, 616),
    ]
    for width, alpha in [(72, 20), (48, 34), (28, 255)]:
        draw.line(path, fill=(accent[0], accent[1], accent[2], alpha), width=width, joint="curve")

    for point in path[1:-1]:
        x, y = point
        draw.ellipse((x - 38, y - 38, x + 38, y + 38), fill=(255, 255, 255, 22), outline=(255, 255, 255, 60), width=5)

    tx, ty = path[-1]
    draw.ellipse((tx - 56, ty - 56, tx + 56, ty + 56), fill=stroke)
    draw.ellipse((tx - 20, ty - 20, tx + 20, ty + 20), fill=(24, 27, 38, 255))

    for gx in [260, 524, 760]:
        for gy in [392, 616]:
            draw.rounded_rectangle((gx - 62, gy - 62, gx + 62, gy + 62), radius=34, outline=(255, 255, 255, 30), width=4)

    return base


def render_preview(title: str, subtitle: str, badge: str, accent_rgb: tuple[int, int, int], filename: str) -> None:
    width, height = 1290, 2796
    top = (18, 20, 31)
    bottom = (10, 12, 18)
    image = Image.new("RGBA", (width, height), top)
    draw = ImageDraw.Draw(image)

    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(int(top[idx] * (1 - t) + bottom[idx] * t) for idx in range(3))
        draw.line((0, y, width, y), fill=color)

    accent = glow_circle(max(width, height), (300, 400), 420, (*accent_rgb, 64), 130).resize((width, height))
    image.alpha_composite(accent)
    image.alpha_composite(glow_circle(max(width, height), (990, 2280), 500, (109, 180, 207, 54), 170).resize((width, height)))

    panel = (84, 174, width - 84, height - 220)
    draw.rounded_rectangle(panel, radius=72, fill=(255, 255, 255, 18), outline=(255, 255, 255, 34), width=4)
    draw.rounded_rectangle((130, 1080, width - 130, 2140), radius=48, fill=(255, 255, 255, 12), outline=(255, 255, 255, 26), width=3)

    serif = font(146, bold=True)
    sans = font(48, bold=False)
    badge_font = font(44, bold=True)

    draw.text((150, 240), "ONE TURN", font=sans, fill=(214, 222, 236, 220), spacing=6)
    draw.multiline_text((150, 400), title, font=serif, fill=(245, 238, 229, 255), spacing=8)
    draw.multiline_text((150, 840), subtitle, font=sans, fill=(205, 211, 222, 240), spacing=12)

    badge_w, badge_h = 340, 92
    draw.rounded_rectangle((150, 960, 150 + badge_w, 960 + badge_h), radius=46, fill=(18, 22, 36, 220))
    draw.text((184, 982), badge, font=badge_font, fill=(245, 238, 229, 255))

    board_origin = (190, 1140)
    tile = 140
    gap = 22
    for row in range(5):
        for col in range(4):
            x0 = board_origin[0] + col * (tile + gap)
            y0 = board_origin[1] + row * (tile + gap)
            fill = (255, 255, 255, 14)
            if (row, col) in {(1, 1), (2, 1), (2, 2)}:
                fill = (*accent_rgb, 88)
            draw.rounded_rectangle((x0, y0, x0 + tile, y0 + tile), radius=34, fill=fill, outline=(255, 255, 255, 24), width=3)

    path_points = [
        (board_origin[0] + tile * 1.5 + gap, board_origin[1] + tile * 3.5 + gap * 3),
        (board_origin[0] + tile * 1.5 + gap, board_origin[1] + tile * 1.5 + gap),
        (board_origin[0] + tile * 2.5 + gap * 2, board_origin[1] + tile * 1.5 + gap),
    ]
    for line_width, alpha in [(46, 24), (28, 255)]:
        draw.line(path_points, fill=(*accent_rgb, alpha), width=line_width, joint="curve")
    x, y = path_points[-1]
    draw.ellipse((x - 42, y - 42, x + 42, y + 42), fill=(245, 238, 229, 255))

    image.save(MARKETING / filename)


def write_icon_set(master: Image.Image) -> None:
    images = []
    for filename, idiom, size, scale in ICON_SPECS:
        if idiom == "ios-marketing":
            output = master.resize((1024, 1024), Image.Resampling.LANCZOS)
        else:
            base = float(size.split("x")[0])
            multiplier = int(scale[0])
            pixels = int(round(base * multiplier))
            output = master.resize((pixels, pixels), Image.Resampling.LANCZOS)
        output.save(ASSETS / filename)
        images.append({
            "filename": filename,
            "idiom": idiom,
            "size": size,
            "scale": scale,
        })

    (ASSETS / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    ensure_dirs()
    master = render_icon_master()
    master.save(MARKETING / "OneTurn-Icon-Master.png")
    write_icon_set(master)
    render_preview(
        "One swipe.\nOne exact line.",
        "Minimalist daily boards with elegant brutality and instant restarts.",
        "Daily Ritual",
        (197, 167, 110),
        "OneTurn-Preview-Daily.png",
    )
    render_preview(
        "Keep the run\nalive.",
        "Endless mode builds pressure softly: chain solves, score beautifully, begin again.",
        "Endless Flow",
        (118, 204, 216),
        "OneTurn-Preview-Endless.png",
    )
    render_preview(
        "Place the bend.\nThen commit.",
        "Planning boards let you compose the route before the single decisive swipe.",
        "Studio Depth",
        (210, 135, 112),
        "OneTurn-Preview-Studio.png",
    )


if __name__ == "__main__":
    main()
