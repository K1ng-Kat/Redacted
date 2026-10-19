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

## Version 1.0 / Build 11 — Crystals, Apple sign-in, and adaptive startup

### Currency and hints
- Players begin with **2 free hint tickets**, separate from spendable currency. New games begin with 0 crystals.
- Afterwards, each hint requires **2 crystals**, with a confirmation dialog. Currency purchases are not offered.
- Each district pays **one crystal once** after all ten stages are cleared and at least seven have a 3-star rating. The district is tracked as claimed, so replays cannot farm crystals. Existing saves automatically claim previously earned district crystals during migration.
- Coins, XP, rank rewards and 100 authored cases remain; rank increases grant coins, no longer extra hint tickets.
- The crystal design is an original **asymmetrical seven-facet lavender prism** rendered in SwiftUI; it is not the uploaded symmetrical reference emblem.

### Optional cross-device backup
- Settings → **Account & Cloud Save** has native **Sign in with Apple**, sign-out, sync status and Sync Now.
- Campaign, best stars, all balances, district claims, detective unlocks and selected preferences are stored in the user's **private CloudKit database**, keyed to the device's iCloud account. A newer timestamped save replaces the older one; scarce currency is **never added together** across devices. Concurrent offline play may require resolving which recent save to keep.
- Sign in with Apple authenticates the player. **Private CloudKit sync also requires the same iCloud account**, a working network, and iCloud access on both devices. Signing in with a different iCloud account does not merge your progress.
- The existing local save continues to work offline. An actual cloud sync is only confirmed after the app reports a successful operation, not merely successful Apple sign-in.
- Sign-out keeps the local save. Resetting a synced save can overwrite the cloud backup on the next sync.
- New project entitlements: Sign in with Apple and CloudKit with proposed container `iCloud.com.UtilityFreak.Redacted`. The developer must register/enable this container and both capabilities under the App ID `com.UtilityFreak.Redacted` on Apple Developer and ensure Xcode automatic signing provisions them. The GitHub simulator build only validates compilation; **device cloud syncing needs live provisioning and an iCloud account**.

### Startup layout
- Adapts the fingerprint dossier and loading meter to available vertical space on compact iPhones, larger iPhones and iPad landscape. The bar and explanatory text remain inside the screen instead of being pushed below the bottom safe area.
- The previously synchronized bar/percentage and Game Mode settings remain.

### Verification
1. Build on iPhone and an iPad 6; check compact startup has fully visible artwork and progress labels.
2. Claim 7 three-star clears and all 10 levels in a district: verify exactly one crystal, even after replay.
3. Spend the two starting hint tickets, then verify 2 crystals per new hint and the confirmation prompt.
4. Enable the two Apple developer capabilities and CloudKit container, install signed builds on two devices using the same Apple/iCloud account; sign in on each and verify actual backed-up/recovered progress, equipped detective, age profile and spent crystals.
5. Test offline and conflict behavior with separate device progress; newest timestamp wins, so avoid making progress offline on both devices until a merge strategy is introduced.

## Build 12 — Home screen and startup layout polish

- Organized all three Home navigation controls (Help, Settings, Detective Profile) as same-sized 44-point touch targets in one horizontal row next to the game logo.
- Moved Profile out of the separate Stars/Solved stats row, leaving two consistently aligned progress chips underneath the header.
- Disabled elastic pull/overscroll on **Home only** using a scoped UIKit scroll-view marker. Normal vertical scrolling remains enabled, and other screens' scrolling remains unchanged.
- Fixed startup foreground safe-area overlap (clock/dynamic island) by **removing** the foreground's `ignoresSafeArea()`. The background still extends edge-to-edge.
- Rescaled the startup dossier to a maximum of 84% of its previous size and calculated a smaller size for compact iPhones. Top logo, central artwork, animated meter and copyright now use safe-area-aware vertical layout.
- Settings now displays one small Age & Difficulty summary card. **Edit** opens all age-mode choices in a modal; Cancel dismisses without changing the profile, and **Save Difficulty** commits the change to local preferences/cloud sync.
- Keeps all 100 case levels, hint/free-ticket rules, currency progression, native startup bar animation, and the existing Apple/iCloud account section intact.

