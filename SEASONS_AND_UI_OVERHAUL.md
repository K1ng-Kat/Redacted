# REDACTED — Season & Release Behavior

## Player experience

- The game's first season is Chapter 1 / Season 1 and tracks locally earned case Intel.
- Each completed case adds 10 Intel plus 5 for each earned star. This is a progress record, not a paid currency.
- Home shows the current operation, next case, real campaign progress, and case/style shortcuts.
- **The game does not show a fabricated countdown or invented next-season date.** The next season remains classified until a genuine schedule is shipped.
- Single-player progress stays on the device. Without an enabled account backend, the app clearly says cross-device backup is unavailable and the main tabs offer Home / Cases / Style.
- When the account backend has valid configuration, the main tabs offer Home / Duels / Social instead.

## Publishing the season schedule

`Redacted-Info.plist` exposes an optional key called `RDSeasonLaunchUTC`. Leave it empty until an actual launch date is decided and published. To enable the calendar, enter a UTC ISO-8601 timestamp such as `2027-01-01T00:00:00Z` **only if that is the intended official release instant**.

The calendar currently rotates every two UTC calendar months, four seasons per chapter. A time boundary refreshes the palette while the app is open and when returning from the background. Each future season must have approved release content before going live. Changing the native schedule/key still requires shipping a new app version. To publish content without app updates, implement a signed server-driven manifest and secure asset delivery.

Important: A device clock is not trusted for purchases, multiplayer rewards, or rankings. Those require server-authoritative time.

## No hidden developer preview

The earlier developer preview and its simulated next-season title are removed from the app. No unreleased art or scripts are bundled. Future confidential development content belongs behind a properly authenticated staging server or in a private internal build rather than in the public codebase.

## Release gate — remaining work

- Configure and test the Supabase project URL, **publishable** client key, SQL policies, email-code authentication, account deletion, data synchronization, and private duels **before advertising online features**. Never ship a service-role or secret key in a client.
- Verify purchases and cloud backup only when their backend enforcement is complete. The current season Intel is device-local.
- Test on actual small/large iPhones and an iPad: onboarding, first case, 100-case navigation, campaign save/restore, rotations, touch targets, Reduce Motion, VoiceOver, and online error states when available.
- Review App Store privacy disclosures, content rating, music attribution/licensing, screenshots, age suitability, and metadata with the final implemented feature set.
- Run the iOS Debug and Release simulator builds and ensure the launch screen, Game Mode and camera permission text are correct.

Build verification is not a substitute for physical-device testing or App Review approval.
