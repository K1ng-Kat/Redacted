# REDACTED

A native, narrative-driven detective game for iPhone built with SwiftUI.

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
