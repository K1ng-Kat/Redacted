#!/usr/bin/env python3
"""Build-time guard: catalog unlocks must have a native 3D equipment renderer."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
catalog = (root / "Redacted/UI/DetectiveWardrobe.swift").read_text()
drawing = (root / "Redacted/UI/Detective3DCharacter.swift").read_text()
duel = (root / "Redacted/Game/MultiplayerService.swift").read_text()
social = (root / "Redacted/Game/DetectiveSocialNetwork.swift").read_text()
db = (root / "Backend/supabase_social.sql").read_text()
duel_db = (root / "Backend/duel_rooms.sql").read_text()
account_db = (root / "Backend/account_saves.sql").read_text()
account = (root / "Redacted/Game/DetectiveSocialNetwork.swift").read_text()
account_ui = (root / "Redacted/UI/RedactedAccountView.swift").read_text()
app = (root / "Redacted/UI/CampaignExtras.swift").read_text()

items = re.findall(r'\.init\(id:\s*"([^"]+)",\s*name:', catalog)
assert len(items) >= 39, f"Expected at least 39 cosmetics; got {len(items)}"
assert len(items) == len(set(items)), "Duplicate cosmetic inventory IDs"
# Cosmetic classes are real SceneKit mesh/material components, not decals.
for token in ("import SceneKit", "SCNView", "SCNNode", "makeHeadwear",
              "makeEyewear", "makeBadge", "coatColor"):
    assert token in drawing, f"Missing native 3D renderer component: {token}"
for slot in ("headwear", "eyewear", "badge", "coat"):
    assert f"equipment[.{slot}]" in drawing, f"3D actor ignores {slot}"
assert "DetectivePortraitAtlas" not in drawing
# Static UIImage objects are allowed *only* as snapshots of the real item
# meshes, not as pasted portraits or replacement avatar sprites.
for token in ("CosmeticItemThumbnail", "CosmeticPreviewCache", "SCNRenderer",
              "renderer.snapshot(", "makeCosmeticPreview", "NSCache",
              "makeHeadwear(into: geometry", "makeEyewear(into: geometry",
              "makeBadge(into: geometry", "tailoredTorso(color: jacket)"):
    assert token in drawing, f"Missing real item-only thumbnail: {token}"
assert "CosmeticItemThumbnail(item: item)" in catalog
assert "Image(systemName: item.symbol)" not in catalog, "Placeholder cosmetics returned"
assert "skinMaterial(_ color: UIColor)" in drawing
assert 'let lids = node.childNodes.filter { $0.name == "Upper eyelid" }' in drawing
assert "eyelid.scale.y =" not in drawing, "Old eye stretching must not recur"
# Styling controls must show literal images rendered by the same SceneKit
# factory and palette as the large live avatar, not an approximate swatch.
assert "DetectiveLookThumbnail(skin: shade, hair: .cropped)" in catalog
assert "DetectiveLookThumbnail(skin: store.skin, hair: style)" in catalog
assert "showUncoveredHair" in catalog and "previewEmptySlot: showUncoveredHair" in catalog
assert "showUncoveredHair = true" in catalog
assert 'renderStyle(skin: DetectiveSkin, hair: DetectiveHair)' in drawing
assert "skin: skin, hair: hair, equipment: [:]" in drawing
assert "camera.position = SCNVector3(0, 1.87, 0.76)" in drawing
# None of the four hairstyle modes can be erased just because a hat is worn.
assert 'makeHair(into: head, style: hair,' in drawing
assert 'headwear: equipment[.headwear]' in drawing
assert "guard !wearingHeadwear else { return }" not in drawing
for token in ('case .classic:', 'case .textured:', 'case .swept:', 'case .cropped:',
              'Classic parted fringe', 'Textured forward curl',
              'Side swept long fringe', 'Cropped hairline',
              'Fitted headband', 'head.addChildNode(fitted)'):
    assert token in drawing, f"Missing fitted headwear/hair component: {token}"
for kind in ("headwear", "eyewear", "badge", "coat"):
    assert sum(item.startswith({"headwear": "hat_", "eyewear": "glasses_",
                               "badge": "badge_", "coat": "coat_"}[kind])
               for item in items) >= 8, f"Not enough {kind} cosmetics"

entry = re.search(r'enum DuelEmote:.*?\{(.*?)\n\s*var id:', duel, re.S)
assert entry, "Duel emote model missing"
emotes = re.findall(r'\bcase\s+([a-z_, ]+)', entry.group(1))
all_emotes = [e.strip() for line in emotes for e in line.split(",")]
assert len(all_emotes) == 8 and len(set(all_emotes)) == 8, "Expected 8 duel-only emotes"
assert "guard phase == .playing" in duel, "Emote sender must require a live duel"
assert "rd_duel_emote" in duel and "rd_duel_finish" in duel, "Remote duel RPC support missing"

for method in ("rd_social_snapshot", "rd_social_heartbeat", "rd_social_send_request",
               "rd_task_force_create", "rd_task_force_join", "rd_task_force_leave"):
    assert method in social and method in db, f"Social RPC mismatch: {method}"
assert "row level security" in db.lower()
assert "row level security" in duel_db.lower()
assert "row level security" in account_db.lower()
assert "rd_duel_finish" in duel_db and "p_evidence" in duel_db
assert "rd_account_save_put" in account_db and "p_expected_revision" in account_db
assert "/auth/v1/otp" in account and "/auth/v1/verify" in account
assert "email" in account and "type" in account
assert "REDACTED ID" in account_ui
assert "SignInWithAppleButton" not in app
assert "CloudSaveManager.shared" not in app
print(f"PASS: {len(items)} catalog cosmetics use native 3D render slots, "
      f"{len(all_emotes)} duel-only emotes, and social RPC contracts.")
