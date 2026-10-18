import SwiftUI

// REDACTED art direction: expressive, chunky and tactile.
// A bright investigation game, not a document reader.
enum Noir {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.105)
    static let card = Color(red: 0.084, green: 0.116, blue: 0.185)
    static let elevated = Color(red: 0.135, green: 0.178, blue: 0.260)
    static let accent = Color(red: 1.0, green: 0.295, blue: 0.32)
    static let accentDark = Color(red: 0.65, green: 0.13, blue: 0.22)
    static let ivory = Color(red: 1.0, green: 0.985, blue: 0.93)
    static let muted = Color(red: 0.70, green: 0.76, blue: 0.83)
    static let line = Color.white.opacity(0.14)
    static let green = Color(red: 0.42, green: 0.98, blue: 0.68)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.26)
    static let cyan = Color(red: 0.36, green: 0.87, blue: 1.0)
    static let deep = Color(red: 0.015, green: 0.025, blue: 0.055)
}

struct RedactedBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Noir.background
                LinearGradient(
                    colors: [Color(red: 0.095, green: 0.13, blue: 0.24),
                             Noir.background, Noir.deep],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                RadialGradient(colors: [Noir.cyan.opacity(0.095), .clear],
                               center: .topTrailing, startRadius: 30, endRadius: 330)
                RadialGradient(colors: [Noir.accent.opacity(0.095), .clear],
                               center: .bottomLeading, startRadius: 30, endRadius: 280)

                Canvas { context, size in
                    var lines = Path()
                    let spacing: CGFloat = 34
                    stride(from: CGFloat(0), through: size.width, by: spacing).forEach { x in
                        lines.move(to: CGPoint(x: x, y: 0))
                        lines.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                        lines.move(to: CGPoint(x: 0, y: y))
                        lines.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(lines, with: .color(.white.opacity(0.026)), lineWidth: 0.7)
                }
                .accessibilityHidden(true)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}

struct FileLabel: View {
    let text: String
    var color: Color = Noir.muted

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(color)
            .lineLimit(2)
    }
}

struct FileCard<Content: View>: View {
    var highlighted = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            highlighted ? Noir.elevated : Noir.card,
                            highlighted ? Noir.card : Color(red: 0.060, green: 0.090, blue: 0.158)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(highlighted ? Noir.gold.opacity(0.75) : Noir.line, lineWidth: highlighted ? 2 : 1.5)
            }
            .shadow(color: Noir.deep.opacity(0.8), radius: 0, x: 0, y: 5)
    }
}

struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.968 : 1)
            .offset(y: configuration.isPressed ? 4 : 0)
            .brightness(configuration.isPressed ? -0.075 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct RedButton: View {
    let text: String
    var symbol = "arrow.right"
    var disabled = false
    var fill = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: fill ? "bolt.fill" : "circle.hexagongrid.fill")
                    .font(.system(size: 15, weight: .heavy))
                Text(text.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .black))
            }
            .foregroundStyle(fill ? Noir.deep : Noir.ivory)
            .padding(.horizontal, 19)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(fill
                          ? LinearGradient(colors: [Noir.gold, Color(red: 1.0, green: 0.57, blue: 0.24)],
                                           startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [Noir.elevated, Noir.card],
                                           startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(fill ? Color.white.opacity(0.55) : Noir.line, lineWidth: 1.5)
            }
            .shadow(color: fill ? Color(red: 0.47, green: 0.23, blue: 0.09) : Noir.deep,
                    radius: 0, x: 0, y: 5)
            .padding(.bottom, 5)
            .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(TactileButtonStyle())
        .disabled(disabled)
        .accessibilityAddTraits(.isButton)
    }
}

