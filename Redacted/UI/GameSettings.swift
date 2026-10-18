import SwiftUI

struct GameSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: InvestigationStore
    @AppStorage("redacted.haptics") private var haptics = true
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            PlayBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlayEyebrow(title: "DETECTIVE HEADQUARTERS", color: PlayColor.yellow)
                        .padding(.top, 16)
                    PlayHeadline(text: "SETTINGS")
                    PlayPanel {
                        Toggle(isOn: $haptics) {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 27))
                                    .foregroundStyle(PlayColor.yellow)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("HAPTIC FEEDBACK")
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .foregroundStyle(PlayColor.text)
                                    Text("Feel clue discoveries and decisions")
                                        .font(.system(size: 12))
                                        .foregroundStyle(PlayColor.secondary)
                                }
                            }
                        }
                        .tint(PlayColor.green)
                    }
                    PlayPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            PlayEyebrow(title: "SAVED GAME", color: PlayColor.aqua)
                            Text("\(store.evidenceCount) of 8 clues · \(store.interviewedCount) of 3 interviews")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(PlayColor.text)
                            Text("Game progress is stored locally on this iPhone. There's no account or online play in this version.")
                                .font(.system(size: 13))
                                .foregroundStyle(PlayColor.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    PlayCTA(title: "Restart case", icon: "arrow.counterclockwise", secondary: true) {
                        confirmReset = true
                    }
                    PlayCTA(title: "Done", icon: "checkmark") {
                        dismiss()
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Start Case 001 over?", isPresented: $confirmReset,
                            titleVisibility: .visible) {
            Button("Erase progress and restart", role: .destructive) {
                store.reset()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your collected evidence, interviews, deductions and case result.")
        }
    }
}
