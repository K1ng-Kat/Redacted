# REDACTED Detective Network — deploy the account backend

The new **Friends / Task Forces** system is independent of iCloud and uses
**Supabase Auth + PostgreSQL**. The iOS app has been built and configured to
disable network actions until this service is explicitly connected.

## Activate (requires a Supabase project)

1. In your own Supabase account, create a project for REDACTED.
2. Under **Authentication → Providers → Anonymous**, enable anonymous
   sign-ins. Consider CAPTCHA, account creation limits and abuse monitoring.
3. In **SQL Editor**, run the full migration in
   [supabase_social.sql](./supabase_social.sql).
   It creates the tables, private invite-only Task Force model, and access
   controlled RPC functions. Do not skip this step.
4. Copy **Project URL** and its **publishable/anon key** (client-safe only).
   Set these keys in the root \`Redacted-Info.plist\`:
   \`RDSocialProjectURL\` and \`RDSocialPublishableKey\`.
   **NEVER** put a \`service_role\` or Supabase secret key in the app.
5. Enable internet access for your devices and run \`red-sync\`, build/sign
   the iOS app. Visit **Social → Friends**. It will create a private anonymous
   authentication session in the iOS Keychain and show the detective code.
6. On a second device, sign in anonymously, add the friend's code, accept the
   request, and check presence. Create a Task Force on one device and join with
   its eight-character private invite code on the other.

**No Apple/iCloud login is required for these social features.** The existing
solo campaign/Apple account backups and existing CloudKit-hosted 1v1 matchmaking
remain separate features. **The 1v1 lobby and opponent emotes still depend on
CloudKit and require its public schema/capabilities**, including the new
\`RDEmote\` public record type with \`emote\` (String) and \`sentAt\` (Date)
fields. CloudKit production permissions must allow a player to create/update
their own record and public read for matched opponents.

## Account, safety and privacy notes

- The first iteration uses **anonymous Supabase Auth**. It persists its refresh
  token in the iOS Keychain and works without an email address or iCloud.
- **Important:** An anonymous account cannot be recovered on a new device or
  after losing its Keychain session. Social account migration, explicit sign-in
  and linking accounts will be a later feature. Your solo level progress is not
  tied to this social account. Supabase docs:
  https://supabase.com/docs/guides/auth/auth-anonymous
- Only pseudonymous friend codes, squad names, membership and activity
  timestamps are stored online. No chat, contacts, email, location, or friends
  directory is included.
- Invite-only Task Forces have a **20-member limit**; each detective can join
  one Task Force at a time. Leaders automatically transfer on departure.
- The app checks presence while Social is open; it never claims online status
  when disconnected. A detective is "online" if the last heartbeat is within
  105 seconds.
- PostgreSQL uses RLS and RPC-specific permissions. Do not turn on generic
  public table access. Test with two distinct accounts and review auth-rate
  limits before launching at scale.
- This code was not deployed to a live Supabase project as part of the GitHub
  source commit. A successful iOS build does not prove internet matchmaking.

## Troubleshooting

- "**Network not connected**": verify URL and publishable key in the signed
  app's Info.plist; verify SQL schema deployed and anonymous sign-ins enabled.
- "**Could not create your detective account**": check Supabase Auth logs,
  rate limiting, and iOS connectivity.
- "**Friend request not found**": both devices must register in the *same*
  Supabase project (not iCloud).
- "**Task Force code not found**": confirm the eight-character invite code,
  current membership, and that both clients use the same backend.
- If a CloudKit friend had previously been added in the **old** Friends screen,
  that old CloudKit friendship is not silently imported. The old campaign
  save data stays intact, but a new request must be sent in the social service.