struct ProgressTrack: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Noir.deep)
                Capsule()
                    .fill(LinearGradient(colors: [Noir.gold, Color.orange],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geometry.size.width * min(1, max(0, progress))))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.25)).frame(height: 3)
                            .padding(.horizontal, 4).padding(.top, 2)
                    }
            }
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1.5))
        }
        .frame(height: 13)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
        .accessibilityLabel("Investigation progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

struct SectionHeading: View {
    let kicker: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Capsule().fill(Noir.accent).frame(width: 22, height: 5)
                FileLabel(text: kicker, color: Noir.cyan)
            }
            Text(title)
                .font(.system(size: 31, weight: .black, design: .rounded))
                .tracking(-0.7)
                .foregroundStyle(Noir.ivory)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Noir.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FileRule: View {
    var body: some View {
        Rectangle()
            .fill(Noir.line)
            .frame(height: 1)
    }
}

struct StatusPill: View {
    let title: String
    var highlighted = false

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(highlighted ? Noir.green : Noir.gold)
                .frame(width: 5, height: 5)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .tracking(0.3)
                .lineLimit(1)
        }
        .foregroundStyle(highlighted ? Noir.green : Noir.gold)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background((highlighted ? Noir.green : Noir.gold).opacity(0.11))
        .clipShape(Capsule())
        .overlay(Capsule().stroke((highlighted ? Noir.green : Noir.gold).opacity(0.35), lineWidth: 1))
    }
}

// Tactile tile for navigating between game activities.
struct ActionTile: View {
    let symbol: String
    let name: String
    let note: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(Noir.deep)
                    .frame(width: 51, height: 51)
                    .background(color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .rotationEffect(.degrees(-5))
                VStack(alignment: .leading, spacing: 5) {
                    Text(name.uppercased())
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(Noir.ivory)
                    Text(note)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Noir.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(color)
            }
            .padding(14)
            .background(Noir.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Noir.line, lineWidth: 1.5))
            .shadow(color: Noir.deep, radius: 0, x: 0, y: 5)
            .padding(.bottom, 5)
        }
        .buttonStyle(TactileButtonStyle())
    }
}

// Original vector illustration. No external images, IP or network requests.
struct ArchiveIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scanning = false

    var body: some View {
        GeometryReader { area in
            let w = area.size.width
            let h = area.size.height
            ZStack {
                LinearGradient(colors: [
                    Color(red: 0.29, green: 0.21, blue: 0.48),
                    Color(red: 0.13, green: 0.20, blue: 0.36),
                    Noir.deep
                ], startPoint: .topLeading, endPoint: .bottomTrailing)

                Circle()
                    .fill(Noir.cyan.opacity(0.11))
                    .frame(width: w * 0.8)
                    .blur(radius: 34)
                    .offset(x: w * 0.24, y: -h * 0.18)

                ForEach(0..<6, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(0.07))
                        .frame(width: 2, height: h * 1.8)
                        .rotationEffect(.degrees(25))
                        .offset(x: CGFloat(index - 3) * 54)
                }

                // The secure archive vault has its own visual identity.
                RoundedRectangle(cornerRadius: 19)
                    .fill(LinearGradient(colors: [Noir.elevated, Noir.deep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: min(w * 0.59, 235), height: h * 0.94)
                    .rotationEffect(.degrees(7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 17)
                            .stroke(Noir.cyan.opacity(0.6), lineWidth: 3)
                            .frame(width: min(w * 0.59, 235), height: h * 0.94)
                            .rotationEffect(.degrees(7))
                    }
                    .offset(x: w * 0.19, y: h * 0.17)

                ZStack {
                    Circle().fill(Noir.deep).frame(width: 110, height: 110)
                    Circle().stroke(Noir.gold, lineWidth: 5).frame(width: 94, height: 94)
                    Circle().stroke(Noir.cyan.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(scanning && !reduceMotion ? 360 : 0))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(Noir.gold)
                }
                .shadow(color: Noir.gold.opacity(0.3), radius: 20)
                .offset(x: w * 0.17, y: h * 0.09)

                Image(systemName: "viewfinder")
                    .font(.system(size: 115, weight: .ultraLight))
                    .foregroundStyle(Noir.cyan.opacity(0.52))
                    .offset(x: -w * 0.21, y: h * 0.18)

                HStack(spacing: 5) {
                    Circle().fill(Noir.accent).frame(width: 7, height: 7)
                    Text("FEED LOST")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(Noir.accentDark)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .rotationEffect(.degrees(-7))
                .offset(x: -w * 0.23, y: -h * 0.18)
            }
            .frame(width: w, height: h)
            .clipped()
            .onAppear {
                if !reduceMotion {
                    withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                        scanning = true
                    }
                }
            }
        }
        .accessibilityLabel("Illustration of a locked research vault with an interrupted security feed")
    }
}
