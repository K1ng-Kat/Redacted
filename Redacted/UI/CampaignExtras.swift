import SwiftUI
import AuthenticationServices

struct CampaignSettingsView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void
    @ObservedObject private var cloud = CloudSaveManager.shared

    @AppStorage("redacted.fx.sound") private var sound = true
    @AppStorage("redacted.fx.haptics") private var haptics = true
    @AppStorage("redacted.fx.motion") private var motion = true
    @AppStorage("redacted.fx.hints") private var hints = true
    @AppStorage("redacted.age.mode") private var ageModeRaw = DetectiveAgeMode.investigator.rawValue
    @AppStorage("redacted.music.enabled") private var musicEnabled = true
    @AppStorage("redacted.music.menu.volume") private var menuVolume = 0.55
    @AppStorage("redacted.music.level.volume") private var levelVolume = 0.12
    @State private var confirmingReset = false
    @State private var showingAgeEditor = false
    @State private var draftAgeMode = DetectiveAgeMode.investigator.rawValue


    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: "SETTINGS", subtitle: "YOUR EXPERIENCE", back: back)
                GameCard {
                    VStack(spacing: 19) {
                        option("SOUND EFFECTS", detail: "Arcade-style taps and success tones",
                               symbol: "speaker.wave.2.fill", enabled: $sound)
                        Divider().overlay(Art.edge.opacity(0.30))
                        option("HAPTICS", detail: "Vibration for taps and completed cases",
                               symbol: "hand.tap.fill", enabled: $haptics)
                        Divider().overlay(Art.edge.opacity(0.30))
                        option("ANIMATIONS", detail: "Reduce button motion when disabled",
                               symbol: "sparkles", enabled: $motion)
                        Divider().overlay(Art.edge.opacity(0.30))
                        option("SHOW HINT BUTTON", detail: "2 free hints; then 2 crystals each",
                               symbol: "lightbulb.fill", enabled: $hints)
                    }
                }
                GameCard(accent: Art.cyan) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Art.cyan)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 4) {
                            GameKicker(text: "AGE & DIFFICULTY", color: Art.cyan)
                            Text((DetectiveAgeMode(rawValue: ageModeRaw) ?? .investigator).title)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(Art.paper)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        Spacer(minLength: 4)
                        Button {
                            GameEffects.shared.tap()
                            draftAgeMode = ageModeRaw
                            showingAgeEditor = true
                        } label: {
                            Label("EDIT", systemImage: "pencil")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Art.ink)
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                                .background(Art.cyan)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(PressGameStyle())
                        .accessibilityLabel("Edit age and game difficulty")
                    }
                }
                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 16) {
                        GameKicker(text: "BACKGROUND MUSIC", color: Art.gold)
                        Toggle(isOn: $musicEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Art.gold)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("MUSIC")
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .foregroundStyle(Art.paper)
                                    Text("Automatic looping music for menus and levels")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Art.faded)
                                }
                            }
                        }
                        .tint(Art.mint)

                        Divider().overlay(Art.edge.opacity(0.3))
                        volumeControl("MENU MUSIC", note: "Bossa Nova by Joth",
                                      value: $menuVolume, maximum: 1)
                        Divider().overlay(Art.edge.opacity(0.3))
                        volumeControl("LEVEL MUSIC", note: "Shop Theme by Cleyton Kauffman · quiet by default",
                                      value: $levelVolume, maximum: 0.45)
                    }
                }
                GameCard(accent: Art.cyan) {
                    VStack(alignment: .leading, spacing: 13) {
                        GameKicker(text: "ACCOUNT & CLOUD SAVE", color: Art.cyan)
                        HStack(spacing: 12) {
                            Image(systemName: cloud.signedIn ? "checkmark.icloud.fill" : "icloud")
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(cloud.signedIn ? Art.mint : Art.cyan)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(cloud.signedIn ? "APPLE ACCOUNT CONNECTED" : "SIGN IN TO SAVE")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.paper)
                                Text(cloud.status)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Art.faded)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        Text("Sign in with Apple to enable private iCloud backup of your progress, crystals, stars, detectives and settings. To restore on another device, sign in there with the same Apple and iCloud account.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        if cloud.signedIn {
                            HStack(spacing: 9) {
                                GameButton(title: cloud.syncing ? "SYNCING…" : "SYNC NOW",
                                           icon: "arrow.triangle.2.circlepath",
                                           color: Art.blueLight, bottom: Art.blueDeep,
                                           inactive: cloud.syncing) {
                                    Task { await cloud.syncNow() }
                                }
                            }
                            if let date = cloud.lastSynced {
                                Text("Last successful sync: \(date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Art.mint)
                            }
                            Button("SIGN OUT (KEEP LOCAL SAVE)") { cloud.signOut() }
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(Art.gold)
                                .frame(minHeight: 44)
                                .buttonStyle(PressGameStyle())
                        } else {
                            SignInWithAppleButton(.signIn, onRequest: { request in
                                request.requestedScopes = []
                            }, onCompletion: { result in
                                cloud.handleSignIn(result)
                            })
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Cloud sync needs iCloud enabled for REDACTED. A sign-in alone does not mean a backup has completed.")
                            .font(.system(size: 11))
                            .foregroundStyle(Art.faded)
                    }
                }
                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 11) {
                        GameKicker(text: "CRYSTALS & HINTS", color: Art.gold)
                        HStack(spacing: 13) {
                            CrystalIcon(size: 53)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(store.crystals) CRYSTALS")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(Art.paper)
                                Text("\(store.hintTickets) free hints remaining")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Art.faded)
                            }
                        }
                        Text("Pass all 10 levels and earn at least 7 perfect 3-star ratings in a district to earn 1 crystal. Hints cost 2 crystals after your 2 starting free hints are used.")
                            .font(.system(size: 12))
                            .foregroundStyle(Art.faded)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                GameCard {
                    VStack(alignment: .leading, spacing: 11) {
                        GameKicker(text: "PRIVACY AND SAVES", color: Art.cyan)
                        Text("Progress is always saved locally. Optional iCloud backup uses your private Apple iCloud account when available; it is not a custom REDACTED server.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("REDACTED 1.0 — iPhone & iPad campaign")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Art.faded)
                    }
                }
                GameButton(title: "ERASE CAMPAIGN SAVE", icon: "trash.fill",
                           color: Art.coral, bottom: Art.coralDark) {
                    confirmingReset = true
                }
                GameButton(title: "DONE", icon: "checkmark", action: back)
                appInfo
            }
            .frame(maxWidth: 560)
            .padding(18)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .sheet(isPresented: $showingAgeEditor) {
            ageProfileEditor
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: "\(sound)|\(haptics)|\(motion)|\(hints)|\(ageModeRaw)|\(musicEnabled)|\(menuVolume)|\(levelVolume)") { _, _ in
            cloud.settingsChanged()
        }
        .confirmationDialog("Delete your 100-level campaign progress?",
                            isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Erase levels, coins, XP and rewards", role: .destructive) {
                store.resetProgress()
                back()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This resets your local levels, crystals, coins, free hints and rank. If cloud sync is enabled, the reset may also sync to iCloud.")
        }
    }

    private var ageProfileEditor: some View {
        ZStack {
            GameBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        GameTitle(text: "EDIT GAME DIFFICULTY", size: 25)
                        Spacer()
                        Button("CANCEL") {
                            showingAgeEditor = false
                        }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Art.cyan)
                        .frame(minWidth: 64, minHeight: 44)
                    }
                    Text("Choose the reading and puzzle level you want. Nothing changes until you tap Save.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(DetectiveAgeMode.allCases) { mode in
                        Button {
                            GameEffects.shared.tap()
                            draftAgeMode = mode.rawValue
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: draftAgeMode == mode.rawValue
                                      ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 23, weight: .bold))
                                    .foregroundStyle(draftAgeMode == mode.rawValue ? Art.mint : Art.cyan)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(mode.title)
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .foregroundStyle(Art.paper)
                                    Text(mode.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Art.faded)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(13)
                            .background(draftAgeMode == mode.rawValue ? Art.blueLight : Art.blueDeep)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15)
                                .stroke(draftAgeMode == mode.rawValue ? Art.gold : Art.edge,
                                        lineWidth: draftAgeMode == mode.rawValue ? 2 : 1))
                            .contentShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(PressGameStyle())
                    }
                    Text("Your exact age is not stored or sent to the developers. Only your selected difficulty profile is saved on this device.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                    GameButton(title: "SAVE DIFFICULTY", icon: "checkmark") {
                        ageModeRaw = draftAgeMode
                        showingAgeEditor = false
                        GameEffects.shared.success()
                    }
                }
                .frame(maxWidth: 500)
                .padding(18)
                .padding(.bottom, 22)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var appInfo: some View {
        GameCard(accent: Art.edge) {
            VStack(alignment: .leading, spacing: 13) {
                GameKicker(text: "APP INFO & CREDITS", color: Art.cyan)
                HStack {
                    Text("REDACTED")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    Spacer()
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "12"))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Art.faded)
                }
                Divider().overlay(Art.edge.opacity(0.3))
                GameKicker(text: "MUSIC CREDITS", color: Art.gold)
                creditRow(
                    title: "Bossa Nova", artist: "Joth",
                    use: "Main menu",
                    url: "https://opengameart.org/content/bossa-nova"
                )
                Divider().overlay(Art.edge.opacity(0.3))
                creditRow(
                    title: "Shop Theme", artist: "Cleyton Kauffman",
                    use: "In-game levels",
                    url: "https://opengameart.org/content/shop-theme"
                )
                Text("Both tracks are published under CC0 1.0 (public-domain dedication).")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
                Link(destination: URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!) {
                    Label("VIEW CC0 LICENSE", systemImage: "arrow.up.right.square")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Art.cyan)
                }
                Text("Game: REDACTED. Thanks to the creators who release their music for independent developers.")
                    .font(.system(size: 11))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func creditRow(title: String, artist: String, use: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Spacer()
                Text(use)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Art.faded)
            }
            Text("Music by \(artist) · CC0")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Art.faded)
            if let destination = URL(string: url) {
                Link(destination: destination) {
                    Label("TRACK SOURCE", systemImage: "arrow.up.right.square")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Art.cyan)
                }
            }
        }
    }

    private func volumeControl(_ title: String, note: String, value: Binding<Double>,
                               maximum: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Art.gold)
            }
            Slider(value: value, in: 0...maximum)
                .tint(Art.gold)
                .disabled(!musicEnabled)
                .accessibilityLabel(title)
            Text(note)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Art.faded)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func option(_ title: String, detail: String,
                        symbol: String, enabled: Binding<Bool>) -> some View {
        Toggle(isOn: enabled) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Art.gold)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Art.mint)
    }
}

