import SwiftUI

enum Noir {
    static let background = Color(red: 0.035, green: 0.043, blue: 0.059)
    static let card = Color(red: 0.081, green: 0.092, blue: 0.112)
    static let elevated = Color(red: 0.109, green: 0.122, blue: 0.143)
    static let accent = Color(red: 0.94, green: 0.25, blue: 0.28)
    static let ivory = Color(red: 0.95, green: 0.94, blue: 0.91)
    static let muted = Color(red: 0.58, green: 0.62, blue: 0.67)
    static let line = Color.white.opacity(0.095)
    static let green = Color(red: 0.35, green: 0.82, blue: 0.62)
}

struct RedactedBackdrop: View {
    var body: some View {
        ZStack {
            Noir.background
            RadialGradient(colors: [Noir.accent.opacity(0.09), .clear],
                           center: .topTrailing, startRadius: 30, endRadius: 390)
            LinearGradient(colors: [.clear, Color.black.opacity(0.25)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

struct FileLabel: View {
    let text: String
    var color: Color = Noir.muted

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(2)
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
            .background(highlighted ? Noir.elevated : Noir.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(highlighted ? Noir.accent.opacity(0.5) : Noir.line, lineWidth: 1)
            }
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
                Text(text.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .tracking(0.8)
                Spacer(minLength: 4)
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(fill ? Color.white : Noir.ivory)
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(fill ? Noir.accent : Noir.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(fill ? Color.clear : Noir.line, lineWidth: 1)
            }
            .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityAddTraits(.isButton)
    }
}

struct ProgressTrack: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(Noir.accent)
                    .frame(width: max(0, geometry.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: 5)
        .accessibilityLabel("Investigation progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

struct SectionHeading: View {
    let kicker: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FileLabel(text: kicker, color: Noir.accent)
            Text(title)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(Noir.ivory)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Noir.muted)
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
        Text(title.uppercased())
            .font(.system(size: 9, weight: .heavy, design: .monospaced))
            .tracking(1)
            .foregroundStyle(highlighted ? Noir.green : Noir.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(highlighted ? Noir.green.opacity(0.12) : Noir.elevated)
            .clipShape(Capsule())
    }
}
