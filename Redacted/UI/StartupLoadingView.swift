import SwiftUI

/// The first interactive game frame. No animated native iOS launch screen:
/// this SwiftUI screen paints before any campaign or SceneKit views are made.
struct StartupLoadingView: View {
    let progress: Double
    let stage: String
    let issue: RedactedLaunchManager.LaunchIssue?
    let retry: () -> Void
    let playOffline: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var breathe = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.035, green: 0.055, blue: 0.12)
                    .ignoresSafeArea()
                LinearGradient(
                    colors: [.clear,
                             Color(red: 0.11, green: 0.20, blue: 0.33).opacity(0.66),
                             .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    Spacer(minLength: 12)

                    classifiedCard
                        .frame(maxWidth: 320)
                        .scaleEffect(geometry.size.height < 670 ? 0.77 : 1)
                        .frame(height: geometry.size.height < 670 ? 245 : 315)

                    VStack(spacing: 8) {
                        Text("EVERY CLUE COUNTS.")
                            .font(.system(size: geometry.size.width < 360 ? 21 : 25,
                                          weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 1, green: 0.98, blue: 0.89))
                        Text("YOUR NEXT MYSTERY IS WAITING")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .tracking(0.9)
                            .foregroundStyle(Color(red: 0.50, green: 0.88, blue: 0.94))
                    }
                    .multilineTextAlignment(.center)

                    Spacer(minLength: 14)

                    VStack(spacing: 14) {
                        AnimatedLoadingMeter(progress: progress)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.48),
                                       value: progress)

                        HStack(spacing: 6) {
                            if issue == nil && progress < 1 {
                                ProgressView()
                                    .tint(Color(red: 0.85, green: 0.74, blue: 0.34))
                                    .scaleEffect(0.65)
                            }
                            Text(stage.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .tracking(0.3)
                                .foregroundStyle(Color(red: 0.75, green: 0.83, blue: 0.92))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: 470)

                    if let issue {
                        connectionOptions(issue)
                            .padding(.top, 13)
                            .frame(maxWidth: 470)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Text("REDACTED · INVESTIGATIONS DIVISION")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.60, green: 0.69, blue: 0.81))
                        .padding(.top, 18)
                }
                .padding(.horizontal, geometry.size.width < 375 ? 18 : 25)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color(red: 0.90, green: 0.26, blue: 0.27))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text("REDACTED")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("DETECTIVE AGENCY")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .tracking(0.7)
                    .foregroundStyle(Color(red: 0.47, green: 0.89, blue: 0.97))
            }
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 19))
                .foregroundStyle(Color(red: 1, green: 0.78, blue: 0.24))
        }
        .accessibilityElement(children: .combine)
    }

    private var classifiedCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(red: 0.09, green: 0.16, blue: 0.26))
                .frame(width: 252, height: 285)
                .rotationEffect(.degrees(8))
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.24, green: 0.32, blue: 0.46),
                             Color(red: 0.07, green: 0.11, blue: 0.19)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 245, height: 284)
                .rotationEffect(.degrees(-5))
                .overlay {
                    RoundedRectangle(cornerRadius: 29, style: .continuous)
                        .strokeBorder(Color(red: 0.90, green: 0.74, blue: 0.34),
                                      lineWidth: 2)
                        .frame(width: 245, height: 284)
                        .rotationEffect(.degrees(-5))
                }
            Image(systemName: "fingerprint")
                .font(.system(size: 142, weight: .ultraLight))
                .foregroundStyle(Color(red: 1, green: 0.81, blue: 0.29))
                .scaleEffect(breathe ? 1.015 : 0.985)

            Text("CLASSIFIED")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color(red: 0.93, green: 0.27, blue: 0.30))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .rotationEffect(.degrees(-12))
                .offset(x: -52, y: 120)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func connectionOptions(_ issue: RedactedLaunchManager.LaunchIssue) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(issue.title, systemImage: issue.kind == .update
                  ? "arrow.down.app.fill" : "wifi.exclamationmark")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0.80, blue: 0.32))
            Text(issue.detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let url = issue.storeURL {
                Button {
                    openURL(url)
                } label: {
                    Label("OPEN APP STORE", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 10) {
                Button(action: retry) {
                    Label("RETRY", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                Button(action: playOffline) {
                    Label("PLAY OFFLINE", systemImage: "airplane")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }
            .font(.system(size: 12, weight: .black, design: .rounded))
            Text("Offline Mode keeps your locally saved cases available. Duels, friends and cloud backup require a connection.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(red: 0.69, green: 0.75, blue: 0.83))
        }
        .padding(14)
        .background(Color(red: 0.10, green: 0.15, blue: 0.24))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(red: 0.51, green: 0.59, blue: 0.73)
                              .opacity(0.52), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

/// The number and fill animate from the exact same interpolated fraction.
private struct AnimatedLoadingMeter: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var fraction: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        VStack(spacing: 11) {
            HStack {
                Text("LOADING INVESTIGATION")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(Color(red: 1, green: 0.78, blue: 0.27))
                Spacer()
                Text("\(min(100, Int((fraction * 100).rounded(.down))))%")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(red: 0.075, green: 0.10, blue: 0.17))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.98, green: 0.80, blue: 0.28),
                                     Color(red: 0.92, green: 0.33, blue: 0.26)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * fraction)
                }
                .overlay {
                    Capsule().stroke(Color(red: 0.36, green: 0.48, blue: 0.62),
                                     lineWidth: 1.5)
                }
            }
            .frame(height: 19)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}