struct CampaignGuideView: View {
    let back: () -> Void
    let begin: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: "HOW TO PLAY", subtitle: "LEARN IN 30 SECONDS", back: back)
                instruction("1", "READ THE CASE", "Each level starts with a tiny mystery and one clear objective.",
                            symbol: "doc.text.magnifyingglass", color: Art.cyan)
                instruction("2", "TAP, THINK, SOLVE", "Look for hidden objects, arrange events, decode words and solve puzzles using evidence.",
                            symbol: "hand.point.up.left.fill", color: Art.gold)
                instruction("3", "EARN YOUR STARS", "A wrong answer ends the attempt. Finish without mistakes or hints to earn 3 stars.",
                            symbol: "star.fill", color: Art.mint)
                instruction("4", "LEVEL UP", "New cases award coins and XP. Later detective identities require more XP and come with new looks.",
                            symbol: "rosette", color: Art.coral)
                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 9) {
                        GameKicker(text: "HINT ECONOMY", color: Art.gold)
                        Text("You start with 50 coins and 2 free hints. Each new rank gives coins and another hint. Hints cost 30 coins after tickets run out, and reduce your star rating.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Art.paper)
                    }
                }
                GameButton(title: "LET'S PLAY", icon: "play.fill", action: begin)
            }
            .frame(maxWidth: 580)
            .padding(18)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
    }

    private func instruction(_ number: String, _ title: String, _ description: String,
                             symbol: String, color: Color) -> some View {
        GameCard(accent: color) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(Art.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 7) {
                    Text("\(number). \(title)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Art.faded)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct CampaignStatsView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void
    let customize: () -> Void
    @AppStorage("redacted.profile.theme") private var selectedTheme = "midnight"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: "DETECTIVE PROFILE",
                             subtitle: "LEVELS · COINS · REWARDS", back: back)

                rankHero
                GameButton(title: "CUSTOMIZE CHARACTER", icon: "paintbrush.fill", action: customize)
                // 2×3 grid: same currency artwork and aligned icon slots as Style Lab.
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    GameCurrencyChip(kind: .xp, amount: store.accountXP)
                    GameCurrencyChip(kind: .coins, amount: store.coins)
                    GameCurrencyChip(kind: .crystals, amount: store.crystals)
                    GameCurrencyChip(kind: .snippets, amount: store.snippets)
                    GameCurrencyChip(kind: .hints, amount: store.hintTickets)
                    GameCurrencyChip(kind: .stars, amount: store.totalStars)
                }
                GameCard {
                    VStack(alignment: .leading, spacing: 10) {
                        GameKicker(text: "HOW REWARDS WORK", color: Art.gold)
                        Text("XP and coins are completely separate. XP increases your detective rank and is never spent. Coins can be spent on snippets without changing XP or rank. Completing cases rewards both independently; rank-ups grant bonus coins.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("A district pass requires 10 clears and at least 7 perfect results; each earns 1 crystal, once. You begin with 2 free hints; later hints cost 2 crystals.")
                            .font(.system(size: 12))
                            .foregroundStyle(Art.faded)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                GameTitle(text: "YOUR DETECTIVES", size: 25)
                ForEach(RankRewards.cosmetics.indices, id: \.self) { index in
                    rewardRow(RankRewards.cosmetics[index])
                }
                GameButton(title: "BACK TO HQ", icon: "house.fill", action: back)
            }
            .frame(maxWidth: 580)
            .padding(18)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .onChange(of: selectedTheme) { _, _ in
            CloudSaveManager.shared.settingsChanged()
        }
    }

    private var rankHero: some View {
        GameCard(accent: Art.gold) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 17) {
                    DetectiveCharacter(store: store, size: 78)
                    VStack(alignment: .leading, spacing: 6) {
                        GameKicker(text: "DETECTIVE ACCOUNT", color: Art.cyan)
                        GameTitle(text: "LEVEL \(store.accountLevel)", size: 29)
                        Text(store.rankTitle)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Art.gold)
                        Text(DetectiveIdentity.names[DetectiveIdentity.index(for: selectedTheme)])
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(Art.cyan)
                    }
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Art.ink)
                        Capsule().fill(Art.gold)
                            .frame(width: proxy.size.width * store.rankProgress)
                    }
                }
                .frame(height: 14)
                HStack {
                    GameKicker(text: store.xpForNextRank, color: Art.paper)
                    Spacer()
                    GameKicker(text: "\(store.accountXP) TOTAL XP")
                }
            }
        }
    }

    private func rewardRow(_ reward: (level: Int, title: String, color: String)) -> some View {
        let unlocked = store.accountLevel >= reward.level
        let equipped = selectedTheme == reward.color

        return GameCard(accent: unlocked ? Art.mint : Art.edge) {
            HStack(spacing: 13) {
                ZStack {
                    DetectivePortrait(theme: reward.color, size: 57)
                        .opacity(unlocked ? 1 : 0.38)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 21, weight: .black))
                            .foregroundStyle(Art.gold)
                            .shadow(color: Art.ink, radius: 7)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(reward.title.uppercased())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    GameKicker(text: "ACCOUNT LVL \(reward.level)" +
                               (unlocked ? " · UNLOCKED" : " · LOCKED"),
                               color: unlocked ? Art.mint : Art.faded)
                    Text(DetectiveIdentity.names[DetectiveIdentity.index(for: reward.color)])
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Art.faded)
                }
                Spacer(minLength: 3)
                if unlocked {
                    Button {
                        GameEffects.shared.success()
                        selectedTheme = reward.color
                    } label: {
                        Text(equipped ? "ACTIVE" : "EQUIP")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Art.ink)
                            .frame(minWidth: 56, minHeight: 42)
                            .background(equipped ? Art.mint : Art.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressGameStyle())
                }
            }
        }
    }
}
