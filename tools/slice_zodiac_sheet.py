from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


SIGNS = (
    "aries",
    "taurus",
    "gemini",
    "cancer",
    "leo",
    "virgo",
    "libra",
    "scorpio",
    "sagittarius",
    "capricorn",
    "aquarius",
    "pisces",
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Slice the 4x3 zodiac master sheet.")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    sheet = Image.open(args.source).convert("RGBA")
    if sheet.width % 4 or sheet.height % 3:
        raise ValueError(
            f"Expected a 4x3 sheet with exact cells, got {sheet.width}x{sheet.height}"
        )

    cell_width = sheet.width // 4
    cell_height = sheet.height // 3
    if cell_width != cell_height:
        raise ValueError(f"Expected square cells, got {cell_width}x{cell_height}")

    args.output.mkdir(parents=True, exist_ok=True)
    for index, sign in enumerate(SIGNS):
        row, column = divmod(index, 4)
        left = column * cell_width
        top = row * cell_height
        avatar = sheet.crop((left, top, left + cell_width, top + cell_height))
        avatar.save(
            args.output / f"zodiac_{index + 1:02d}_{sign}.png",
            format="PNG",
            optimize=True,
        )

    print(f"Created {len(SIGNS)} avatars at {cell_width}x{cell_height} px")


if __name__ == "__main__":
    main()
