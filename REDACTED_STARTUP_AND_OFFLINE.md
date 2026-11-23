# Redacted launch screen, offline play and version checks

## What the game actually does

The **native iOS LaunchScreen storyboard is static**, and iOS owns the time before it hands control to the app. Redacted cannot put a working progress bar on that native screen. The first app-owned SwiftUI view is now `StartupLoadingView` (from `RedactedApp.swift`); the heavy campaign view and SceneKit characters are created only after it finishes.

The animated loading bar and number use the same interpolated value. Its milestones represent startup work: reading the local save, preparing the case catalog and checking bundled resources, then bounded connectivity and update verification. The bar can stay at about 64–76% while network work is pending rather than pretending progress.

When the network is unavailable or the update check fails, the loader presents **RETRY** and **PLAY OFFLINE**, not an endless spinner. Offline Mode is saved under `redacted.offlineMode`; turn it off in **More → Settings → Offline Mode** when connectivity returns.

Offline Mode supports locally saved cases, difficulty, cosmetic customization, and local progress. It pauses network initialization and presence. Duels and Social remain visible, with clear disabled/paused states, instead of disappearing.

## Live update policy

`Live/startup.json` is a publicly accessible no-secret startup manifest, delivered over HTTPS through the project's GitHub raw URL configured as `RDStartupManifestURL` in `Redacted-Info.plist`.

Example:

```json
{
  "minimumBuild": 19,
  "message": "A newer Redacted version is needed for online play.",
  "appStoreURL": null
}
```

When a genuine newer App Store version exists, set `minimumBuild` to that new integer **CFBundleVersion** and `appStoreURL` to its verified `https://apps.apple.com/...` product URL. Do not guess an App Store URL. If the returned minimum build exceeds the installed build, show an update notice and App Store link when provided. The app still permits offline single-player investigations.

The GitHub raw endpoint may be cached briefly and is not a transactionally accurate, real-time multiplayer backend. Do not use it to secure paid entitlements or competitive rewards. The startup verifier times out and offers Offline Mode if GitHub is unavailable. Offline play also works when no internet or no manifest can be fetched.

## QA that must be performed on real hardware

1. Cold-launch Redacted from the home screen after force-quitting, with Xcode debugger detached; confirm the native static screen hands off to the loader promptly.
2. Watch the bar and numeric percentage from 0 to 100, with a smooth animation and no second loading screen.
3. Enable airplane mode before launch: loader pauses at connection check and offers **Retry** and **Play Offline**.
4. Choose Play Offline: Cases, Style Lab, Settings, progress and music work. Duels and Social remain visible, but no online requests are attempted.
5. Disable Offline Mode in Settings and reconnect: online features resume only when the configured backend supports them.
6. For a private test build, raise `minimumBuild` above the installed build: the loader shows the update requirement; revert the test manifest before shipping.
7. Test bad Wi-Fi, captive portals, slow responses, a downed update endpoint, and app return from background.
8. Check navigation on small and large iPhones and iPads: Home, Cases, Duels, Social, More; More includes Settings, Profile, Style Lab, Guide and Season HQ.
9. Test all four cosmetic slots: selecting items visibly changes the preview; equipping and unequipping changes the saved avatar; no item consumes currency until confirmation.

A successful simulator build checks compilation, **not physical cold-launch latency, UI appearance, or realistic 3D character quality**. Use Xcode Instruments' App Launch template to distinguish OS launch time from game initialization if the static LaunchScreen persists on device.