### Device QA
- Check iPhone Home header at normal and large text sizes; Help, Settings and Profile should be aligned and all tappable.
- Pull the Home screen downward from the top: no rubber-band/stretch. Scroll upward through the campaign: content should scroll normally.
- Cold-launch iPhone with notch or Dynamic Island: no REDACTED title under the time, and entire dossier plus bottom loading meter visible.
- Settings age: tap Edit, change option, Cancel (old remains); Edit again and Save (new profile persists).

## Version 1.1 / Build 13 — Custom detective, snippet cosmetics, 2-player racing, Friends

### Detective customization and shop
- My Detective and Shop are accessible from HQ. The existing rank-based six identity portraits remain.
- Four independently equipped cosmetic slots: **headwear, eyewear, badge and outfit**. 15 items have rank thresholds from 1 to 20, with different icon/tint treatments on the detective portrait. All rank thresholds are achievable within the 100-level campaign.
- Players buy **snippets with coins**, save them in their wallet, then spend snippets on eligible permanent cosmetic unlocks. Current packs: 1 for 55 coins, 5 for 250, 12 for 540.
- Alternatively, unlock an eligible cosmetic instantly with **crystals** at item-specific costs of 2–10. Crystals never bypass the rank requirement, just the snippet collection requirement.
- Ownership, snippets and equipped cosmetics are persisted in the existing CampaignProgress and private iCloud save. Wallet spending is transactional locally, not server-authoritative.

### Multiplayer and friends
- Two-player **invite-only** room; host makes a 6-character room code, shares a QR code or iOS link `redacted-detective://join/CODE`. Opening the link in the installed app navigates to the room and starts matching. A second player can type the code or use the in-app camera scanner (also works on iPad 6).
- A separate catalog generates **exactly 1,000 deterministic case combinations**: 20 settings × 10 missing objects × 5 methods, with three common clue steps. The same random seed is sent to both players. The match does **not** affect campaign level progression or personal stars.
- Each detective races to solve evidence selection, evidence code and suspect access. Incorrect guesses receive a three-second penalty. The first submitted correct finish as ordered by CloudKit record creation time is the winner.
- **Friends**: anonymous 8-character shareable friend codes, request/accept flow, friend list, and an ONLINE indicator based on a recent opt-in heartbeat. No player-entered public names, search, messaging, proximity tracking, or chat.
- Social features use CloudKit **public database records** rather than a custom server. Room, invitation, friend request, and presence metadata is potentially readable by other app users; only pseudonymous random codes and short generated labels are placed there.
- Existing private CloudKit account save is separate. Social presence starts only after visiting Friends or Multiplayer.

### Online setup required before functional release
The Xcode simulator CI checks **compilation only**. Online matches / presence **cannot work** without activating iCloud/CloudKit for `iCloud.com.UtilityFreak.Redacted` in Apple Developer, then setting up and deploying the **public CloudKit schema** and correct creator/public read permissions. Data types are: `RDRoom`, `RDJoin`, `RDFinish`, `RDPlayer`, `RDFriendRequest`, `RDFriendAccepted`. Fields use the string names in `MultiplayerService.swift`. Add a **query index** to `RDFriendRequest.recipient` for receiving requests. Grant public read and authenticated create; updates are performed by each record's owner.
- No custom backend has been provisioned. Cross-device multiplayer/friend flows remain **unverified** until tested on at least two real iCloud-enabled signed Apple devices using production CloudKit schema.
- This CloudKit public-record MVP is not tournament-grade: final answer validation happens on clients, and host controls room creation. For a public competitive launch, implement server-verified solve steps, anti-cheat, moderation/rate limiting, account/device identity, push/liveness handling, and secure prize distribution.
- No player-to-player currency staking or wagers. The game has no contact discovery, chat, or public lobby.
- The custom URL scheme works only after the app is installed. For links that install the game and then automatically resume a room, an associated-domain Universal Link backend and deferred deep linking would be needed; those are **not implemented**.

