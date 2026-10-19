import SwiftUI

enum Art {
    static let ink = Color(red: 0.035, green: 0.055, blue: 0.12)
    static let blue = Color(red: 0.12, green: 0.22, blue: 0.40)
    static let blueDeep = Color(red: 0.075, green: 0.13, blue: 0.25)
    static let blueLight = Color(red: 0.19, green: 0.32, blue: 0.52)
    static let edge = Color(red: 0.36, green: 0.50, blue: 0.70)
    static let gold = Color(red: 1.0, green: 0.79, blue: 0.19)
    static let goldDark = Color(red: 0.64, green: 0.32, blue: 0.065)
    static let coral = Color(red: 0.99, green: 0.32, blue: 0.32)
    static let coralDark = Color(red: 0.59, green: 0.14, blue: 0.22)
    static let cyan = Color(red: 0.37, green: 0.89, blue: 0.97)
    static let mint = Color(red: 0.43, green: 0.96, blue: 0.60)
    static let paper = Color(red: 1.0, green: 0.98, blue: 0.89)
    static let faded = Color(red: 0.75, green: 0.83, blue: 0.93)
}

/// Original detective-star coin for game currency.
struct CoinIcon: View {
    var size: CGFloat = 25

    var body: some View {
        ZStack {
            Circle().fill(Art.goldDark).offset(y: size * 0.08)
            Circle().fill(LinearGradient(colors: [
                Color(red: 1, green: 0.95, blue: 0.58),
                Art.gold, Color(red: 0.94, green: 0.53, blue: 0.11)
            ], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(Art.goldDark.opacity(0.75),
                            lineWidth: max(1.4, size * 0.057))
                .padding(size * 0.14)
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.37, weight: .black))
                .foregroundStyle(Art.goldDark)
            Circle().fill(.white.opacity(0.86))
                .frame(width: size * 0.12)
                .offset(x: -size * 0.28, y: -size * 0.27)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct GameBackdrop: View {
    @AppStorage("redacted.profile.theme") private var selectedTheme = "midnight"

    private var palette: [Color] {
        switch selectedTheme {
        case "crimson":
            return [Color(red: 0.31, green: 0.08, blue: 0.18),
                    Art.ink, Color(red: 0.15, green: 0.045, blue: 0.08)]
        case "neon":
            return [Color(red: 0.055, green: 0.26, blue: 0.30),
                    Art.ink, Color(red: 0.07, green: 0.07, blue: 0.27)]
        case "gold":
            return [Color(red: 0.30, green: 0.23, blue: 0.095),
                    Art.ink, Color(red: 0.16, green: 0.115, blue: 0.07)]
        case "ghost":
            return [Color(red: 0.25, green: 0.31, blue: 0.38),
                    Art.blueDeep, Color(red: 0.07, green: 0.11, blue: 0.16)]
        case "director":
            return [Color(red: 0.28, green: 0.13, blue: 0.33),
                    Art.ink, Color(red: 0.11, green: 0.055, blue: 0.16)]
        default:
            return [Art.blue, Art.ink, Art.blueDeep]
        }
    }

    var body: some View {
        ZStack {
            Art.ink
            LinearGradient(colors: palette,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Art.cyan.opacity(0.12), .clear],
                           center: .topTrailing, startRadius: 30, endRadius: 440)
            Canvas { context, size in
                var path = Path()
                for index in 0...20 {
                    let x = CGFloat(index) * size.width / 20
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for index in 0...40 {
                    let y = CGFloat(index) * size.height / 40
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(0.026)), lineWidth: 0.8)
            }
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

struct GameCard<Content: View>: View {
    let content: Content
    var accent: Color = Art.edge

    init(accent: Color = Art.edge, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Art.ink.opacity(0.82))
                        .offset(y: 5)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            colors: [Art.blueLight, Art.blueDeep],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accent.opacity(0.62), lineWidth: 1.7)
                }
            }
            .padding(.bottom, 5)
    }
}

struct PressGameStyle: ButtonStyle {
    @AppStorage("redacted.fx.motion") private var motion = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let animate = motion && !reduceMotion
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(animate && configuration.isPressed ? 0.962 : 1)
            .offset(y: animate && configuration.isPressed ? 2 : 0)
            .brightness(configuration.isPressed ? -0.065 : 0)
            .animation(animate ? .spring(response: 0.13, dampingFraction: 0.73) : nil,
                       value: configuration.isPressed)
    }
}

