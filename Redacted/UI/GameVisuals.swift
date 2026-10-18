import SwiftUI

// Custom visual language for REDACTED: illustrated locations, oversized tactile
// controls, and clear silhouettes. No third-party assets or copied game UI.
enum PlayColor {
    static let midnight = Color(red: 0.035, green: 0.06, blue: 0.14)
    static let panel = Color(red: 0.085, green: 0.14, blue: 0.245)
    static let panelTop = Color(red: 0.15, green: 0.22, blue: 0.35)
    static let outline = Color(red: 0.28, green: 0.40, blue: 0.57)
    static let text = Color(red: 1, green: 0.98, blue: 0.90)
    static let secondary = Color(red: 0.71, green: 0.79, blue: 0.90)
    static let yellow = Color(red: 1, green: 0.80, blue: 0.22)
    static let orange = Color(red: 1, green: 0.52, blue: 0.24)
    static let red = Color(red: 0.99, green: 0.29, blue: 0.32)
    static let aqua = Color(red: 0.39, green: 0.91, blue: 0.96)
    static let green = Color(red: 0.43, green: 0.92, blue: 0.55)
}

struct PlayBackground: View {
    var body: some View {
        ZStack {
            PlayColor.midnight
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.21, blue: 0.36),
                         PlayColor.midnight, Color(red: 0.02, green: 0.035, blue: 0.09)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            RadialGradient(colors: [PlayColor.aqua.opacity(0.1), .clear],
                           center: .topTrailing, startRadius: 20, endRadius: 400)
        }
        .ignoresSafeArea()
    }
}

struct PlayPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [PlayColor.panelTop, PlayColor.panel],
                                         startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(PlayColor.outline.opacity(0.8), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.37), radius: 0, x: 0, y: 5)
    }
}

struct PlayPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65),
                       value: configuration.isPressed)
    }
}

struct PlayCTA: View {
    let title: String
    var icon = "arrow.right"
    var enabled = true
    var secondary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .black))
                Spacer(minLength: 0)
                Text(title.uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.73)
                    .tracking(0.4)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .black))
            }
            .foregroundStyle(secondary ? PlayColor.text : PlayColor.midnight)
            .padding(.horizontal, 18)
            .frame(height: 61)
            .background {
                RoundedRectangle(cornerRadius: 17)
                    .fill(secondary
                          ? LinearGradient(colors: [PlayColor.panelTop, PlayColor.panel],
                                           startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [PlayColor.yellow, PlayColor.orange],
                                           startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(.white.opacity(secondary ? 0.27 : 0.66), lineWidth: 2)
            }
            .shadow(color: secondary ? PlayColor.midnight : Color(red: 0.51, green: 0.23, blue: 0.06),
                    radius: 0, x: 0, y: 6)
            .padding(.bottom, 6)
            .opacity(enabled ? 1 : 0.4)
        }
        .disabled(!enabled)
        .buttonStyle(PlayPress())
    }
}

struct PlayEyebrow: View {
    let title: String
    var color: Color = PlayColor.aqua
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(color)
    }
}

struct PlayHeadline: View {
    let text: String
    var size: CGFloat = 31
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(-0.7)
            .foregroundStyle(PlayColor.text)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct MissionProgress: View {
    let current: Int
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(index <= min(current, 5) ? PlayColor.yellow : PlayColor.outline.opacity(0.55))
                    .frame(height: 8)
                    .overlay(Capsule().stroke(.black.opacity(0.18), lineWidth: 1))
            }
        }
        .accessibilityLabel("Mission chapter")
        .accessibilityValue("\(min(current + 1, 6)) of 6")
    }
}

