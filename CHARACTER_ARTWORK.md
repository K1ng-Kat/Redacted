# Photoreal detective character renderer

The game now supports an authored 4×5 portrait atlas named `DetectivePortraitAtlas` and paints selected wardrobe equipment over it. The source renderer lives in `Redacted/UI/DetectiveRealisticAvatar.swift`.

The atlas has **4 hair columns** (Classic, Textured, Side Sweep, Cropped) and **5 skin-tone rows** (Porcelain, Peach, Bronze, Umber, Deep). It is one JPEG imported into the asset catalog as `DetectivePortraitAtlas.imageset/DetectivePortraitAtlas.jpg`. This setup avoids loading 20 independent portraits.

## Adding artwork to a build

1. Create `Redacted/Assets.xcassets/DetectivePortraitAtlas.imageset`.
2. Put your 4×5 image in the folder as `DetectivePortraitAtlas.jpg`.
3. Add a `Contents.json` file with:
   ```json
   {"images":[{"filename":"DetectivePortraitAtlas.jpg","idiom":"universal"}],
    "info":{"author":"xcode","version":1}}
   ```
4. Build the app.

If the atlas is not bundled, the app automatically falls back to the existing SwiftUI illustration. This is intentional so existing builds keep working; an asset-backed release should be tested with the atlas included.

## What stays compatible

- All existing skin/hair selections, paid/unlocked cosmetic IDs, shop currencies and rank rules stay exactly the same.
- Home, rank/profile, main wardrobe preview and equipment thumbnails all call `DetectiveCharacter`, so they automatically use the same avatar.
- Cosmetic rendering is a photo-compositing approximation. For fully physically realistic clothes and animation, future work would require individual material layers or a rigged 3D character; this implementation is a static photoreal portrait, **not a realtime 3D model**.

## QA

On both iPhone and iPad verify every skin × hair selection, each headwear/glasses/badge/coat, the live try-on, unlock/equip/unequip, and all avatar sizes (48/78/122/215 points). Ensure the artwork contains no blank margins or cell borders and that cosmetics do not obscure the detective's face. Test a build missing the atlas to ensure it still renders the fallback without a crash.