### Test cases
- Buy snippet pack, close/reopen app, verify balance; unlock cosmetics at eligible ranks via snippets and via crystals, equip/unequip, verify iCloud snapshot includes them.
- On two signed iOS devices with CloudKit configured, create room, enter code, QR-scan, verify both see same mystery and first valid completion wins; repeat after network interruption and app background/resume.
- Invite friends by shareable friend code, accept, refresh; check online status stops showing after heartbeat expires, with no private Apple IDs displayed.
- Test iPadOS 17 scanner and iOS 18+ QR deep link. Test 1,000 generated case indices for uniqueness and accessible answers. Check Store privacy disclosure and child-facing social feature compliance.

### Account portability
The player's anonymous 8-character detective friend code and accepted friend list are also fields of the campaign save. When the *same* account's private iCloud save is restored, the code and list can follow to the next device. Do not play or make new friends before initial iCloud restoration completes; CloudKit private sync and social rooms must be provisioned first. Using multiplayer on two devices concurrently under one friend identity is not supported.

## Version 1.2 / Build 14 — complete detective wardrobe art overhaul

- Replaces the previous floating SF Symbol character accessories with an **original unified SwiftUI Canvas vector illustration**. Headwear sits on the skull, glasses sit at eye level, badges are pinned to the right lapel, and outfits actually recolor/redesign the torso and coat. Every item is drawn in the exact same coordinate system at any preview size.
- The visual is authored entirely as geometry in `DetectiveAvatarArt.swift`; no externally sourced or copyrighted avatar image dependencies.
- Existing cosmetic IDs, rank gates, snippet and crystal prices, purchases, owned items, and equipped slots are retained. No user progress wipe or currency reset.
- Six rank identity portraits, the Home rank chip, the Profile and the Wardrobe all share the new illustration system instead of incompatible portrait styles.
- Redesigned Style Lab: prominent centered live try-on, four organized category tabs, two-column item preview cards, purchase confirmation, clear owned/equipped/locked states, and a collapsible snippet exchange.
- Adds five selectable **free skin tones** and four **free hairstyles**. Saved as `skinStyle` and `hairStyle` in backward-compatible `CampaignProgress` Codable fields; retained across relaunches and included in the existing iCloud save.
- **XP and coins are strictly independent balances:** XP can increase rank but can never be spent for cosmetics; coins are spent on snippets, which unlock cosmetics. Existing `CampaignStore.complete` calculates XP and coins independently and credits each into separate fields. The Profile shows Total XP and Coins as separate HUD values.
- The App Store iOS/iPadOS 17 compatibility target is unchanged and the iPad 6 remains supported.

### Character QA
1. Equip each of the four cosmetic slots and inspect the same character in Style Lab, Home, and Profile. Verify no floating SF Symbol accessories are left and all layers stay aligned on compact iPhone and iPad screens.
2. Preview a locked or unowned item; confirm preview does not unlock it or change any balances.
3. Purchase snippets with coins: confirm coins decrease, snippets increase, and XP/rank are unchanged.
4. Spend snippets or crystals on a cosmetic: confirm the item becomes permanently owned and auto-equipped without changes to XP/rank.
5. Equip/unequip previously owned items, reopen the app, and verify appearance and balances persist; verify the new skin/hair fields survive a private iCloud restoration on another signed device.
6. Check existing 1.1 save migration (no skin/hair keys) defaults to Peach/Classic, with all existing cosmetic IDs still valid.

## Version 1.3 / Build 15 — Proportions, wardrobe spacing and consistent currency cards

- Rebalances the character illustration by scaling the **entire head, ears, hair, eyes, glasses and hats together** to 82% width / 84% height around the neck/collar, and broadening the coat shoulders. All items keep exactly the same permanent IDs, ownership, rank requirements, prices, and anchor positions relative to the head.
- A reusable `GameCurrencyChip` standardizes icon footprint (30pt), padding, typography and 61pt card height. Coins always use REDACTED's custom `CoinIcon`, crystals use `CrystalIcon`, and XP/snippets/stars/hints use consistently sized symbols.
- Detective Profile: fixed two-column/three-row grid with XP, coins, crystals, snippets, free hints, and stars. Eliminates the uneven three-chip row and spacing hacks.
- Style Lab: fixed two-column currency grid, 2×2 category picker with normal-size icons and touch targets, 215pt preview, and tighter spacing. Small displays no longer squash four balance boxes into a single row.
- All existing XP and coin data remains separate and unchanged; this is a visual-only overhaul without a save migration.

