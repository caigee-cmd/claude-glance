#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: resize-alpha-icon.py <source.png> <output.png> <size>", file=sys.stderr)
        return 1

    source_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    size = int(sys.argv[3])

    if not source_path.is_file():
        print(f"Source icon not found: {source_path}", file=sys.stderr)
        return 1

    image = Image.open(source_path).convert("RGBA")
    resized = image.resize((size, size), Image.Resampling.LANCZOS)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    resized.save(output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
