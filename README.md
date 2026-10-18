# REDACTED

A native, narrative-driven detective game for iPhone built with SwiftUI.

## 0.3 — Playable guided game redesign

The previous five-tab desk was too confusing. The default player experience has been rebuilt from scratch:

- **One home screen and one big PLAY button**
- **Four illustrated locations** with exactly two tappable hotspots each
- **Clue reveal screens** with the original evidence and one-sentence explanation
- **Three illustrated suspect interviews**, presented as direct question/answer conversations
- **Two deduction puzzles** after you finish investigating
- **A final culprit choice** and three-star case summary
- **Always-visible task instruction**, in-context HELP, persistent progress and automatic resume at the first unfinished chapter
- Original vector room art and portraits bundled in code, animated press states, tactile feedback, a clear chapter tracker, and strong hierarchy

The existing story, evidence, progress storage and game logic remain intact.
Old UI files remain in the repository for now but are no longer reachable from the app.
This is still a handcrafted solo mystery, not an online multiplayer game.

### Quick validation on iPhone
1. Tap PLAY. Only the two yellow hotspots in the room should demand attention.
2. Collect both clues, tap NEXT LOCATION, and repeat for four locations.
3. Interview all three characters by asking at least one question each.
4. Solve the two evidence-based choices, accuse the culprit and view the case result.
5. Force-quit during a case, reopen and ensure PLAY resumes at the next unfinished chapter.
6. Restart Case 001 in Settings and verify that the case starts from the vault again.

An actual iPhone/Xcode compile and hands-on usability pass are still required.


## 0.2 — Game-feel overhaul

A new original art direction focused on tactile mobile-game polish: a custom vector vault illustration, deeper color and lighting, extruded animated buttons, prominent mission navigation, animated clue and deduction rewards, earned Agent XP, redesigned suspect interviews, and a one-to-three-star case conclusion. This is not a clone of another game's art or interface.

Agent XP is derived from real case progress (25 per clue, 40 per interviewed suspect, 80 per solved deduction, and 150 for closing the case). Scores are reproducible across launches, with no network or microtransactions.

The first playable investigation remains intact; progress saves continue using the original key and data model.


## Version 0.1 — Case 001: The Missing Archive

The first playable single-player case takes place at Northpoint Research, where a confidential drive disappears during a six-minute surveillance blackout.

### Current gameplay

- A fully navigable classified-file home screen and Case Archive
- Four locations with eight discoverable evidence records
- Three suspects with six interactive interview prompts
- Two evidence-gated deduction challenges
- A final accusation with meaningful success/failure states
- A case conclusion and timeline reconstruction
- Automatic local save/resume and a reset option
- Optional iPhone haptics

There are no online features yet. Multiplayer, accounts, matchmaking, procedural cases, achievements, audio and additional episodes are future work, not present-day capabilities.

## Getting started

1. Open \`Redacted.xcodeproj\` in Xcode.
2. Select the shared \`Redacted\` scheme.
3. Select an iPhone running iOS 18 or later (device or simulator).
4. Build and run with Cmd-R.

The app uses only Apple system frameworks and bundled Swift code. No API keys, server, user account, paid assets or third-party dependencies are required.

### Code layout

- \`Redacted/RedactedApp.swift\`: App entry
- \`Redacted/ContentView.swift\`: Root navigation
- \`Redacted/Game/CaseData.swift\`: Case content and rules
- \`Redacted/Game/InvestigationStore.swift\`: State, validation and persistence
- \`Redacted/UI/Noir.swift\`: Visual design system
- \`Redacted/UI/HomeView.swift\`: Home, archive, settings
- \`Redacted/UI/InvestigationView.swift\`: Investigation, evidence, interviews, deductions, ending

The project uses Xcode's file-system-synchronized group: newly added Swift source files in \`Redacted/\` are included in the app target automatically.

### Xcode Cloud

A shared \`Redacted\` scheme is checked in at \`Redacted.xcodeproj/xcshareddata/xcschemes/Redacted.xcscheme\`. Select it when creating the Xcode Cloud workflow. Code signing remains configured with the existing team's settings.

### Suggested manual QA

1. Start Case 001 and discover all eight evidence files.
2. Ask at least one question to every suspect.
3. Verify that deduction answers cannot be submitted before the required evidence is collected.
4. Submit incorrect deduction answers and retry.
5. Solve both deductions, accuse the wrong suspect, and then accuse Jules Hart.
6. Leave the app and reopen to verify progress persists.
7. Reset progress in Settings and verify the case is fresh.

This is a first playable prototype. iOS/Xcode build verification must be performed on a Mac or Xcode Cloud; it is not included as a passing test claim.

## Creative direction

No combat, no cards, no towers, and no arena combat. The core is observation, interactive fiction, deduction, and eventually social deception in online multiplayer.
