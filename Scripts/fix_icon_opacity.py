#!/usr/bin/env python3
"""Fix REDACTED iOS AppIcon by fitting the ORIGINAL artwork to the full canvas.

The source PNG has a black rounded-square icon inset ~110 px inside a transparent
1024x1024 canvas. iOS frames the transparent margin, creating a white nested rim.
Merely filling alpha with charcoal keeps the icon too small. This repairs BOTH.

Read the exact historical original icon blob (before any prior 'opacity' fix),
crop only the transparent source padding, resize uniformly to fill the square,
and composite onto opaque near-black. No graphic elements are redrawn.
"""
from io import BytesIO
from pathlib import Path
import subprocess

from PIL import Image

ORIGINAL_BLOB = "efb2b09b627fa8bf78e77f5319a23240a7099770"
ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "Redacted/Assets.xcassets/AppIcon.appiconset/Redacted Files App Icon (1024).png"


def original_image() -> Image.Image:
    source = subprocess.run(
        ["git", "-C", str(ROOT), "cat-file", "blob", ORIGINAL_BLOB],
        check=True,
        capture_output=True,
    ).stdout
    image = Image.open(BytesIO(source)).convert("RGBA")
    if image.size != (1024, 1024):
        raise ValueError(f"Unexpected original icon dimensions: {image.size}")
    return image


def main() -> None:
    original = original_image()
    alpha = original.getchannel("A")
    # Reject stray near-zero-alpha compression/noise around the illustration.
    bounds = alpha.point(lambda value: 255 if value > 90 else 0).getbbox()
    if not bounds:
        raise ValueError("Original icon contains no visible artwork")
    left, top, right, bottom = bounds
    side = max(right - left, bottom - top) + 2
    if not (740 <= side <= 880):
        raise ValueError(f"Unexpected artwork bounds: {bounds}")

    center_x = (left + right) / 2
    center_y = (top + bottom) / 2
    crop_left = round(center_x - side / 2)
    crop_top = round(center_y - side / 2)
    artwork = original.crop((
        crop_left, crop_top, crop_left + side, crop_top + side
    )).resize((1024, 1024), Image.Resampling.LANCZOS)

    # Opaque background. iOS applies the system corner mask ONE time.
    result = Image.new("RGBA", (1024, 1024), (10, 11, 13, 255))
    result.alpha_composite(artwork)
    final = result.convert("RGB")
    final.save(ICON, format="PNG", optimize=True)

    verified = Image.open(ICON)
    if verified.size != (1024, 1024) or verified.mode != "RGB":
        raise ValueError("Generated app icon failed full-size opaque validation")

    print("SUCCESS: original folder, fingerprint and REDACTED banner preserved")
    print(f"Original visible bounds: {bounds}")
    print(f"Source crop: {(crop_left, crop_top, crop_left + side, crop_top + side)}")
    print("Output: opaque 1024x1024, no transparent border, full-canvas icon")


if __name__ == "__main__":
    main()
