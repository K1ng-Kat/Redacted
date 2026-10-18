import SwiftUI

// The player sees one decision on launch: PLAY. Everything else is secondary.
struct GameHomeView: View {
    @ObservedObject var store: InvestigationStore
    let play: () -> Void

    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entrance = false

    private var experience: Int {
        store.evidenceCount * 25 + store.interviewedCount * 40 +
        store.deductionCount * 80 + (store.state.caseClosed ? 150 : 0)
    }

    var body: some View {
        ZStack {
            PlayBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    brandHeader
                    agentBar
                    headline
                    featuredCase
                    footer
                }
                .frame(maxWidth: 580)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            GameSettingsView(store: store)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.8)) {
                    entrance = true
                }
            } else {
                entrance = true
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(PlayColor.red)
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-7))
                Image(systemName: "eye.fill")
                    .font(.system(size: 27, weight: .black))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("REDACTED")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(-0.5)
                    .foregroundStyle(PlayColor.text)
                PlayEyebrow(title: "Detective HQ")
            }
            Spacer()
            Button {
                Feedback.tap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(PlayColor.text)
                    .frame(width: 46, height: 46)
                    .background(PlayColor.panelTop)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(PlayColor.outline, lineWidth: 1.5))
            }
            .buttonStyle(PlayPress())
            .accessibilityLabel("Settings")
        }
    }

    private var agentBar: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(PlayColor.yellow)
                    .frame(width: 49, height: 49)
                Image(systemName: "star.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(PlayColor.midnight)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("DETECTIVE · LVL \(1 + experience / 200)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(PlayColor.text)
                    Spacer()
                    Text("\(experience % 200)/200 XP")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(PlayColor.yellow)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(PlayColor.midnight)
                        Capsule()
                            .fill(PlayColor.yellow)
                            .frame(width: proxy.size.width * CGFloat(experience % 200) / 200)
                    }
                }
                .frame(height: 9)
            }
        }
        .padding(13)
        .background(PlayColor.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(PlayColor.outline.opacity(0.6), lineWidth: 1))
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 5) {
            PlayEyebrow(title: "One case. One truth.", color: PlayColor.yellow)
            PlayHeadline(text: "THE HUNT\nSTARTS HERE.", size: 36)
            Text("Find what everyone else missed.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PlayColor.secondary)
        }
        .offset(y: entrance ? 0 : 15)
        .opacity(entrance ? 1 : 0)
    }

    private var featuredCase: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                MysteryRoomArt(room: 0)
                LinearGradient(colors: [.clear, PlayColor.midnight.opacity(0.1), PlayColor.midnight.opacity(0.97)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CASE #001")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(PlayColor.midnight)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(PlayColor.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                        if store.state.caseClosed {
                            Label("SOLVED", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(PlayColor.green)
                                .font(.system(size: 11, weight: .black))
                        } else {
                            Label("NEW MYSTERY", systemImage: "bolt.fill")
                                .foregroundStyle(PlayColor.yellow)
                                .font(.system(size: 11, weight: .black))
                        }
                    }
                    Spacer()
                    Text("THE MISSING\nARCHIVE")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 8)
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                        Text("6 MINUTES. 3 SUSPECTS.")
                    }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(PlayColor.aqua)
                }
                .padding(20)
            }
            .frame(height: 265)
            .clipped()

            VStack(alignment: .leading, spacing: 14) {
                Text("Someone stole a confidential research drive. Can you catch them?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PlayColor.text)
                    .fixedSize(horizontal: false, vertical: true)

                if store.state.started {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(PlayColor.yellow)
                        Text("\(store.evidenceCount) clues found")
                        Spacer()
                        Text(store.state.caseClosed ? "CASE SOLVED" : "IN PROGRESS")
                            .foregroundStyle(store.state.caseClosed ? PlayColor.green : PlayColor.aqua)
                    }
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(PlayColor.secondary)
                }

                PlayCTA(
                    title: store.state.caseClosed ? "View your victory" :
                        (store.state.started ? "Continue case" : "Play case 001"),
                    icon: "play.fill"
                ) {
                    Feedback.reward()
                    store.start()
                    play()
                }
            }
            .padding(19)
            .background(PlayColor.panel)
        }
        .clipShape(RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(PlayColor.outline, lineWidth: 2))
        .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 7)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(PlayColor.aqua)
            Text("SOLO STORY MODE")
            Spacer()
            Text("REDACTED · 0.3")
        }
        .font(.system(size: 10, weight: .black, design: .monospaced))
        .foregroundStyle(PlayColor.secondary)
        .padding(.top, 4)
    }
}
