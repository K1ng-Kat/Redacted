#!/usr/bin/env python3
"""Build-time guard: catalog unlocks must have real drawn cosmetics."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
catalog = (root / "Redacted/UI/DetectiveWardrobe.swift").read_text()
drawing = (root / "Redacted/UI/DetectiveAvatarArt.swift").read_text()
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
for item in items:
    assert f'"{item}"' in drawing, f"No rendered appearance for {item}"
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
, "Social tables need RLS"
print(f"PASS: {len(items)} individually illustrated cosmetics, "
      f"{len(all_emotes)} duel-only emotes, and social RPC contracts.")
