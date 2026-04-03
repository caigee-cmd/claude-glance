#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024
CARD_INSET = 92
CARD_RADIUS = 220
LINE_WIDTH = 58
NODE_RADIUS = 40
SHADOW_OFFSET_Y = 26
SHADOW_BLUR = 42


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def rounded_mask(size: int, inset: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=255,
    )
    return mask


def make_background(size: int, mask: Image.Image) -> Image.Image:
    top = (252, 249, 244)
    bottom = (243, 239, 232)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    for y in range(size):
        t = y / (size - 1)
        row = tuple(int(lerp(top[i], bottom[i], t)) for i in range(3)) + (255,)
        for x in range(size):
            bg.putpixel((x, y), row)

    # Add a soft warm highlight so the plate doesn't feel flat.
    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.ellipse(
        (-120, -40, size * 0.82, size * 0.68),
        fill=(255, 255, 255, 74),
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(58))
    bg = Image.alpha_composite(bg, highlight)

    plate = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    plate.paste(bg, mask=mask)
    return plate


def make_shadow(size: int, mask: Image.Image) -> Image.Image:
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_alpha = Image.new("L", (size, size), 0)
    shadow_alpha.paste(mask, (0, SHADOW_OFFSET_Y))
    shadow_alpha = shadow_alpha.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))
    shadow.putalpha(shadow_alpha)

    shadow_tint = Image.new("RGBA", (size, size), (34, 31, 28, 56))
    return Image.composite(shadow_tint, shadow, shadow_alpha)


def draw_chart(base: Image.Image) -> None:
    points = [
        (262, 634),
        (426, 472),
        (556, 570),
        (774, 354),
    ]

    accent = (216, 145, 63, 255)
    charcoal = (61, 63, 72, 255)

    shadow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_points = [(x, y + 10) for x, y in points]
    shadow_draw.line(shadow_points, fill=(32, 28, 24, 44), width=LINE_WIDTH, joint="curve")
    for point in shadow_points:
        shadow_draw.ellipse(
            (
                point[0] - NODE_RADIUS,
                point[1] - NODE_RADIUS,
                point[0] + NODE_RADIUS,
                point[1] + NODE_RADIUS,
            ),
            fill=(32, 28, 24, 44),
        )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(shadow_layer)

    line_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    line_draw = ImageDraw.Draw(line_layer)
    line_draw.line(points, fill=charcoal, width=LINE_WIDTH, joint="curve")

    for index, point in enumerate(points):
        fill = accent if index == len(points) - 1 else charcoal
        radius = NODE_RADIUS + (6 if index == len(points) - 1 else 0)
        line_draw.ellipse(
            (
                point[0] - radius,
                point[1] - radius,
                point[0] + radius,
                point[1] + radius,
            ),
            fill=fill,
        )

    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    x, y = points[-1]
    glow_draw.ellipse((x - 68, y - 68, x + 68, y + 68), fill=(229, 167, 89, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(24))

    highlight = Image.new("RGBA", base.size, (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.line(points, fill=(255, 255, 255, 40), width=10, joint="curve")

    base.alpha_composite(glow)
    base.alpha_composite(line_layer)
    base.alpha_composite(highlight)


def add_plate_stroke(base: Image.Image, inset: int, radius: int) -> None:
    stroke = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(stroke)
    draw.rounded_rectangle(
        (inset + 2, inset + 2, SIZE - inset - 2, SIZE - inset - 2),
        radius=radius,
        outline=(255, 255, 255, 70),
        width=4,
    )
    base.alpha_composite(stroke)


def render_icon() -> Image.Image:
    mask = rounded_mask(SIZE, CARD_INSET, CARD_RADIUS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(make_shadow(SIZE, mask))
    canvas.alpha_composite(make_background(SIZE, mask))
    add_plate_stroke(canvas, CARD_INSET, CARD_RADIUS)
    draw_chart(canvas)
    return canvas


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    icon_source_dir = repo_root / "ClaudeDash" / "Resources" / "IconSource"
    app_icon_path = icon_source_dir / "AppIcon-1024.png"

    icon_source_dir.mkdir(parents=True, exist_ok=True)
    render_icon().save(app_icon_path)
    print(f"Wrote {app_icon_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
