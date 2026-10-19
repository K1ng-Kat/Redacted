# REDACTED ID — passwordless email-code sign-in

This implements a **Supercell ID-style experience** with REDACTED's own
branding and account identity. It is not affiliated with Supercell. It uses
Supabase Auth's securely verified email OTP, Supabase Postgres, and a
configurable transactional SMTP provider. **No Apple ID or iCloud is required.**

## Account flow

1. In Settings → REDACTED ID or Social, enter an email address.
2. Receive a six-digit one-time verification code by email.
3. Type the code in the iPhone app. The server verifies it (the app never holds
   a verifier/OTP secret).
4. REDACTED ID saves the social identity, Task Force, friends and a private
   campaign backup. On a new device, enter that same email and a new code.
5. If the server has a campaign backup, choose **Restore Account Progress** or
   **Keep This Device's Progress**. Balances are never added together.
6. Sign out preserves this device's campaign. Delete account is available
   from Settings for complete online account removal.

## REQUIRED before sign-in emails or online matches work

This GitHub repository contains app code and SQL, but there is currently **no
live Supabase server, email delivery service, or database provisioned by this
commit**. You must:

1. Create a Supabase project you control.
2. Enable **Auth → Providers → Email**, including email OTP/passwordless.
   Disable anonymous sign-ins if not needed; Apple sign-in is not used.
3. Under Auth → Email Templates, edit **Magic Link / OTP** with the HTML from
   [REDACTED_OTP_EMAIL.html](REDACTED_OTP_EMAIL.html) so email contains
   \`{{ .Token }}\`. Without this template, Supabase may send a *magic link*
   rather than the six-digit code the app expects.
4. Configure OTP length to **6 digits**, expiration (recommended 10 minutes),
   and resend/rate limits (at least a 60-second resend interval).
5. Connect a verified transactional email domain and custom SMTP provider for
   deliverability, domain SPF/DKIM, and volume beyond test email limits.
   **Keep SMTP API keys/passwords on the server, never in the app or GitHub.**
6. Run these SQL migrations in this exact order in the project's SQL editor:
   - \`Backend/supabase_social.sql\` — Friends and Task Forces
   - \`Backend/account_saves.sql\` — private revision-checked campaign saves
   - \`Backend/duel_rooms.sql\` — server-verified 1v1 rooms and preset emotes
7. Add the **project URL** and **publishable (public) anon key** to
   \`RDSocialProjectURL\` and \`RDSocialPublishableKey\` in
   \`Redacted-Info.plist\`. Never add the service_role/secret key to Xcode,
   Info.plist, or GitHub.
8. Rebuild the app. Test with TWO distinct verified email accounts, on TWO
   devices, on your project. Check:
   - First verification creates a code and profile.
   - Same email on device 2 restores the same Social identity and Task Force.
   - Friend request → accept, online presence, Task Force join by code.
   - Campaign save upload, restore on device 2, and explicit account conflict
     choice after making offline progress on two devices.
   - Duel code/QR deep link, same seed for both players, server-verified finish,
     emotes and mute.
   - Sign out doesn't erase local levels; delete account removes online data.

**Important:** The server has no public email search or chat. Social tables have
RLS enabled and deny direct authenticated read/write. All RPCs obtain user
identity from \`auth.uid()\`, and campaign writes require expected save revision.
Game-currency fraud prevention for public scale also requires server-authoritative
reward issuance, anti-abuse monitoring, moderation and backup recovery tests.

## Privacy, age, and production considerations

- Email is private authentication data, not visible in other players' profiles.
- No exact age, birth date, address, location, contacts, or messages are
  collected by the Friends/Task Forces screens.
- Allow users to sign out and delete their accounts.
- For a game offered to children or teens, configure age-appropriate privacy
  notices, account data retention, parent/guardian considerations where
  required, and avoid exposing unsolicited communication or personal details.
- A successful Swift build confirms **compilation only**, not outbound email
  delivery or Supabase integration.
- This is passwordless verification, not a self-hosted authentication server.
  Supabase Auth validates codes and maintains the user sessions; REDACTED owns
  the user experience and its game account data.
