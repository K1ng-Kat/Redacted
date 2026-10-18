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
}

struct HomeView: View {
    @ObservedObject var store: InvestigationStore
    let openCase: () -> Void
    @State private var showArchive = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    identity
                    caseFeature
                    quickActions
                    footer
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 45)
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
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Noir.accent)
                    .frame(width: 40, height: 40)
                    .background(Noir.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("R // D")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(Noir.ivory)
                    FileLabel(text: "Investigations division")
                }
            }
            Spacer()
            Button {
                Feedback.tap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 19))
                    .foregroundStyle(Noir.ivory)
                    .frame(width: 44, height: 44)
                    .background(Noir.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Noir.line, lineWidth: 1))
            }
            .accessibilityLabel("Settings")
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Circle().fill(Noir.accent).frame(width: 6, height: 6)
                FileLabel(text: "Restricted access · Personnel only", color: Noir.accent)
            }
            Text("REDACTED")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .tracking(1.5)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(Noir.ivory)
            Text("Every story leaves a trace.\nEvery suspect has something to hide.")
                .font(.system(size: 15))
                .foregroundStyle(Noir.muted)
                .lineSpacing(4)
        }
        .padding(.top, 12)
    }

    private var caseFeature: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [
                    Color(red: 0.26, green: 0.075, blue: 0.095),
                    Color(red: 0.12, green: 0.11, blue: 0.15),
                    Noir.card
                ], startPoint: .topLeading, endPoint: .bottomTrailing)

                Circle()
                    .stroke(Noir.accent.opacity(0.2), lineWidth: 1)
                    .frame(width: 260, height: 260)
                    .offset(x: 205, y: -80)
                Circle()
                    .stroke(Noir.accent.opacity(0.16), lineWidth: 1)
                    .frame(width: 195, height: 195)
                    .offset(x: 235, y: -46)

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        FileLabel(text: "Active dossier / 001", color: Noir.ivory.opacity(0.8))
                        Spacer()
                        StatusPill(title: store.state.caseClosed ? "Resolved" : "Unsolved",
                                   highlighted: store.state.caseClosed)
                    }
                    Spacer(minLength: 14)
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 49, weight: .ultraLight))
                        .foregroundStyle(Noir.ivory.opacity(0.65))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE MISSING\nARCHIVE")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(Noir.ivory)
                            .fixedSize(horizontal: false, vertical: true)
                        FileLabel(text: "Northpoint Research / 21:16", color: Noir.ivory.opacity(0.64))
                    }
                }
                .padding(23)
            }
            .frame(height: 280)
            .clipped()

            VStack(alignment: .leading, spacing: 18) {
                Text("A research drive vanishes during a six-minute camera blackout. Three suspects. One truth.")
                    .font(.system(size: 14))
                    .foregroundStyle(Noir.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if store.state.started {
                    HStack {
                        FileLabel(text: "Investigation progress")
                        Spacer()
                        Text("\(Int(store.progressFraction * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Noir.ivory)
                    }
                    ProgressTrack(progress: store.progressFraction)
                }

                RedButton(
                    text: store.state.caseClosed ? "Review solved case" :
                        (store.state.started ? "Continue investigation" : "Begin investigation"),
                    symbol: "arrow.up.right"
                ) {
                    Feedback.tap()
                    store.start()
                    openCase()
                }
            }
            .padding(21)
            .background(Noir.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(Noir.line, lineWidth: 1))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 13) {
            FileLabel(text: "Department")
            Button {
                Feedback.tap()
                showArchive = true
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 22))
                        .foregroundStyle(Noir.accent)
                        .frame(width: 43, height: 43)
                        .background(Noir.accent.opacity(0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Case Archive")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Noir.ivory)
                        Text("Browse available investigations")
                            .font(.system(size: 12))
                            .foregroundStyle(Noir.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Noir.muted)
                }
                .padding(17)
                .background(Noir.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Noir.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        HStack {
            FileLabel(text: "R/D · Secure terminal")
            Spacer()
            FileLabel(text: "Build 0.1")
        }
        .padding(.top, 4)
    }

    private var archiveSheet: some View {
        ZStack {
            RedactedBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeading(kicker: "Records Division", title: "Case Archive",
                                   subtitle: "Investigations stored on this device.")
                    FileCard {
                        VStack(alignment: .leading, spacing: 12) {
                            StatusPill(title: store.state.caseClosed ? "Solved" : "Available",
                                       highlighted: store.state.caseClosed)
                            Text("001 / THE MISSING ARCHIVE")
                                .font(.system(size: 19, weight: .bold, design: .monospaced))
                                .foregroundStyle(Noir.ivory)
                            Text("Northpoint Research · Evidence theft")
                                .foregroundStyle(Noir.muted)
                            RedButton(text: "Open file") {
                                showArchive = false
                                store.start()
                                openCase()
                            }
                        }
                    }
                    FileCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 7) {
                                FileLabel(text: "Case 002 · Classified")
                                Text("More investigations are planned.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Noir.muted)
                            }
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Noir.muted)
                        }
                    }
                }
                .padding(24)
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
                VStack(alignment: .leading, spacing: 22) {
                    SectionHeading(kicker: "Preferences", title: "Terminal Settings",
                                   subtitle: "Local options for your detective profile.")
                    FileCard {
                        Toggle(isOn: $haptics) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Haptic feedback")
                                    .foregroundStyle(Noir.ivory)
                                Text("Vibrate lightly when interacting")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Noir.muted)
                            }
                        }
                        .tint(Noir.accent)
                    }
                    FileCard {
                        VStack(alignment: .leading, spacing: 8) {
                            FileLabel(text: "Privacy & storage")
                            Text("Your case progress is saved locally on this device. This version has no accounts, analytics, or online matches.")
                                .font(.system(size: 13))
                                .foregroundStyle(Noir.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    RedButton(text: "Reset investigation", symbol: "arrow.counterclockwise", fill: false) {
                        confirmReset = true
                    }
                    FileLabel(text: "Redacted · Prototype 0.1")
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Delete your investigation progress?",
                            isPresented: $confirmReset,
                            titleVisibility: .visible) {
            Button("Delete Progress", role: .destructive) {
                store.reset()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Collected evidence, interviews, and case conclusions will be erased from this device.")
        }
    }
}
