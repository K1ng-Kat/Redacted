import SwiftUI

/// Original REDACTED startup presentation.
/// Progress is driven by ContentView's actual local preparation checkpoints.
struct StartupLoadingView: View {
    let progress: Double
    let stage: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GameBackdrop()

                // Dramatic dossier art: vault door, floating case card, fingerprint
                // and a scanner reticle, all vector-based and bundled in code.
                VStack(spacing: 0) {
                    topEmblem
                    Spacer(minLength: 18)
                    hero
                        .frame(maxWidth: 460)
                    Spacer(minLength: 32)
                    bottomLoader
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 25)
                .padding(.top, max(24, geometry.safeAreaInsets.top + 12))
                .padding(.bottom, max(25, geometry.safeAreaInsets.bottom + 14))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    private var topEmblem: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.fill")
                .font(.system(size: 23, weight: .black))
                .foregroundStyle(Art.paper)
                .frame(width: 48, height: 48)
                .background(Art.coral)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .rotationEffect(.degrees(-5))
            VStack(alignment: .leading, spacing: 3) {
                Text("REDACTED")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .tracking(-0.7)
                    .foregroundStyle(Art.paper)
                GameKicker(text: "DETECTIVE AGENCY", color: Art.cyan)
            }
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 21))
                .foregroundStyle(Art.gold)
        }
    }

    private var hero: some View {
        VStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 45)
                    .fill(Art.ink.opacity(0.74))
                    .frame(width: 272, height: 330)
                    .rotationEffect(.degrees(11))
                    .overlay {
                        RoundedRectangle(cornerRadius: 45)
                            .stroke(Art.cyan.opacity(0.28), lineWidth: 4)
                            .frame(width: 272, height: 330)
                            .rotationEffect(.degrees(11))
                    }
                RoundedRectangle(cornerRadius: 29)
                    .fill(
                        LinearGradient(colors: [Art.blueLight, Art.blueDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 256, height: 317)
                    .rotationEffect(.degrees(-7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 29)
                            .stroke(Art.gold.opacity(0.75), lineWidth: 4)
                            .frame(width: 256, height: 317)
                            .rotationEffect(.degrees(-7))
                    }
                Image(systemName: "fingerprint")
                    .font(.system(size: 150, weight: .ultraLight))
                    .foregroundStyle(Art.gold)
                    .rotationEffect(.degrees(-7))
                    .shadow(color: Art.gold.opacity(0.32), radius: 26)
                    .scaleEffect(shimmer ? 1.035 : 0.975)

                Image(systemName: "viewfinder")
                    .font(.system(size: 225, weight: .ultraLight))
                    .foregroundStyle(Art.cyan.opacity(0.35))
                    .rotationEffect(.degrees(-7))

                Text("CLASSIFIED")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Art.paper)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Art.coral)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .rotationEffect(.degrees(-13))
                    .offset(x: -61, y: 133)
            }
            .frame(height: 350)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                GameTitle(text: "EVERY CLUE COUNTS.", size: 28)
                    .multilineTextAlignment(.center)
                Text("YOUR NEXT MYSTERY IS WAITING.")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Art.cyan)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var bottomLoader: some View {
        VStack(spacing: 16) {
            // One Animatable number drives BOTH the percentage and the fill.
            // SwiftUI interpolates it on every rendered frame; they cannot
            // independently jump between the loading milestones anymore.
            AnimatedLoadingMeter(progress: progress, reduceMotion: reduceMotion)
                .animation(reduceMotion ? nil : .linear(duration: 1.05), value: progress)

            Text(stage.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(Art.faded)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            GameKicker(text: "© REDACTED · INVESTIGATIONS DIVISION", color: Art.faded)
                .padding(.top, 4)
        }
        .frame(maxWidth: 580)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading game")
        .accessibilityValue("\(Int(progress * 100)) percent, \(stage)")
    }
}

/// Animatable conformance delivers the intermediate fraction on each frame;
/// Text is derived from that same fraction as the filled width.
private struct AnimatedLoadingMeter: View, Animatable {
    var progress: Double
    let reduceMotion: Bool

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var fraction: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                GameKicker(text: "INITIALIZING CASE FILES", color: Art.gold)
                Spacer()
                Text("\(Int((fraction * 100).rounded(.down)))%")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Art.ink)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Art.gold, Art.coral],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geometry.size.width * fraction))
                        .overlay(alignment: .top) {
                            Capsule().fill(Color.white.opacity(0.28))
                                .frame(height: 3)
                                .padding(.top, 3)
                        }
                }
                .overlay(Capsule().stroke(Art.edge, lineWidth: 2.5))
            }
            .frame(height: 23)
            .accessibilityHidden(true)
        }
    }
}
