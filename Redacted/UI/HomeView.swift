import SwiftUI
import UIKit

enum Feedback {
    static func tap() {
        let enabled = UserDefaults.standard.object(forKey: "redacted.haptics") as? Bool ?? true
        if enabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    static func success() {
        let enabled = UserDefaults.standard.object(forKey: "redacted.haptics") as? Bool ?? true
        if enabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    static func reward() {
        let enabled = UserDefaults.standard.object(forKey: "redacted.haptics") as? Bool ?? true
        if enabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
}

struct HomeView: View {
    @ObservedObject var store: InvestigationStore
    let openCase: () -> Void
    @State private var showArchive = false
    @State private var showSettings = false

    // Earned entirely from real actions, not a fake random reward counter.
    private var experience: Int {
        store.evidenceCount * 25 +
        store.interviewedCount * 40 +
        store.deductionCount * 80 +
        (store.state.caseClosed ? 150 : 0)
    }
    private var level: Int { 1 + experience / 200 }
    private var experienceProgress: Double { Double(experience % 200) / 200.0 }

    var body: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    agentPass
                    titleBlock
                    featuredCase
                    gameModes
                    footer
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 35)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showArchive) {
            archiveSheet
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(Noir.accent)
                    .frame(width: 47, height: 47)
                    .rotationEffect(.degrees(-5))
                Image(systemName: "eye.fill")
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(Noir.ivory)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("REDACTED")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Noir.ivory)
                FileLabel(text: "Detective division", color: Noir.cyan)
            }
            Spacer()
            Button {
                Feedback.tap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Noir.ivory)
                    .frame(width: 45, height: 45)
                    .background(Noir.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Noir.line, lineWidth: 2))
            }
            .buttonStyle(TactileButtonStyle())
            .accessibilityLabel("Settings")
        }
    }

    private var agentPass: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Noir.gold)
                    .frame(width: 60, height: 60)
                Image(systemName: "star.shield.fill")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Noir.deep)
            }
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("AGENT LEVEL \(level)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Noir.ivory)
                    Spacer(minLength: 3)
                    Text("\(experience % 200) / 200 XP")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Noir.gold)
                }
                ProgressTrack(progress: experienceProgress)
                FileLabel(text: store.state.caseClosed ? "First case solved · Division recognized" : "Gather clues to earn XP")
            }
        }
        .padding(15)
        .background(Noir.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Noir.line, lineWidth: 1.5))
        .shadow(color: Noir.deep, radius: 0, x: 0, y: 5)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            FileLabel(text: "Incoming transmission", color: Noir.cyan)
            Text("YOUR NEXT\nBIG CASE.")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .tracking(-1.3)
                .foregroundStyle(Noir.ivory)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Text("Investigate. Connect the clues. Expose the truth.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Noir.muted)
        }
        .padding(.top, 5)
    }

    private var featuredCase: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ArchiveIllustration()
                LinearGradient(colors: [.clear, Noir.deep.opacity(0.16), Noir.deep.opacity(0.96)],
                               startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("CASE 001")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(1.7)
                            .foregroundStyle(Noir.deep)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(Noir.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .rotationEffect(.degrees(-3))
                        Spacer()
                        StatusPill(title: store.state.caseClosed ? "Solved" : "High priority",
                                   highlighted: store.state.caseClosed)
                    }
                    Spacer()
                    Text("THE MISSING\nARCHIVE")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                        .shadow(color: Noir.deep, radius: 12)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                        Text("21:16 · NORTHPOINT RESEARCH")
                    }
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Noir.cyan)
                }
                .padding(22)
            }
            .frame(height: 300)
            .clipped()

            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Noir.gold)
                    Text("One stolen drive. Six missing minutes. Three suspects. Can you crack it?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Noir.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if store.state.started {
                    VStack(spacing: 8) {
                        HStack {
                            FileLabel(text: "Investigation completed")
                            Spacer()
                            Text("\(Int(store.progressFraction * 100))%")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(Noir.gold)
                        }
                        ProgressTrack(progress: store.progressFraction)
                    }
                }

                RedButton(
                    text: store.state.caseClosed ? "Review your victory" :
                        (store.state.started ? "Resume the case" : "Start investigating"),
                    symbol: "arrow.up.right"
                ) {
                    Feedback.reward()
                    store.start()
                    openCase()
                }
            }
            .padding(19)
            .background(Noir.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Noir.line, lineWidth: 2))
        .shadow(color: Noir.deep, radius: 0, x: 0, y: 8)
    }

    private var gameModes: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionHeading(kicker: "Headquarters", title: "YOUR DESK",
                           subtitle: "Everything you need to solve the next case.")
            ActionTile(symbol: "tray.full.fill", name: "Case collection",
                       note: "Browse your investigations", color: Noir.cyan) {
                Feedback.tap()
                showArchive = true
            }
            ActionTile(symbol: "slider.horizontal.3", name: "Options",
                       note: "Haptics and saved progress", color: Noir.gold) {
                Feedback.tap()
                showSettings = true
            }
        }
    }

    private var footer: some View {
        HStack {
            FileLabel(text: "Division // 001")
            Spacer()
            FileLabel(text: "Prototype · 0.2")
        }
        .padding(.top, 8)
    }

    private var archiveSheet: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeading(kicker: "Missions", title: "CASE COLLECTION",
                                   subtitle: "Each investigation is a new story to unravel.")
                    FileCard(highlighted: true) {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                StatusPill(title: store.state.caseClosed ? "Completed" : "Playable",
                                           highlighted: store.state.caseClosed)
                                Spacer()
                                FileLabel(text: "01 / 01")
                            }
                            Text("001 / THE MISSING ARCHIVE")
                                .font(.system(size: 21, weight: .black, design: .rounded))
                                .foregroundStyle(Noir.ivory)
                            Text("Northpoint Research · The midnight theft")
                                .font(.system(size: 13))
                                .foregroundStyle(Noir.muted)
                            RedButton(text: store.state.started ? "Continue case" : "Open case") {
                                showArchive = false
                                store.start()
                                openCase()
                            }
                        }
                    }
                    FileCard {
                        HStack(spacing: 15) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 31))
                                .foregroundStyle(Noir.muted)
                            VStack(alignment: .leading, spacing: 7) {
                                FileLabel(text: "Case 002 · Incoming")
                                Text("A new mystery is coming later.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Noir.muted)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: InvestigationStore
    @AppStorage("redacted.haptics") private var haptics = true
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    SectionHeading(kicker: "Headquarters", title: "GAME SETTINGS",
                                   subtitle: "Tune your detective experience.")
                    FileCard {
                        Toggle(isOn: $haptics) {
                            HStack(spacing: 13) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Noir.gold)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Game feel")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Noir.ivory)
                                    Text("Enable haptic feedback")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Noir.muted)
                                }
                            }
                        }
                        .tint(Noir.green)
                    }
                    FileCard {
                        VStack(alignment: .leading, spacing: 11) {
                            FileLabel(text: "Your save data", color: Noir.cyan)
                            Text("Your clues, interviews and deductions are saved automatically on this iPhone.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Noir.ivory)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("This build is offline-only. It does not use accounts, advertising or analytics.")
                                .font(.system(size: 12))
                                .foregroundStyle(Noir.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    RedButton(text: "Restart case 001", symbol: "arrow.counterclockwise", fill: false) {
                        confirmReset = true
                    }
                    FileLabel(text: "REDACTED / Build 0.2 / Single-player")
                }
                .padding(24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Erase Case 001 progress?",
                            isPresented: $confirmReset,
                            titleVisibility: .visible) {
            Button("Erase Case Progress", role: .destructive) {
                store.reset()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Collected evidence, interviews, and solved deductions will be erased from this device.")
        }
    }
}