struct GameButton: View {
    let title: String
    var icon: String = "play.fill"
    var color: Color = Art.gold
    var bottom: Color = Art.goldDark
    var inactive: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            GameEffects.shared.tap()
            action()
        } label: {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .black))
                    .frame(width: 24)
                Spacer(minLength: 0)
                Text(title.uppercased())
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.4)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
            }
            .foregroundStyle(color == Art.gold ? Art.ink : Color.white)
            .padding(.horizontal, 17)
            .frame(height: 56)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(bottom)
                        .offset(y: 5)
                    RoundedRectangle(cornerRadius: 15)
                        .fill(LinearGradient(colors: [color.opacity(0.85), color],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.50), lineWidth: 1.7)
                }
            }
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .opacity(inactive ? 0.45 : 1)
        }
        .disabled(inactive)
        .buttonStyle(PressGameStyle())
        .accessibilityAddTraits(.isButton)
    }
}

struct GameTitle: View {
    let text: String
    var size: CGFloat = 29

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(-0.55)
            .foregroundStyle(Art.paper)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.78)
            .accessibilityAddTraits(.isHeader)
    }
}

struct GameKicker: View {
    let text: String
    var color: Color = Art.cyan

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .tracking(1)
            .foregroundStyle(color)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }
}

struct StarStrip: View {
    let earned: Int
    var size: CGFloat = 18
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < earned ? "star.fill" : "star")
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(index < earned ? Art.gold : Art.faded.opacity(0.48))
            }
        }
        .accessibilityLabel("\(earned) of 3 stars")
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    var tint: Color = Art.gold

    var body: some View {
        HStack(spacing: 8) {
            if icon == "circle.hexagongrid.fill" {
                CoinIcon(size: 24)
            } else if icon == "crystal" {
                CrystalIcon(size: 26)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Art.faded)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Art.blueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Art.edge.opacity(0.5), lineWidth: 1))
    }
}

// An illustrated scene of each episode's setting, drawn in SwiftUI.
// All shadows are behind solid graphic shapes, never applied to a Text view.
struct DistrictIllustration: View {
    let episode: Int

    private let backgrounds: [(Color, Color)] = [
        (Color(red: 0.30, green: 0.20, blue: 0.44), Color(red: 0.06, green: 0.11, blue: 0.26)),
        (Color(red: 0.11, green: 0.34, blue: 0.44), Color(red: 0.03, green: 0.11, blue: 0.28)),
        (Color(red: 0.40, green: 0.14, blue: 0.34), Color(red: 0.10, green: 0.08, blue: 0.24)),
        (Color(red: 0.37, green: 0.54, blue: 0.67), Color(red: 0.10, green: 0.21, blue: 0.37)),
        (Color(red: 0.39, green: 0.30, blue: 0.21), Color(red: 0.11, green: 0.12, blue: 0.20)),
        (Color(red: 0.25, green: 0.41, blue: 0.61), Color(red: 0.07, green: 0.12, blue: 0.28)),
        (Color(red: 0.45, green: 0.27, blue: 0.38), Color(red: 0.12, green: 0.08, blue: 0.25)),
        (Color(red: 0.17, green: 0.40, blue: 0.31), Color(red: 0.07, green: 0.11, blue: 0.20)),
        (Color(red: 0.34, green: 0.21, blue: 0.48), Color(red: 0.08, green: 0.07, blue: 0.21)),
        (Color(red: 0.35, green: 0.17, blue: 0.22), Color(red: 0.07, green: 0.07, blue: 0.15))
    ]

    var body: some View {
        GeometryReader { geometry in
            let pair = backgrounds[min(max(episode, 0), 9)]
            ZStack {
                LinearGradient(colors: [pair.0, pair.1],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .fill(Art.cyan.opacity(0.11))
                    .frame(width: geometry.size.width * 0.75)
                    .blur(radius: 28)
                    .offset(x: geometry.size.width * 0.28, y: -65)

                // Silhouettes: deliberately illustrative rather than stock imagery.
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        let height = CGFloat(75 + ((index * 47 + episode * 31) % 120))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Art.ink.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                            .overlay(alignment: .top) {
                                HStack(spacing: 4) {
                                    ForEach(0..<2, id: \.self) { _ in
                                        Capsule()
                                            .fill(Art.gold.opacity(0.27))
                                            .frame(width: 5, height: 20)
                                    }
                                }
                                .padding(.top, 12)
                            }
                    }
                }
                .padding(.horizontal, 10)
                .frame(maxHeight: .infinity, alignment: .bottom)

                let episodeSymbol = CampaignCatalog.episodes[min(max(episode, 0), 9)].symbol
                Image(systemName: episodeSymbol)
                    .font(.system(size: 105, weight: .black))
                    .foregroundStyle(Art.gold)
                    .rotationEffect(.degrees(-9))
                    .padding(26)
                    .background {
                        RoundedRectangle(cornerRadius: 29)
                            .fill(Art.ink.opacity(0.82))
                            .rotationEffect(.degrees(7))
                            .overlay {
                                RoundedRectangle(cornerRadius: 29)
                                    .stroke(Art.cyan.opacity(0.52), lineWidth: 4)
                                    .rotationEffect(.degrees(7))
                            }
                    }
                    .offset(x: geometry.size.width * 0.10, y: 1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }
}
