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


## Version 0.5 — Startup, CC0 soundtrack and credits

- Original REDACTED splash/loading screen: dossier, fingerprint, CLASSIFIED stamp, progress bar, preparation-stage caption and fade to menu.
- Startup progress reflects case catalog and local save loading followed by soundtrack preparation; the brief completed-bar animation transitions into the game.
- Main menu and out-of-game screens use **Bossa Nova** by Joth; active levels use **Shop Theme** by Cleyton Kauffman at a quiet default of 12% of full volume.
- Settings now contain a Music toggle and independent volume sliders for menu and level soundtracks. Sound effects remain a separate control.
- New **App Info & Credits** section at the bottom of Settings includes dynamic version/build numbers, track titles and creator names, OpenGameArt source links and the CC0 license link.
- The soundtrack only plays from local bundled MP3 files, with no internet streaming. It respects the user's Music setting and pauses when the app backgrounds.
- **Asset-import step**: GitHub Actions workflow in \`.github/workflows/import-cc0-music.yml\` runs on the v0.5 commit to download the CC0 track files, select the normal Shop Theme arrangement, convert them with ffmpeg, and commit two \`.mp3\` resources under \`Redacted/Audio/\`.
- If that workflow cannot run (e.g. GitHub Actions is disabled or its bot cannot push), run \`python3 Scripts/import_cc0_music.py\` on a machine with Python 3, commit both generated \`.m4a\` files, and sync.
- \`MUSIC_CREDITS.md\` documents sources and licensing. OpenGameArt licenses are reported as CC0; copyright ownership of uploads is not independently guaranteed.

### Soundtrack QA

1. Confirm the audio import workflow succeeded and both \`Redacted/Audio/*.mp3\` files exist in GitHub before expecting playback.
2. Launch the app: the progress bar and completed state should appear, followed by main menu music.
3. Open any level: the soundtrack should switch to the quieter Shop Theme arrangement.
4. Turn music off and on from Settings, then adjust both sliders; verify no music continues in the background when off.
5. Visit Settings' last section, verify dynamic app version and links open the original artists' pages.

## red-sync — safe two-way Mac/GitHub synchronization

Install or update the command on a Mac with:

```bash
mkdir -p "$HOME/.local/bin" && curl -fsSL https://raw.githubusercontent.com/K1ng-Kat/Redacted/main/Scripts/red-sync -o "$HOME/.local/bin/red-sync" && chmod +x "$HOME/.local/bin/red-sync" && "$HOME/.local/bin/red-sync"
```

Once installed, simply run `red-sync` whenever you want to synchronize.

- Detects changed/new/deleted files in `~/Documents/Redacted`.
- Automatically stages and commits local changes with a timestamp.
- Fetches and merges GitHub's `main` (no forced pushes or resets).
- Pushes local commits to GitHub, including Xcode project and app icon updates.
- Automatically reconciles an Xcode `project.pbxproj` conflict **only when GitHub changed the app version/build settings**, preserving your local project and app-icon settings.
- Creates a named local backup branch before a divergent merge. If other changes conflict, it stops and aborts the merge without discarding local commits.
- Blocks common signing key, secret and credential files from automated upload.
- Requires local Git author identity and push authentication to be configured.

The script checks `origin` belongs to this repository and refuses other checked-out branches. It does not execute on a schedule: run `red-sync` to initiate the sync.

## Version 0.6 — Better game feel, district gates, detective portraits and app icon

- Improved control feel with faster pressed states, tighter cards/layout, larger hittable controls and lighter original tap effects.
- Both menu and level tracks are preloaded; scene changes stop the old track and start the next immediately without overlapping fade. Sound effects are pre-rendered and reused.
- New custom minted gold coin icon and short coin counter/animation with original coin ticks on victory. Respects sound and motion preferences.
- iPhone swipe right from the screen's left edge goes back, never forward. The edge restriction reduces conflict with sliders and puzzles.
- Completed levels require confirmation to replay. Best star ratings are retained.
- An incorrect submitted answer fails the attempt and shows an evidence review/retry screen. Multiple choice and scene hotspots require confirmation.
- Next district opens only after all 10 cases in the current district are cleared and at least 7 have 3 stars (70%).
- Dimmed tutorial overlays explain the opening case and each new district.
- Six stylized detective portraits in the profile, rank-up equip prompt, and progressively higher XP thresholds.
- App-icon fix: Debug and Release select ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon. The existing original 1024x1024 PNG remains unchanged.

### Device testing
Verify icon on device, music transitions, taps, victory coin ticks, edge back, failed attempts, replay, 7-of-10 gate, detective unlocks and portrait rendering. If iOS still caches the previous icon, first clean the Xcode build folder. Deleting/reinstalling removes local game progress, so only do that when necessary.

## Version 0.7 / Build 8 — iPadOS 17, private age profiles and smooth loading

- The single universal Xcode target now has iOS/iPadOS **17.0 as its shared deployment target** and supports iPhone and iPad device families. This enables the 2018 iPad 6th generation, which cannot update to iPadOS 18.
- iPhone on iOS 17 sees an in-app iOS 18 required message. Note that the universal App Store minimum is still 17, so App Store download eligibility is not independently restricted by device family.
- Settings now offers four locally stored gameplay/reading profiles: **6–8 Junior, 9–12 Explorer, 13–15 Investigator, 16+ Expert**. No birth date or identifying information is collected.
- The same 100 authored cases adapt their question language, available choices, evidence prompts and hints. Junior mode uses vocabulary support, two-choice questions, first-event and word scaffolds, plus optional read-aloud. Explorer mode has three choices and read-aloud. Investigator and Expert use four choices and different timeline orders, as well as harder transformed lock codes and frequencies.
- Existing save data, coins, star rewards, lock rules and credits are preserved. The same local save is used for every age profile on one device.
- The startup bar and percentage now interpolate over each real preparation checkpoint with a longer easing curve and a clean fade into the game.
- Research notes and design limitations: see AGE_PROFILES_AND_IPAD.md.

### Test before release
- Physical **iPad 6th generation with iPadOS 17**, portrait and landscape; verify all sound/music assets load and puzzle buttons fit.
- iPhone iOS 18 or later plays normally; iPhone iOS 17 displays the update message.
- For each age profile, play one of each ten puzzle types and verify there is always a reachable correct answer.
- Verify iPad VoiceOver/read-aloud, Profile/Settings changes, startup progress, coins and star progression.
- A separate Xcode build and actual hardware QA are still required. Static checks don't guarantee iPadOS 17 runtime behavior.

## Version 0.8 — Smooth navigation, private first-run setup, opaque icon

- First-launch age setup appears after the startup splash. A wheel picker (ages 6–17 and 18+) and confirmation choose the difficulty.
- Exact age is NEVER written to disk or sent over a network. The selected number is transient SwiftUI state; only a derived difficulty preference and a setup-complete flag are saved locally.
- Settings remains the place to change the resulting difficulty later; its privacy description is now explicit.
- Replaced the buggy whole-screen simultaneous swipe gesture with an interactive swipe-right starting at the extreme left 22-point bezel. The previous screen slides underneath as the user pulls, followed by a short release animation. No swipe-forward gesture.
- Active cases navigate back to the map; other screens navigate back to HQ. Puzzle buttons, horizontal lists, and radio sliders no longer compete with a full-screen drag recognizer.
- The existing 1024x1024 user icon was inspected. Its corners and outer region are transparent, causing a light/white matte under some iOS icon rendering. The fix composites ONLY transparent/semitransparent pixels over dark charcoal; fully opaque original logo pixels remain identical.
- Icon repair script: Scripts/fix_icon_opacity.py. Automation: .github/workflows/fix-icon-opacity.yml. This does not replace the original artwork with a different design.

### Before release
1. Confirm the Remove REDACTED App Icon White Border GitHub Action succeeded, and that the corrected binary PNG was committed back to main.
2. Run red-sync, clean Xcode build folder, reinstall only if necessary (reinstalling deletes local campaign progress).
3. Test first launch and age setup, inspect original icon without a white edge, and verify persistent difficulty but NO stored numeric age.
4. Test interactive swipe from the extreme left edge on iPhone and iPad, and test dragging the radio slider and scrolling normally.
5. Compile and playtest on iPad 6 with iPadOS 17 and iPhone with iOS 18 or later.


## Version 0.9 / Build 10 — Accurate back history, continuous loading, native Game Mode

- Screen navigation keeps a short in-memory history stack. Entering directly from Home and swiping/button back returns Home; entering from the Level Map returns to the map. "Next Level" replaces the current level while retaining the original return destination.
- Back swipe's interactive underlay now renders the real previous screen in the navigation history (not a hardcoded Level Map).
- Adds a dark native LaunchScreen storyboard matching REDACTED's branding and dark startup background instead of relying on a generic generated system launch screen. This reduces the visual flash on cold launch. The OS may still use a prior snapshot on warm resume; the app cannot fully control that.
- Loading animation: the percentage and bar are rendered by one Animatable View using the exact same interpolated fraction. The UI displays before first progress updates, then smoothly advances through genuine catalog/save and audio readiness checkpoints to 100% before revealing Home. No independent jumpy percentage state.
- Opts into Apple's real iOS/iPadOS Game Mode using the Info.plist key LSSupportsGameMode = YES. The **system**, not the app, controls when its banner appears and whether the user has disabled Game Mode. Requires iOS 18 or iPadOS 18+; the iPad 6 running iPadOS 17 still plays without Game Mode.
- The build validation workflow verifies the built Info.plist includes the Game Mode and launch storyboard keys.

### QA

1. Cold launch on iPhone: native dark launch screen → continuous REDACTED loading bar with count matching fill → menu; no normal Home UI before loading.
2. Launch from Home → level → edge swipe and back button must return Home. Launch from Map → level → back must return Map, including after Next Level.
3. Launch from How To Play → level → back returns the guide screen.
4. Inspect Game Mode system banner on supported real iOS 18+ device. The user can turn off Game Mode per app in Control Center, so presence of the banner cannot be guaranteed.
5. Run automated iOS Simulator build and inspect built Info.plist. Verify on physical iPhone and iPad before release.

### Native Game Mode metadata packaging

The game opts in using a **source Info.plist at the repository root** (`Redacted-Info.plist`), referenced by both Xcode target configurations and merged with generated keys. Apple documents that an invented `INFOPLIST_KEY_...` build setting is not sufficient to add a key to the generated Info.plist. Explicit source properties `LSSupportsGameMode = true` and `UILaunchStoryboardName = LaunchScreen` are required. The CI workflow checks both values in the compiled `Redacted.app/Info.plist`.
