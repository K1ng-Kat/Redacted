# REDACTED — Single-player Detective Campaign

## Version 0.4 / Build 5

A complete overhaul of the first playable prototype into a **100-level offline campaign** with ten original mystery districts and ten different puzzle interaction patterns. The game is now presented as a light, easy-to-navigate, replayable mobile puzzler rather than a confusing dossier interface.

### Play
- A simple home screen with one large PLAY action.
- A LEVELS map with 10 themed districts and 100 numbered challenges, each with its own scenario and resolution.
- Puzzle types: spot a clue, reconstruct a timeline, code keypad, expose a contradiction, find an anomaly, select a hidden route, unscramble a word, tune a radio, match two pieces of evidence, and choose the culprit.
- Contextual prompts, optional hints, tutorial, error feedback, stars and case-completion summaries.
- Accessible back navigation, safe area scrolling, larger tap targets and optional animations.
- Locally saved completion status, unlocked stages and best star rating for each level.

### Detective account / rewards
- Start with 50 coins and two free hints.
- First solve: 90 XP + 20 XP per earned star, 35 coins + 8 per star.
- Solve the final level of a district: an extra 80 XP and 100 coins (first clear only).
- Every rank increase awards 60 coins and a free hint ticket.
- Rank-based titles and six unlockable background themes (ranks 1, 3, 6, 10, 15 and 20).
- Hint ticket first; if none remain, a hint costs 30 coins. Hints lower potential star ratings.
- Replays pay only for improved best star ratings, preventing infinite coin farming.
- Campaign and account data stored locally in `UserDefaults`, with no paid currency or network dependency.

### Menus
PLAY / LEVEL SELECT / DETECTIVE PROFILE & REWARDS / HOW TO PLAY / SETTINGS.
Settings include sound, haptics, motion, hint-button visibility and a confirmed reset action.

### Visual bug fix
Replaced all visible legacy views and removed inherited text effects. The new interface uses solid colors and backgrounds with depth behind the surface; **text itself receives no offset, shadow or reflection effects**. This targets the reported mirrored/ghosted text appearance, but requires validation on an iPhone.

### Technical
Native SwiftUI and Apple frameworks. Minimum iOS 18. Existing shared `Redacted` scheme remains available for Xcode Cloud. New sources are automatically included by Xcode's synchronized source group. No external assets, API keys, ads, servers or accounts needed.

### Manual QA on iPhone
1. Launch and verify the first-time tutorial appears and the home screen is legible.
2. Solve Levels 1–10 to validate all ten mechanics and the district rewards.
3. Leave a level midway and resume; previously solved levels should remain unlocked.
4. Open Detective Profile, check coins/XP, unlock/equip cosmetics.
5. Use two free hint tickets, then use 30 coins for another hint; confirm spending and star deductions.
6. Replay a cleared case; ensure XP/coins aren't repeatedly granted unless stars improve.
7. Inspect screens at different Dynamic Type sizes and light/dark system settings for ghosted text.
8. Reset the campaign and verify coins, tickets, levels, stars and account level return to defaults.

The initial Case 001 prototype source/save is retained in the existing repository history and device storage; this campaign starts with a new separate save namespace. No online multiplayer functionality is claimed.

**Build status:** Source/static checks performed; an Xcode/device build and playtesting remain required.
