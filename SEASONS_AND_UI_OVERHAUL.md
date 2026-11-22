# Redacted — Chapter / Season System (first implementation)

## What is implemented

- Season HQ is reachable from the home screen. It has a live countdown, chapter/season numbering, upcoming deployment notice, real seasonal Intel and case/star activity.
- The shared `Art` palette, background, home tiles and navigation accent respond to the season. Existing manually selected detective backdrop preferences are preserved.
- Season changes are calculated at explicit **UTC** calendar boundaries. A main-run-loop timer handles the rollover while the app is active, and `scenePhase == .active` reconciles the season after backgrounding.
- A **DEBUG-only** "Preview next season" control in Season HQ switches the visual theme locally and can switch back. It cannot publish a season or affect other players. Next-season example text exists only in `#if DEBUG` builds.
- Completed cases add +10 Intel and +5 per star to the active season. Stored under a season-specific UserDefaults key; existing `CampaignProgress` and cloud-save structures are unchanged.
- The home screen was reprioritized to highlight Season HQ and the next case, while the global cards and backdrop gained a subtler, consistent visual system.

## Set the official season schedule before releasing

In `Redacted/Game/SeasonDirector.swift`, change `SeasonCalendar.epoch` to the intended **Chapter 1 Season 1 starting instant in UTC**. Currently **November 1, 2026 00:00 UTC** is a development example.

The current implementation rotates **every two UTC calendar months**, with four seasons per chapter. Change the `2` month interval and `index / 4` chapter progression if the desired live-ops plan differs.

Real next-season names, story beats, and assets have **not** been shipped; beyond the opening season, the public label remains `CLASSIFIED OPERATION` until those are authored.

## Security and deployment limitations

**No client-bundled secret is leakproof.** Future artwork, cosmetics, titles and files should not be included in public releases until their embargo ends. DEBUG-only previews prevent accidental release of preview UI, but are not a substitute for an authenticated **private staging backend** for unreleased content. Ship the release assets at launch from a server or via an App Store update.

The UTC schedule is device-clock-based at present: it provides a reliable presentation transition under normal conditions but **not a server-authoritative simultaneous launch** when phones' clocks differ or are intentionally changed. Server time and signed published manifests should govern competitive rewards, public purchases, and sensitive time-limited events.

Seasonal Intel is currently **device-local** and is not paid currency or part of cross-device cloud saves. Do not advertise purchasable season passes or transferable rewards until they have backend-enforced entitlement and synchronization.

## QA checklist

1. Build and launch on an iPhone simulator and iPad simulator.
2. Open **Season HQ** from Home. Verify countdown, season numbering, live activity and UTC date format.
3. Complete a case. Confirm seasonal Intel, cases and stars increase. Verify normal case coins, crystals, best stars and cloud-save behavior are unchanged.
4. On a DEBUG build, preview the next season: home screen, case screen, wardrobe, duels and social should use the alternate accent; the season preview banner must be visible. Return to live.
5. Release build must not contain the developer preview control or the development-only next-season title.
6. Change the simulator clock across a boundary while the app is backgrounded; on foreground verify the correct season and reset seasonal activity. Repeat with the app open.
7. Verify Dynamic Type, VoiceOver, reduced motion, narrow iPhone layouts and iPad landscape.

## Next production steps

A proper full-game overhaul should then refine mission illustrations and animations, seasonal cosmetics, reward tracks and content operations. None of these are presented as already implemented. Before public live-ops launch, add a signed server schedule and private asset staging so seasons can be authored and released without distributing spoilers in advance.
