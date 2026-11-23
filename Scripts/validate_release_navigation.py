#!/usr/bin/env python3
"""Prevent release polish from hiding navigation or reintroducing fake loading."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
read = lambda rel: (root / rel).read_text()

navigation = read("Redacted/ContentView.swift")
app = read("Redacted/RedactedApp.swift")
loader = read("Redacted/UI/StartupLoadingView.swift")
network = read("Redacted/Game/RedactedLaunchManager.swift")
settings = read("Redacted/UI/CampaignExtras.swift")
more = read("Redacted/UI/CampaignMoreView.swift")
social = read("Redacted/UI/DetectiveSocialHubView.swift")
duels = read("Redacted/UI/MultiplayerViews.swift")
wardrobe = read("Redacted/UI/DetectiveWardrobe.swift")
actor = read("Redacted/UI/Detective3DCharacter.swift")
plist = read("Redacted-Info.plist")
mission = read("Redacted/UI/MissionPlay.swift")
campaign = read("Redacted/Game/CampaignStore.swift")

for route in (".home", ".levels", ".multiplayer", ".friends", ".more"):
    assert f"mainTab({route}," in navigation, f"Missing main tab {route}"
for route in ("settings", "guide", "stats", "wardrobe", "season"):
    assert f"case .{route}:" in navigation, f"Missing destination {route}"
assert "CampaignMoreView(" in navigation
assert "CampaignSettingsView(" in navigation
assert "CampaignGuideView(" in navigation
assert "DetectiveWardrobeView(" in navigation
assert "SeasonHubView(" in navigation
assert "Offline Mode" in settings
assert "redacted.offlineMode" in settings and "redacted.offlineMode" in network
assert "RedactedFirstFrameGate()" in app
assert "StartupLoadingView(" in app
assert "StartupLoadingView(" not in navigation, "Nested loading views create a second splash"
assert "prepareStartup()" not in navigation
for token in ("AnimatedLoadingMeter", "PLAY OFFLINE", "RETRY", "issue:"):
    assert token in loader, f"Missing boot UI feature: {token}"
for token in ("NWPathMonitor", "URLSession.shared.data", "RDStartupManifestURL",
              "ready = true", "playOffline()", "minimumBuild", "timeoutInterval"):
    assert token in network, f"Missing startup gate: {token}"
assert "RDStartupManifestURL" in plist
assert "offlineMode" in duels and "offlineMode" in social
assert "portraitMode:" in wardrobe
assert "isTryingOn" in wardrobe
assert "DetectiveCharacter(store: store, size: 122, previewCosmetic: item)" not in wardrobe
for token in ("makeHair", "makeHeadwear", "makeEyewear", "makeBadge", "makeCoatDetails"):
    assert token in actor, f"3D actor missing {token}"

# A free or paid hint is permanently revealed per level in the same
# progress snapshot that backs up/restores the player's other campaign data.
for token in ('revealedHintLevels: Set<Int>', 'decodeIfPresent(Set<Int>.self,',
              'hasRevealedHint(for level: Int)', 'func redeemHint(for level: Int)',
              'if hasRevealedHint(for: level) { return true }',
              'updated.revealedHintLevels.insert(level)', 'progress = updated'):
    assert token in campaign, f"Hint persistence contract broken: {token}"
assert 'store.redeemHint(for: mission.id)' in mission
assert 'store.hasRevealedHint(for: mission.id)' in mission
assert 'hintVisible = false' not in mission, "Reopening must not hide bought hints"
# Ordering choices should be reversible without clearing the whole attempt.
assert 'selectedSequence.remove(at: chosenPosition)' in mission
assert '.disabled(chosenPosition != nil)' not in mission
assert 'usedLetterIndices.remove(at: position)' in mission
assert '.disabled(usedLetterIndices.contains(index))' not in mission

print("PASS: all Redacted routes and original options available; one loading screen, "
      "offline choice, distinct 3D equipment and future update policy present")
