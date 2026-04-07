#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image


LOW_THRESHOLD = 180
HIGH_THRESHOLD = 235
CANVAS_PADDING_RATIO = 0.11


def extract_mask(source: Image.Image) -> Image.Image:
    source = source.convert("RGBA")
    mask = Image.new("L", source.size, 0)

    for y in range(source.height):
        for x in range(source.width):
            r, g, b, a = source.getpixel((x, y))
            if a == 0:
                continue

            luminance = int((r * 299 + g * 587 + b * 114) / 1000)
            if luminance >= HIGH_THRESHOLD:
                alpha = 0
            elif luminance <= LOW_THRESHOLD:
                alpha = 255
            else:
                alpha = int((HIGH_THRESHOLD - luminance) / (HIGH_THRESHOLD - LOW_THRESHOLD) * 255)

            if alpha > 0:
                mask.putpixel((x, y), alpha)

    return mask


def build_template_image(mask: Image.Image, size: int) -> Image.Image:
    bbox = mask.getbbox()
    if bbox is None:
        raise RuntimeError("Could not extract a visible glyph from the source icon.")

    glyph = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    glyph.putalpha(mask)
    glyph = glyph.crop(bbox)

    padding = max(1, round(size * CANVAS_PADDING_RATIO))
    target_side = max(1, size - (padding * 2))
    scale = min(target_side / glyph.width, target_side / glyph.height)
    resized = glyph.resize(
        (max(1, round(glyph.width * scale)), max(1, round(glyph.height * scale))),
        Image.Resampling.LANCZOS,
    )

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = ((size - resized.width) // 2, (size - resized.height) // 2)
    canvas.alpha_composite(resized, dest=offset)
    return canvas


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: generate-menubar-icon.py <source.png> <output.png> <size>", file=sys.stderr)
        return 1

    source_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    size = int(sys.argv[3])

    if not source_path.is_file():
        print(f"Source icon not found: {source_path}", file=sys.stderr)
        return 1

    mask = extract_mask(Image.open(source_path))
    output = build_template_image(mask, size)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
