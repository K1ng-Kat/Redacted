import SwiftUI

// Six original detective identities tied to the existing rank unlocks.
enum DetectiveIdentity {
    static let names = [
        "NIGHT SCOUT", "CRIMSON ANALYST", "NEON TRACKER",
        "GOLDEN INSPECTOR", "GHOST OPERATIVE", "AGENCY DIRECTOR"
    ]
    static let colors = [Art.cyan, Art.coral, Art.mint, Art.gold,
                         Color(red: 0.8, green: 0.85, blue: 0.96),
                         Color(red: 0.78, green: 0.50, blue: 1)]

    static func index(for theme: String) -> Int {
        RankRewards.cosmetics.firstIndex(where: { $0.color == theme }) ?? 0
    }

    static func latestUnlocked(previous: Int, current: Int) -> (name: String, theme: String)? {
        guard current > previous else { return nil }
        for reward in RankRewards.cosmetics.reversed()
            where reward.level > previous && reward.level <= current {
            return (reward.title, reward.color)
        }
        return nil
    }
}

struct DetectivePortrait: View {
    let theme: String
    var size: CGFloat = 83

    private var index: Int { DetectiveIdentity.index(for: theme) }
    private var highlight: Color { DetectiveIdentity.colors[index] }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.20)
                .fill(LinearGradient(colors: [highlight, Art.blueDeep],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))

            // Stylized shoulders and collar.
            Ellipse()
                .fill(index % 2 == 0 ? Art.ink : Art.blue)
                .frame(width: size * 0.91, height: size * 0.53)
                .offset(y: size * 0.39)
            Ellipse()
                .fill(Color(red: 0.95 - Double(index % 3) * 0.12,
                            green: 0.75 - Double(index % 3) * 0.08,
                            blue: 0.57 - Double(index % 3) * 0.05))
                .frame(width: size * 0.47, height: size * 0.52)
                .offset(y: -size * 0.043)

            if index == 0 || index == 4 {
                Ellipse().fill(Art.ink)
                    .frame(width: size * 0.55, height: size * 0.20)
                    .offset(y: -size * 0.30)
            } else if index == 1 || index == 5 {
                RoundedRectangle(cornerRadius: size * 0.08)
                    .fill(Art.ink)
                    .frame(width: size * 0.57, height: size * 0.19)
                    .offset(y: -size * 0.27)
                Capsule().fill(Art.gold)
                    .frame(width: size * 0.65, height: size * 0.07)
                    .offset(y: -size * 0.20)
            } else {
                Ellipse().fill(Color(red: 0.20, green: 0.14, blue: 0.20))
                    .frame(width: size * 0.60, height: size * 0.26)
                    .offset(y: -size * 0.27)
            }

            HStack(spacing: size * 0.13) {
                Circle().frame(width: size * 0.035)
                Circle().frame(width: size * 0.035)
            }
            .foregroundStyle(Art.ink)
            .offset(y: -size * 0.02)

            if index == 2 || index == 5 {
                Image(systemName: "eyeglasses")
                    .font(.system(size: size * 0.34, weight: .regular))
                    .foregroundStyle(Art.ink)
                    .offset(y: -size * 0.03)
            }
            if index == 3 || index == 4 {
                Image(systemName: index == 3 ? "star.circle.fill" : "eye.fill")
                    .font(.system(size: size * 0.18, weight: .black))
                    .foregroundStyle(Art.gold)
                    .offset(x: size * 0.20, y: size * 0.33)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.20))
        .overlay(RoundedRectangle(cornerRadius: size * 0.20)
            .stroke(highlight.opacity(0.86), lineWidth: 2))
        .accessibilityLabel("\(DetectiveIdentity.names[index]) detective portrait")
    }
}

/// Coach steps intentionally intercept other taps so new players know
/// exactly what to do. Only shown for major first-time milestones.
struct GameCoachOverlay: View {
    let title: String
    let detail: String
    let button: String
    let symbol: String
    let portraitTheme: String?
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.87).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Art.gold)
                    .padding(.bottom, 2)
                if let portraitTheme {
                    DetectivePortrait(theme: portraitTheme, size: 118)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(Art.gold)
                }
                GameTitle(text: title, size: 29)
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Art.paper)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "arrow.down")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(Art.gold)
                GameButton(title: button, icon: "hand.point.up.left.fill", action: action)
            }
            .frame(maxWidth: 350)
            .padding(23)
            .background(Art.blueDeep)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(RoundedRectangle(cornerRadius: 25)
                .stroke(Art.gold, lineWidth: 2.5))
            .padding(.horizontal, 20)
        }
        .transition(.opacity)
        .zIndex(200)
    }
}

/// Deterministic, short coin celebration. Doesn't spawn an unbounded number
/// of audio players or play a sound for every individual currency unit.
struct CoinRewardAnimation: View {
    let coins: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleCount = 0
    @State private var flying = false

    var body: some View {
        ZStack {
            HStack(spacing: 11) {
                CoinIcon(size: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text("+\(visibleCount)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Art.gold)
                    GameKicker(text: "COINS EARNED", color: Art.faded)
                }
                Spacer()
            }

            if !reduceMotion && coins > 0 {
                ForEach(0..<7, id: \.self) { index in
                    CoinIcon(size: CGFloat(18 + index % 3 * 5))
                        .offset(
                            x: flying ? CGFloat(index - 3) * 23 : 0,
                            y: flying ? CGFloat(-48 - (index % 3) * 22) : 22
                        )
                        .opacity(flying ? 0 : 1)
                        .scaleEffect(flying ? 0.65 : 1)
                        .animation(.easeOut(duration: 0.58)
                            .delay(Double(index) * 0.045), value: flying)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: coins) {
            if reduceMotion || coins <= 0 {
                visibleCount = max(0, coins)
                return
            }
            visibleCount = 0
            flying = false
            flying = true
            let steps = min(14, max(1, coins))
            for step in 1...steps {
                if Task.isCancelled { break }
                try? await Task.sleep(for: .milliseconds(53))
                if Task.isCancelled { break }
                visibleCount = (coins * step) / steps
                GameEffects.shared.coinTick()
            }
            if !Task.isCancelled { visibleCount = coins }
        }
        .accessibilityLabel("\(coins) coins earned")
    }
}
