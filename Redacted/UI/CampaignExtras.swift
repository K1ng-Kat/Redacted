import SwiftUI

struct CampaignSettingsView: View {
    @ObservedObject var store: CampaignStore
    let back: () -> Void

    @AppStorage("redacted.fx.sound") private var sound = true
    @AppStorage("redacted.fx.haptics") private var haptics = true
    @AppStorage("redacted.fx.motion") private var motion = true
    @AppStorage("redacted.fx.hints") private var hints = true
    @State private var confirmingReset = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
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
                        option("SHOW HINT BUTTON", detail: "Hints cost a ticket or 30 coins",
                               symbol: "lightbulb.fill", enabled: $hints)
                    }
                }
                GameCard {
                    VStack(alignment: .leading, spacing: 11) {
                        GameKicker(text: "PRIVACY AND SAVES", color: Art.cyan)
                        Text("Your account level, coins, stars and solved levels are saved locally on this device. No online account or multiplayer connection is required.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("REDACTED 0.4 — single-player campaign")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Art.faded)
                    }
                }
                GameButton(title: "ERASE CAMPAIGN SAVE", icon: "trash.fill",
                           color: Art.coral, bottom: Art.coralDark) {
                    confirmingReset = true
                }
                GameButton(title: "DONE", icon: "checkmark", action: back)
            }
            .frame(maxWidth: 560)
            .padding(18)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(GameBackdrop())
        .confirmationDialog("Delete your 100-level campaign progress?",
                            isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Erase levels, coins, XP and rewards", role: .destructive) {
                store.resetProgress()
                back()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This is permanent. It erases all earned currency, account levels, stars, and unlocks on this device.")
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
            VStack(alignment: .leading, spacing: 19) {
                ScreenHeader(title: "HOW TO PLAY", subtitle: "LEARN IN 30 SECONDS", back: back)
                instruction("1", "READ THE CASE", "Each level starts with a tiny mystery and one clear objective.",
                            symbol: "doc.text.magnifyingglass", color: Art.cyan)
                instruction("2", "TAP, THINK, SOLVE", "Look for hidden objects, arrange events, decode words and solve puzzles using evidence.",
                            symbol: "hand.point.up.left.fill", color: Art.gold)
                instruction("3", "EARN YOUR STARS", "Make fewer mistakes and use fewer hints to finish with up to three stars.",
                            symbol: "star.fill", color: Art.mint)
                instruction("4", "LEVEL UP", "New cases award coins and XP. Rise through detective ranks to unlock rewards and new visual themes.",
                            symbol: "rosette", color: Art.coral)
                GameCard(accent: Art.gold) {
                    VStack(alignment: .leading, spacing: 9) {
                        GameKicker(text: "HINT ECONOMY", color: Art.gold)
                        Text("You start with 50 coins and 2 free hints. Every new rank gives extra coins and another hint. After your tickets run out, hints cost 30 coins.")
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
    @AppStorage("redacted.profile.theme") private var selectedTheme = "midnight"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: "DETECTIVE PROFILE",
                             subtitle: "LEVELS · COINS · REWARDS", back: back)

                rankHero
                HStack(spacing: 9) {
                    StatChip(icon: "circle.hexagongrid.fill", value: "\(store.coins)", label: "COINS")
                    Spacer(minLength: 1)
                    StatChip(icon: "lightbulb.fill", value: "\(store.hintTickets)", label: "HINTS", tint: Art.cyan)
                    Spacer(minLength: 1)
                    StatChip(icon: "star.fill", value: "\(store.totalStars)", label: "STARS", tint: Art.gold)
                }
                GameCard {
                    VStack(alignment: .leading, spacing: 10) {
                        GameKicker(text: "HOW REWARDS WORK", color: Art.gold)
                        Text("New cases: XP, coins and stars. Finish every 10th case for a district bonus. Every detective account level awards 60 coins and one free hint.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Replaying a solved level only pays extra rewards when you improve your best star rating. There are no purchases or paid loot boxes.")
                            .font(.system(size: 12))
                            .foregroundStyle(Art.faded)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                GameTitle(text: "RANK UNLOCKS", size: 25)
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
    }

    private var rankHero: some View {
        GameCard(accent: Art.gold) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 17) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 19)
                            .fill(Art.gold)
                            .frame(width: 78, height: 78)
                        Image(systemName: "star.shield.fill")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(Art.ink)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        GameKicker(text: "DETECTIVE ACCOUNT", color: Art.cyan)
                        GameTitle(text: "LEVEL \(store.accountLevel)", size: 29)
                        Text(store.rankTitle)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Art.gold)
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
                Image(systemName: unlocked ? "paintpalette.fill" : "lock.fill")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(unlocked ? Art.gold : Art.faded)
                    .frame(width: 49, height: 49)
                    .background(Art.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 6) {
                    Text(reward.title.uppercased())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    GameKicker(text: "ACCOUNT LVL \(reward.level)" +
                               (unlocked ? " · UNLOCKED" : " · LOCKED"),
                               color: unlocked ? Art.mint : Art.faded)
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
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(equipped ? Art.mint : Art.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressGameStyle())
                }
            }
        }
    }
}
