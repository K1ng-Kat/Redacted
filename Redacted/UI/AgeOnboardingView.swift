import SwiftUI

/// One-time game setup. The selected numeric age exists only as transient
/// SwiftUI state. The parent view persists the *difficulty mode*, not the age.
struct AgeOnboardingView: View {
    let complete: (DetectiveAgeMode) -> Void

    @State private var selectedAge = 12
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var mode: DetectiveAgeMode {
        switch selectedAge {
        case ..<9: .junior
        case 9..<13: .explorer
        case 13..<16: .investigator
        default: .expert
        }
    }

    private var themeSymbol: String {
        switch mode {
        case .junior: "magnifyingglass"
        case .explorer: "map.fill"
        case .investigator: "doc.text.magnifyingglass"
        case .expert: "checkmark.shield.fill"
        }
    }

    var body: some View {
        ZStack {
            GameBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    profileIllustration
                    introduction
                    ageSelector
                    privacy
                    GameButton(title: "CONTINUE TO REDACTED",
                               icon: "arrow.right") {
                        complete(mode)
                    }
                }
                .frame(maxWidth: 460)
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.79)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: "eye.fill")
                    .foregroundStyle(Art.coral)
                Text("REDACTED")
                    .foregroundStyle(Art.paper)
            }
            .font(.system(size: 23, weight: .black, design: .rounded))
            GameKicker(text: "NEW DETECTIVE SETUP · STEP 1 OF 1",
                       color: Art.cyan)
            GameTitle(text: "HOW OLD ARE YOU?", size: 31)
                .multilineTextAlignment(.center)
            Text("We'll match the mysteries to your reading and puzzle level.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Art.faded)
                .multilineTextAlignment(.center)
        }
    }

    private var profileIllustration: some View {
        ZStack {
            Circle()
                .fill(Art.gold.opacity(0.10))
                .frame(width: 170, height: 170)
            Circle()
                .stroke(Art.gold.opacity(0.53), lineWidth: 3)
                .frame(width: 138, height: 138)
            Image(systemName: themeSymbol)
                .font(.system(size: 68, weight: .black))
                .foregroundStyle(Art.gold)
                .scaleEffect(appeared ? 1 : 0.91)
            Image(systemName: "sparkle")
                .font(.system(size: 28))
                .foregroundStyle(Art.cyan)
                .offset(x: 66, y: -59)
        }
        .frame(height: 155)
        .accessibilityHidden(true)
    }

    private var introduction: some View {
        GameCard(accent: Art.gold) {
            VStack(alignment: .leading, spacing: 7) {
                GameKicker(text: "YOUR GAME DIFFICULTY", color: Art.gold)
                GameTitle(text: mode.title, size: 21)
                Text(mode.subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Art.paper)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var ageSelector: some View {
        GameCard(accent: Art.cyan) {
            VStack(spacing: 7) {
                GameKicker(text: "SELECT YOUR AGE", color: Art.cyan)
                Picker("Age", selection: $selectedAge) {
                    ForEach(6...17, id: \.self) { age in
                        Text("\(age) years old").tag(age)
                    }
                    Text("18 or older").tag(18)
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 310)
                .frame(height: 170)
                .clipped()
                .accessibilityHint("Your age is used only to choose a gameplay difficulty.")
                Text("Players younger than 6 should play with an adult.")
                    .font(.system(size: 11))
                    .foregroundStyle(Art.faded)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var privacy: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(Art.mint)
            VStack(alignment: .leading, spacing: 7) {
                Text("YOUR AGE STAYS PRIVATE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                Text("Your exact age is NOT saved or sent to the developers. It's used here only to choose your game difficulty.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Art.paper)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Only the resulting difficulty setting is saved on this device so you won't be asked again. You can change it anytime in Settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Art.mint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15)
            .stroke(Art.mint.opacity(0.42), lineWidth: 1.5))
    }
}