QA: verify character anatomy and hat/eyewear alignment, the wardrobe's two-column balances, full-width two-column Profile stats, and correct original coin icon on real iPhone and iPad.

### Build 16 — Detective character proportion correction

- Corrects the oversized coat relative to the detective's head. Enlarges the head and *all attached headwear/eyewear together* from 0.82×0.84 to 0.88×0.90, preserving all attachment points.
- Narrows the shoulder silhouette, vest, shirt opening and both lapels together rather than adjusting the coat outline alone. Sleeve seams and the Ghost/Royal coat details move inward with the new body geometry.
- Moves the chest badge inward onto the new lapel (194, 258).
- No changes to owned/equipped cosmetics, rank requirements, coin/XP wallets, gameplay, or save formats.
- QA: inspect character at 48, 78, 122 and 215 points with all four headwear options, eyewear options, and the different coat styles on iPhone and iPad.

## Version 1.4 / Build 17 — Friends primary tab & online presence UX

- The main app now has a consistent bottom navigation with **Home, Multiplayer, and Friends**. Friends is a primary tab, not a buried Home shortcut. Tab switches reset only navigation history; all case navigation, deep links, saves, and active multiplayer session state remain intact.
- Online friends appear in the dedicated **ONLINE NOW** section above offline friends. Large green status, clear count, and a PLAY shortcut to the Multiplayer lobby make it easier to see who can play.
- Friend requests are displayed above the list with a prominent ACCEPT control.
- An at-a-glance header shows online and total friend counts; friend code entry lives in a focused **Add Friend** sheet. Sharing/copying your 8-character personal code remains available.
- Automatic presence checks every 40 seconds **only while the Friends tab is visible**, plus swipe-to-refresh, a manual refresh control and refreshing again when foregrounded. Presence reports online for recent activity (105-second threshold).
- A cloud fetch failure is shown as **STATUS UNAVAILABLE**, not falsely as OFFLINE.
- All existing social IDs, accepted friends, friend requests, private CloudKit save data and multiplayer room codes are retained. No reset or wallet changes.
- Playing together still requires the public CloudKit schema and entitlement setup described above; clicking PLAY opens the existing invite-based multiplayer lobby to create and share a room.
- iPhone/iPad: check bottom-tab placement, safe-area spacing, friend-code sheet entry, large online/offline indicators, and return to case after navigating away from tabs.

## REDACTED 1.5 — Build 18: Task Forces, sliding tabs, cosmetics, and 1v1 emotes

- Social now uses an independent account-backed Friends/Task Forces network rather than requiring iCloud. Supabase Auth, Postgres SQL and client-side code are included. The network remains visibly **unconfigured** until a real Supabase project is connected. Full activation guide: [Backend/SOCIAL_SETUP.md](Backend/SOCIAL_SETUP.md).
- Invite-only **Task Forces** support a name, eight-character squad code, 20 members, leader transfer, and online presence. A detective belongs to one squad.
- The compact Social page replaces the oversized Friends cards with an online-first contact list, a short invitation strip, and a Task Force segment.
- The bottom Home/Duels/Social bar now has a spring-sliding gold selector, contiguous tab track and safe-area background, eliminating the odd gap and Liquid Glass styling. Horizontal swipes can switch pages except during a live duel.
- The original avatar head/coat ratio is rebalanced with a wider face relative to the shoulders while accessories continue to use the same anchors.
- **39 illustrated cosmetics** total (24 new), with actual drawn variation in all four equipment slots. Prices/ranks/previous ownership and saves are retained.
- **Eight preset emotes** only in active 1v1 matches, with a five-second cooldown, opponent display, and local mute. CloudKit requires a new \`RDEmote\` record type for live delivery.
- The independent Friends backend requires manual Supabase provisioning: social networking is **not live from the GitHub code alone**. Existing 1v1 CloudKit matchmaking is still a separate service and is not migrated by this patch.
- Anonymous accounts do not require Apple/iCloud but are device-bound until a later account-linking/recovery feature. Never ship a Supabase secret or service-role key inside the app.
