# REDACTED — Native 3D Detective

The character is now a genuine three-dimensional **SceneKit model** built entirely inside the app. There are no AI-generated portrait tiles, fake pasted hat images, or remote art downloads.

## In-app avatar

The 3D implementation lives in `Redacted/UI/Detective3DCharacter.swift`. The existing `DetectiveCharacter` SwiftUI entry point is used on Home, Profile, and the Style Lab and creates a 3D renderer instead of composing image layers.

- Head, eyes, ears, nose, facial features, hair, torso, arms, hands, legs, jacket, and shoes are real scene geometry.
- Saved skin and hairstyle choices still select variants.
- Hats, eyewear, badges, and coat materials are three-dimensional objects and materials attached to the same scene nodes. They are not pasted on a sprite.
- A gentle idle head turn is enabled on the large character preview. Smaller previews are static to reduce frame work.
- The player's cosmetics, wallet, unlocks, and saved `CampaignProgress` schema are unchanged.

This is the **native 3D character system foundation**, not a commercially sculpted photorealistic PBR human mesh. Realistic facial topology, skin normal maps, cloth simulation, motion-captured animation, LODs, and rigged garment meshes would require authored 3D assets. Those can be added later through the model factory without changing purchased item IDs.

## Where the art lives

All new geometry, accessories, and material definitions are committed directly in the Swift source on GitHub. **There is no ZIP to install and no JPEG atlas to commit.** The old `DetectivePortraitAtlas` image is no longer used. Do not commit that earlier AI portrait pack.

## Startup

`RedactedApp.swift` now shows a lightweight first frame with a real loading indicator before constructing the heavier game view. The main loading sequence no longer waits on synchronous audio generation, and an offline game skips the unnecessary Keychain lookup.

## Quality checks before release

- Cold launch on a physical iPhone after force quit, warm launch, first install, and launch with airplane mode.
- Verify Home, Stats and Style Lab, including all 5 skins × 4 hairstyles × equipped hats, glasses, badge and outfit. Use low-end iPad hardware to detect thermal/performance issues.
- Confirm navigation remains responsive while equipment is previewed, equipped and purchased.
- Check actual human proportions, facial details, eyewear alignment, headwear fit, and dark/light accessibility contrast.
- Measure with Xcode Instruments and inspect first frame in system logs. The GitHub Actions build can validate compilation, not cold-launch timing on your phone.