struct ClueMarker: View {
    let title: String
    let icon: String
    let found: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .stroke(found ? PlayColor.green : PlayColor.yellow, lineWidth: 2.5)
                        .frame(width: 66, height: 66)
                        .scaleEffect(found || reduceMotion ? 1 : pulse ? 1.13 : 0.95)
                        .opacity(found ? 0.3 : pulse ? 0.17 : 0.60)
                    Circle()
                        .fill(found ? PlayColor.green : PlayColor.yellow)
                        .frame(width: 53, height: 53)
                        .overlay {
                            Circle().stroke(.white.opacity(0.75), lineWidth: 2)
                        }
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 4)
                    Image(systemName: found ? "checkmark" : icon)
                        .font(.system(size: 23, weight: .black))
                        .foregroundStyle(PlayColor.midnight)
                }
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(PlayColor.midnight.opacity(0.88))
                    .clipShape(Capsule())
            }
            .frame(width: 118)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlayPress())
        .accessibilityLabel(found ? "\(title), evidence collected" : "Investigate \(title)")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// Hand-built vector art: each location has a readable silhouette and unique props.
// Interactable clue hotspots are layered above this scene by the game controller.
struct MysteryRoomArt: View {
    let room: Int

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [room == 2 ? Color(red: 0.18, green: 0.30, blue: 0.40) :
                            Color(red: 0.18, green: 0.23, blue: 0.39),
                             Color(red: 0.06, green: 0.09, blue: 0.19)],
                    startPoint: .top, endPoint: .bottom
                )

                // Floor perspective
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * 0.78))
                    path.addLine(to: CGPoint(x: width, y: height * 0.78))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .fill(Color(red: 0.12, green: 0.16, blue: 0.26))

                Rectangle().fill(PlayColor.aqua.opacity(0.25))
                    .frame(height: 3)
                    .position(x: width / 2, y: height * 0.78)

                switch room {
                case 0: archive(in: CGSize(width: width, height: height))
                case 1: security(in: CGSize(width: width, height: height))
                case 2: dispatch(in: CGSize(width: width, height: height))
                default: technician(in: CGSize(width: width, height: height))
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .accessibilityLabel(["Secure vault with glowing door controls",
                             "Security office with camera monitors",
                             "Dispatch room with a pneumatic tube",
                             "Technical office with a workstation and coffee"][min(max(room, 0), 3)])
    }

    private func archive(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.09, green: 0.15, blue: 0.23))
                .frame(width: size.width * 0.57, height: size.height * 0.71)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(PlayColor.aqua.opacity(0.48), lineWidth: 6)
                }
                .position(x: size.width * 0.50, y: size.height * 0.44)
            Circle()
                .stroke(PlayColor.yellow.opacity(0.8), lineWidth: 8)
                .frame(width: 93, height: 93)
                .background(Circle().fill(Color(red: 0.10, green: 0.21, blue: 0.32)))
                .position(x: size.width * 0.54, y: size.height * 0.47)
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 45, weight: .black))
                .foregroundStyle(PlayColor.yellow)
                .position(x: size.width * 0.54, y: size.height * 0.47)
            RoundedRectangle(cornerRadius: 7)
                .fill(PlayColor.aqua.opacity(0.62))
                .frame(width: 42, height: 85)
                .position(x: size.width * 0.18, y: size.height * 0.54)
            Rectangle()
                .fill(PlayColor.yellow.opacity(0.6))
                .frame(width: size.width * 0.70, height: 6)
                .position(x: size.width / 2, y: size.height * 0.83)
        }
    }

    private func security(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let x = size.width * (0.24 + CGFloat(i) * 0.26)
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(red: 0.07, green: 0.29, blue: 0.37))
                    .frame(width: size.width * 0.23, height: size.height * 0.34)
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(PlayColor.aqua.opacity(0.7), lineWidth: 3)
                    }
                    .position(x: x, y: size.height * 0.38)
                Image(systemName: i == 1 ? "video.slash.fill" : "waveform.path")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(i == 1 ? PlayColor.red : PlayColor.aqua)
                    .position(x: x, y: size.height * 0.38)
            }
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.16, green: 0.26, blue: 0.35))
                .frame(width: size.width * 0.88, height: size.height * 0.16)
                .position(x: size.width / 2, y: size.height * 0.74)
            Image(systemName: "keyboard")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(PlayColor.secondary)
                .position(x: size.width * 0.54, y: size.height * 0.75)
        }
    }

    private func dispatch(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.13, green: 0.22, blue: 0.28))
                .frame(width: size.width * 0.41, height: size.height * 0.75)
                .position(x: size.width * 0.73, y: size.height * 0.45)
            Circle()
                .stroke(PlayColor.yellow, lineWidth: 10)
                .frame(width: 118, height: 118)
                .position(x: size.width * 0.70, y: size.height * 0.39)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 50, weight: .black))
                .foregroundStyle(PlayColor.yellow)
                .position(x: size.width * 0.70, y: size.height * 0.39)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.54, green: 0.34, blue: 0.22))
                .frame(width: size.width * 0.43, height: size.height * 0.33)
                .overlay {
                    RoundedRectangle(cornerRadius: 8).stroke(PlayColor.yellow.opacity(0.5), lineWidth: 4)
                }
                .position(x: size.width * 0.27, y: size.height * 0.67)
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 54))
                .foregroundStyle(PlayColor.yellow.opacity(0.82))
                .position(x: size.width * 0.27, y: size.height * 0.67)
        }
    }

    private func technician(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.08, green: 0.28, blue: 0.37))
                .frame(width: size.width * 0.64, height: size.height * 0.51)
                .overlay {
                    RoundedRectangle(cornerRadius: 10).stroke(PlayColor.aqua.opacity(0.67), lineWidth: 5)
                }
                .position(x: size.width * 0.46, y: size.height * 0.38)
            Image(systemName: "terminal.fill")
                .font(.system(size: 60, weight: .black))
                .foregroundStyle(PlayColor.aqua)
                .position(x: size.width * 0.46, y: size.height * 0.38)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.32, green: 0.29, blue: 0.32))
                .frame(width: size.width * 0.86, height: size.height * 0.15)
                .position(x: size.width / 2, y: size.height * 0.76)
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 55, weight: .bold))
                .foregroundStyle(PlayColor.orange)
                .position(x: size.width * 0.75, y: size.height * 0.65)
        }
    }
}

