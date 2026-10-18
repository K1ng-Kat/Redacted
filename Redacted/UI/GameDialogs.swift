import SwiftUI

struct ClueRevealView: View {
    @Environment(\.dismiss) private var dismiss
    let evidence: CaseEvidence

    var body: some View {
        ZStack {
            PlayBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        PlayEyebrow(title: "EVIDENCE ACQUIRED", color: PlayColor.green)
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(PlayColor.green)
                    }
                    .padding(.top, 12)

                    ZStack {
                        RoundedRectangle(cornerRadius: 23)
                            .fill(LinearGradient(
                                colors: [PlayColor.panelTop, PlayColor.midnight],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                        Circle()
                            .fill(PlayColor.yellow.opacity(0.1))
                            .frame(width: 210, height: 210)
                        Circle()
                            .stroke(PlayColor.yellow.opacity(0.35), lineWidth: 2)
                            .frame(width: 147, height: 147)
                        Image(systemName: evidence.category.symbol)
                            .font(.system(size: 85, weight: .black))
                            .foregroundStyle(PlayColor.yellow)
                            .shadow(color: PlayColor.yellow.opacity(0.3), radius: 24)
                    }
                    .frame(height: 215)
                    .overlay(alignment: .topLeading) {
                        Text("CLUE +25 XP")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(PlayColor.midnight)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(PlayColor.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .rotationEffect(.degrees(-5))
                            .padding(14)
                    }

                    PlayEyebrow(title: evidence.category.rawValue + "  ·  " + evidence.time,
                                color: PlayColor.aqua)
                    PlayHeadline(text: evidence.title, size: 28)

                    PlayPanel {
                        VStack(alignment: .leading, spacing: 11) {
                            PlayEyebrow(title: "WHAT YOU FOUND", color: PlayColor.yellow)
                            Text(evidence.contents)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .lineSpacing(5)
                                .foregroundStyle(PlayColor.text)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    PlayPanel {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundStyle(PlayColor.yellow)
                            VStack(alignment: .leading, spacing: 7) {
                                PlayEyebrow(title: "WHY IT MATTERS", color: PlayColor.yellow)
                                Text(evidence.significance)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(PlayColor.text)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    PlayCTA(title: "Back to the scene", icon: "checkmark") {
                        Feedback.tap()
                        dismiss()
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct InterviewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: InvestigationStore
    let suspect: CaseSuspect

    init(suspect: CaseSuspect, store: InvestigationStore) {
        self.suspect = suspect
        self.store = store
    }

    private var talked: Bool {
        suspect.questions.contains(where: { store.hasAsked($0.id) })
    }

    var body: some View {
        ZStack {
            PlayBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 17) {
                    PlayEyebrow(title: "INTERROGATION ROOM", color: PlayColor.yellow)
                        .padding(.top, 12)
                    HStack(alignment: .center, spacing: 16) {
                        SuspectPortrait(suspectID: suspect.id, size: 116)
                        VStack(alignment: .leading, spacing: 5) {
                            PlayHeadline(text: suspect.name, size: 25)
                            Text(suspect.position.uppercased())
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(PlayColor.aqua)
                        }
                        Spacer(minLength: 0)
                    }

                    PlayPanel {
                        VStack(alignment: .leading, spacing: 9) {
                            PlayEyebrow(title: "INITIAL STATEMENT", color: PlayColor.aqua)
                            Text("“\(suspect.statement)”")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(PlayColor.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    PlayHeadline(text: "ASK A QUESTION", size: 23)
                    Text("Tap a question to hear their answer.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlayColor.secondary)

                    ForEach(suspect.questions) { prompt in
                        VStack(alignment: .leading, spacing: 9) {
                            Button {
                                guard !store.hasAsked(prompt.id) else { return }
                                Feedback.success()
                                store.ask(prompt.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: store.hasAsked(prompt.id) ?
                                          "checkmark.circle.fill" : "bubble.left.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(store.hasAsked(prompt.id) ? PlayColor.green : PlayColor.yellow)
                                    Text(prompt.question)
                                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                                        .foregroundStyle(PlayColor.text)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                    if !store.hasAsked(prompt.id) {
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(PlayColor.yellow)
                                    }
                                }
                                .padding(16)
                                .background(PlayColor.panelTop)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(PlayColor.outline, lineWidth: 1.5))
                            }
                            .buttonStyle(PlayPress())
                            if store.hasAsked(prompt.id) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "quote.bubble.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(PlayColor.aqua)
                                    Text(prompt.reply)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(PlayColor.text)
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(15)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(PlayColor.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .transition(.opacity.combined(with: .offset(y: -6)))
                            }
                        }
                    }

                    if talked {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundStyle(PlayColor.yellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("INTERVIEW COMPLETE!")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(PlayColor.text)
                                Text("+40 XP earned for questioning this suspect.")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(PlayColor.secondary)
                            }
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PlayColor.green.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(PlayColor.green.opacity(0.6), lineWidth: 1.5))
                    }

                    PlayCTA(title: talked ? "Interview done" : "Back to suspects",
                            icon: talked ? "checkmark" : "arrow.left") {
                        Feedback.tap()
                        dismiss()
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}
