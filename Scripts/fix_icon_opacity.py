#!/usr/bin/env python3
"""Fix the existing REDACTED app icon's transparent outer perimeter.

Apple App Store icons should be opaque. The original authored icon contains
transparent corners/outside padding; some iOS icon rendering paths matte them
white, causing the reported white rim.

Keep every original fully-opaque pixel UNCHANGED. Only composite transparent
and semitransparent pixels against a matching dark charcoal background.
Do not crop, rescale, repaint or regenerate the existing icon artwork.
"""
from pathlib import Path
from PIL import Image

ICON = (
    Path(__file__).resolve().parents[1]
    / "Redacted"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
    / "Redacted Files App Icon (1024).png"
)


def main() -> None:
    original = Image.open(ICON).convert("RGBA")
    if original.size != (1024, 1024):
        raise SystemExit(f"Refusing to alter unexpected icon size: {original.size}")

    alpha = original.getchannel("A")
    minimum, maximum = alpha.getextrema()
    if minimum == 255:
        print("App icon already completely opaque; no modification needed.")
        return
    if maximum < 180:
        raise SystemExit("The app icon has no opaque interior; refusing to alter.")

    # RGB 20/21/26 is a neutral near-black that matches the illustration's
    # outer dark edge and avoids white/light corner matting on iOS.
    background = Image.new("RGBA", original.size, (20, 21, 26, 255))
    background.alpha_composite(original)
    result = background.convert("RGB")

    # Critical guarantee: any fully opaque original pixels are pixel-identical.
    # AI/export pipelines sometimes cap alpha at 254 rather than 255; accept
    # that common near-opaque format and composite it consistently.
    opaque_mask = alpha.point(lambda value: 255 if value == 255 else 0)
    original_rgb = original.convert("RGB")
    from PIL import ImageChops
    difference = ImageChops.difference(original_rgb, result)
    if ImageChops.multiply(difference, Image.merge("RGB", (opaque_mask,) * 3)).getbbox():
        raise SystemExit("Opaque original artwork unexpectedly changed")

    result.save(ICON, format="PNG", optimize=True)
    rebuilt = Image.open(ICON)
    if rebuilt.mode != "RGB" or rebuilt.size != (1024, 1024):
        raise SystemExit("The rebuilt app icon is invalid")

    print("SUCCESS: replaced transparent outer rim with an opaque dark background.")
    print(f"Preserved the original 1024x1024 icon and all opaque foreground artwork.")
    print(f"Original alpha range: {minimum}–{maximum}; output mode: {rebuilt.mode}.")


if __name__ == "__main__":
    main()