struct SuspectPortrait: View {
    let suspectID: String
    var size: CGFloat = 96

    private var tint: Color {
        switch suspectID {
        case "ada": PlayColor.orange
        case "noah": PlayColor.aqua
        default: PlayColor.red
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23)
                .fill(tint.gradient)
            Circle()
                .fill(Color(red: 0.96, green: 0.71, blue: 0.55))
                .frame(width: size * 0.38, height: size * 0.40)
                .offset(y: -size * 0.065)
            Ellipse()
                .fill(suspectID == "noah" ? PlayColor.midnight : Color(red: 0.27, green: 0.20, blue: 0.23))
                .frame(width: size * 0.45, height: size * 0.23)
                .offset(y: -size * 0.265)
            Ellipse()
                .fill(suspectID == "ada" ? Color(red: 0.36, green: 0.20, blue: 0.39) :
                        suspectID == "noah" ? PlayColor.panelTop : PlayColor.midnight)
                .frame(width: size * 0.8, height: size * 0.48)
                .offset(y: size * 0.37)
            HStack(spacing: size * 0.12) {
                Circle().frame(width: size * 0.03)
                Circle().frame(width: size * 0.03)
            }
            .foregroundStyle(PlayColor.midnight)
            .offset(y: -size * 0.05)
            if suspectID == "jules" {
                Image(systemName: "shield.fill")
                    .font(.system(size: size * 0.16))
                    .foregroundStyle(PlayColor.yellow)
                    .offset(x: size * 0.18, y: size * 0.30)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.23)
                .stroke(.white.opacity(0.63), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 0, y: 4)
        .accessibilityHidden(true)
    }
}
