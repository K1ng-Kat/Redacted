import SwiftUI

struct CaseAdventureView: View {
    @ObservedObject var store: InvestigationStore
    let leaveCase: () -> Void

    @State private var chapter = 0
    @State private var selectedEvidence: CaseEvidence?
    @State private var selectedSuspect: CaseSuspect?
    @State private var pendingAccusation: String?
    @State private var message: String?
    @State private var messageID = UUID()
    @State private var showHint = false

    private let roomTitles = ["THE VAULT", "SECURITY HQ", "DISPATCH", "THE TECH LAB"]
    private let roomDetails = [
        "The door was locked. Something still went missing.",
        "The cameras stopped for exactly six minutes.",
        "A mysterious delivery left at 9:16 PM.",
        "An IT worker claims he never touched the cameras."
    ]
    private let clueIDs = [
        ["access", "door"], ["camera", "roster"],
        ["dispatch", "audit"], ["maintenance", "coffee"]
    ]
    private let clueLabels = [
        ["DOOR LOCK", "FLOOR SCAN"], ["CAMERA FEED", "STAFF LIST"],
        ["PNEUMATIC TUBE", "PRIVATE LETTER"], ["COMPUTER", "COFFEE"]
    ]
    private let clueIcons = [
        ["lock.fill", "waveform.path"], ["video.slash.fill", "person.text.rectangle"],
        ["shippingbox.fill", "envelope.fill"], ["desktopcomputer", "cup.and.saucer.fill"]
    ]
    private let cluePositions: [[CGPoint]] = [
        [CGPoint(x: 0.24, y: 0.51), CGPoint(x: 0.77, y: 0.69)],
        [CGPoint(x: 0.24, y: 0.48), CGPoint(x: 0.76, y: 0.49)],
        [CGPoint(x: 0.28, y: 0.61), CGPoint(x: 0.75, y: 0.43)],
        [CGPoint(x: 0.29, y: 0.39), CGPoint(x: 0.77, y: 0.65)]
    ]

    private var chapterTitle: String {
        if chapter < 4 { return roomTitles[chapter] }
        switch chapter {
        case 4: return "QUESTION TIME"
        case 5: return "CONNECT THE DOTS"
        case 6: return "NAME THE THIEF"
        default: return "CASE CRACKED!"
        }
    }

    private var instruction: String {
        if chapter < 4 {
            return "TAP BOTH GLOWING OBJECTS TO FIND THE CLUES."
        }
        switch chapter {
        case 4: return "QUESTION ALL THREE SUSPECTS."
        case 5: return "PICK THE ANSWERS THAT FIT YOUR EVIDENCE."
        case 6: return "TAP WHO YOU THINK DID IT."
        default: return "YOU FOUND THE TRUTH."
        }
    }

    private var chapterCompleted: Bool { completed(chapter) }
    private var foundInRoom: Int {
        guard chapter < 4 else { return 0 }
        return clueIDs[chapter].filter { store.hasEvidence($0) }.count
    }

    var body: some View {
        ZStack {
            PlayBackground()
            VStack(spacing: 0) {
                topHUD
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        missionHeading
                        if chapter < 4 {
                            roomGame
                        } else if chapter == 4 {
                            interviewGame
                        } else if chapter == 5 {
                            deductionGame
                        } else if chapter == 6 {
                            accusationGame
                        } else {
                            victoryGame
                        }
                        Spacer(minLength: 15)
                    }
                    .id(chapter)
                    .transition(.opacity.combined(with: .offset(x: 16)))
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 17)
                    .padding(.top, 19)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
                bottomAction
            }
            if let message {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 21, weight: .black))
                        Text(message)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(PlayColor.midnight)
                    .padding(15)
                    .background(PlayColor.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(16)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(5)
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { chapter = firstUnfinishedChapter() }
        .sheet(item: $selectedEvidence) { evidence in
            ClueRevealView(evidence: evidence)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedSuspect) { suspect in
            InterviewGameView(suspect: suspect, store: store)
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "ACCUSATION: \(CaseData.suspect(for: pendingAccusation ?? "")?.name ?? "Unknown")",
            isPresented: Binding(
                get: { pendingAccusation != nil },
                set: { if !$0 { pendingAccusation = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Make accusation") {
                if let suspectID = pendingAccusation { accuse(suspectID) }
                pendingAccusation = nil
            }
            Button("Not yet", role: .cancel) { pendingAccusation = nil }
        } message: {
            Text("Look at the camera override, transfer receipt and motive before choosing.")
        }
        .alert("HOW TO PLAY", isPresented: $showHint) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text(hintText)
        }
    }

    private var topHUD: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    Feedback.tap()
                    leaveCase()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(PlayColor.text)
                        .frame(width: 45, height: 45)
                        .background(PlayColor.panelTop)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(PlayColor.outline, lineWidth: 1.5))
                }
                .buttonStyle(PlayPress())
                .accessibilityLabel("Save and return home")

                VStack(alignment: .leading, spacing: 3) {
                    Text("CASE 001")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(PlayColor.text)
                    PlayEyebrow(title: "CHAPTER \(min(chapter + 1, 7)) OF 7")
                }
                Spacer()
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(PlayColor.yellow)
                    Text("\(store.evidenceCount)/8")
                        .foregroundStyle(PlayColor.text)
                }
                .font(.system(size: 15, weight: .black, design: .rounded))
                .padding(.horizontal, 12)
                .frame(height: 41)
                .background(PlayColor.panel)
                .clipShape(Capsule())
            }
            MissionProgress(current: chapter)
        }
        .padding(.horizontal, 17)
        .padding(.top, 9)
        .padding(.bottom, 13)
        .background(PlayColor.midnight.opacity(0.9))
        .overlay(alignment: .bottom) { PlayColor.outline.opacity(0.5).frame(height: 1) }
    }

    private var missionHeading: some View {
        VStack(alignment: .leading, spacing: 7) {
            PlayEyebrow(title: chapter < 4 ? "EXPLORE THE LOCATION" : "THE CASE IS HEATING UP",
                        color: PlayColor.yellow)
            PlayHeadline(text: chapterTitle)
            Text(chapter < 4 ? roomDetails[chapter] : instruction)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PlayColor.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var roomGame: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .bottom) {
                GeometryReader { proxy in
                    ZStack {
                        MysteryRoomArt(room: chapter)
                        ForEach(0..<2, id: \.self) { i in
                            let id = clueIDs[chapter][i]
                            ClueMarker(
                                title: clueLabels[chapter][i],
                                icon: clueIcons[chapter][i],
                                found: store.hasEvidence(id)
                            ) {
                                openClue(id)
                            }
                            .position(
                                x: proxy.size.width * cluePositions[chapter][i].x,
                                y: proxy.size.height * cluePositions[chapter][i].y
                            )
                        }
                    }
                }
                HStack {
                    Image(systemName: "hand.tap.fill")
                    Text(chapterCompleted ? "ALL CLUES FOUND!" : "TAP THE GLOWING CLUES")
                    Spacer()
                    Text("\(foundInRoom)/2")
                }
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(PlayColor.midnight)
                .padding(.horizontal, 13)
                .frame(height: 37)
                .background(chapterCompleted ? PlayColor.green : PlayColor.yellow)
            }
            .frame(height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(chapterCompleted ? PlayColor.green : PlayColor.outline, lineWidth: 2))
            .shadow(color: .black.opacity(0.35), radius: 0, y: 6)

            PlayPanel {
                HStack(spacing: 12) {
                    Image(systemName: chapterCompleted ? "checkmark.shield.fill" : "lightbulb.fill")
                        .font(.system(size: 27, weight: .black))
                        .foregroundStyle(chapterCompleted ? PlayColor.green : PlayColor.yellow)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(chapterCompleted ? "SCENE COMPLETE!" : "YOUR OBJECTIVE")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(PlayColor.text)
                        Text(chapterCompleted
                             ? "Both clues are in your case file. You're ready to move on."
                             : "Tap the two glowing objects above. Each one contains evidence.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PlayColor.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var interviewGame: some View {
        VStack(alignment: .leading, spacing: 18) {
            PlayPanel {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 29))
                        .foregroundStyle(PlayColor.yellow)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("3 PEOPLE. 3 STORIES.")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(PlayColor.text)
                        Text("Tap a portrait. Ask at least one question to each person.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PlayColor.secondary)
                    }
                }
            }
            ForEach(CaseData.suspects) { suspect in
                let interviewed = suspect.questions.contains { store.hasAsked($0.id) }
                Button {
                    Feedback.tap()
                    selectedSuspect = suspect
                } label: {
                    HStack(spacing: 16) {
                        SuspectPortrait(suspectID: suspect.id, size: 94)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(suspect.name.uppercased())
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(PlayColor.text)
                            Text(suspect.position)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(PlayColor.secondary)
                            Text(interviewed ? "✓ QUESTIONED" : "TAP TO INTERVIEW →")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(interviewed ? PlayColor.green : PlayColor.yellow)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: interviewed ? "checkmark.circle.fill" : "chevron.right.circle.fill")
                            .font(.system(size: 23))
                            .foregroundStyle(interviewed ? PlayColor.green : PlayColor.yellow)
                    }
                    .padding(13)
                    .background(PlayColor.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 19))
                    .overlay(RoundedRectangle(cornerRadius: 19)
                        .stroke(interviewed ? PlayColor.green.opacity(0.6) : PlayColor.outline, lineWidth: 2))
                }
                .buttonStyle(PlayPress())
            }
        }
    }

    private var deductionGame: some View {
        VStack(alignment: .leading, spacing: 17) {
            PlayPanel {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 29))
                        .foregroundStyle(PlayColor.yellow)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("PUT THE PIECES TOGETHER")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(PlayColor.text)
                        Text("Use what you found to reconstruct the crime.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PlayColor.secondary)
                    }
                }
            }
            if let puzzle = CaseData.deductions.first(where: { !store.deductionIsSolved($0.id) }) {
                PlayEyebrow(title: "PUZZLE \(store.deductionCount + 1) OF 2",
                            color: PlayColor.yellow)
                PlayHeadline(text: puzzle.question, size: 25)
                ForEach(puzzle.options.indices, id: \.self) { index in
                    Button {
                        Feedback.tap()
                        if store.submitDeduction(puzzle, option: index) {
                            Feedback.success()
                            notify("PERFECT DEDUCTION! +80 XP")
                        } else {
                            Feedback.reward()
                            notify("NOT QUITE. \(puzzle.wrongHint)")
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(String(index + 1))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(PlayColor.midnight)
                                .frame(width: 43, height: 43)
                                .background(PlayColor.aqua)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Text(puzzle.options[index])
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(PlayColor.text)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(PlayColor.yellow)
                        }
                        .padding(13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PlayColor.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(PlayColor.outline, lineWidth: 1.5))
                    }
                    .buttonStyle(PlayPress())
                }
            } else {
                celebrationPanel(title: "DEDUCTIONS COMPLETE",
                                 detail: "You solved the blackout and the escape route. It's time to name the person responsible.")
            }
        }
    }

    private var accusationGame: some View {
        VStack(alignment: .leading, spacing: 18) {
            PlayPanel {
                VStack(alignment: .leading, spacing: 10) {
                    PlayEyebrow(title: "FINAL DECISION", color: PlayColor.yellow)
                    Text("WHO STOLE THE DRIVE?")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(PlayColor.text)
                    Text("You've seen every room and questioned every suspect. Choose carefully.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PlayColor.secondary)
                }
            }
            ForEach(CaseData.suspects) { suspect in
                Button {
                    Feedback.tap()
                    pendingAccusation = suspect.id
                } label: {
                    HStack(spacing: 15) {
                        SuspectPortrait(suspectID: suspect.id, size: 85)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(suspect.name.uppercased())
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(PlayColor.text)
                            Text(suspect.position)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(PlayColor.secondary)
                            Text("ACCUSE →")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(PlayColor.yellow)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(13)
                    .background(PlayColor.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(PlayColor.red.opacity(0.75), lineWidth: 2))
                }
                .buttonStyle(PlayPress())
            }
        }
    }

    private var victoryGame: some View {
        let mistakes = store.state.incorrectDeductions + store.state.incorrectAccusations
        let stars = mistakes == 0 ? 3 : mistakes <= 2 ? 2 : 1
        return VStack(alignment: .leading, spacing: 19) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 70, weight: .black))
                    .foregroundStyle(PlayColor.green)
                PlayHeadline(text: "CASE CLOSED!", size: 37)
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.system(size: 47, weight: .black))
                            .foregroundStyle(i < stars ? PlayColor.yellow : PlayColor.outline)
                    }
                }
                Text(stars == 3 ? "FLAWLESS INVESTIGATION!" :
                        stars == 2 ? "EXCELLENT WORK!" : "YOU FOUND THE TRUTH!")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(PlayColor.aqua)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            PlayPanel {
                VStack(alignment: .leading, spacing: 12) {
                    PlayEyebrow(title: "RESPONSIBLE PARTY", color: PlayColor.yellow)
                    HStack(spacing: 14) {
                        SuspectPortrait(suspectID: "jules", size: 90)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("JULES HART")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(PlayColor.text)
                            Text("HEAD OF SECURITY")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(PlayColor.red)
                        }
                    }
                    Text("Jules deliberately cut the camera feed with credential S02, sent the 740 g research drive through the transfer tube, and used a fabricated network fault as cover.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(PlayColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("MOTIVE: The drive contained records of irregular security payments set to be audited the next morning.")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PlayColor.aqua)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            celebrationPanel(title: "CASE 001 COMPLETE",
                             detail: "Your solution is saved. Revisit this case anytime from the home screen.")
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        VStack(spacing: 0) {
            PlayColor.outline.opacity(0.45).frame(height: 1)
            if chapter == 7 {
                PlayCTA(title: "Back to headquarters", icon: "house.fill", action: leaveCase)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 12)
            } else if chapterCompleted {
                PlayCTA(title: chapter == 5 ? "Find the culprit" :
                        chapter == 4 ? "Solve the mystery" :
                        chapter == 3 ? "Question suspects" : "Next location",
                        icon: "arrow.right") {
                    Feedback.reward()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.83)) {
                        chapter = min(chapter + 1, 7)
                    }
                }
                .padding(.horizontal, 17)
                .padding(.vertical, 12)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "scope")
                        .foregroundStyle(PlayColor.yellow)
                    Text(instruction)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(PlayColor.text)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Button {
                        Feedback.tap()
                        showHint = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle.fill")
                            Text("HELP")
                        }
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(PlayColor.yellow)
                        .padding(9)
                        .background(PlayColor.panelTop)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlayPress())
                }
                .padding(.horizontal, 19)
                .frame(minHeight: 67)
            }
        }
        .background(PlayColor.midnight.opacity(0.98))
    }

    private var hintText: String {
        switch chapter {
        case 0...3: return "Look for the two bouncing yellow buttons inside the room. Tap one to inspect and collect evidence. When both turn green, tap NEXT LOCATION."
        case 4: return "Tap each of the three character cards, then choose any question. Once all three have been interviewed, tap SOLVE THE MYSTERY."
        case 5: return "Read the question and select the answer that matches the clues you found. You can retry if you're wrong."
        case 6: return "Tap a character, then confirm your accusation. You can retry if your accusation isn't supported."
        default: return "You solved the case! Go back to headquarters."
        }
    }

    private func completed(_ index: Int) -> Bool {
        switch index {
        case 0...3:
            return clueIDs[index].allSatisfy { store.hasEvidence($0) }
        case 4: return store.interviewedCount == 3
        case 5: return store.deductionCount == 2
        case 6: return store.state.caseClosed
        default: return true
        }
    }

    private func firstUnfinishedChapter() -> Int {
        for index in 0...6 {
            if !completed(index) { return index }
        }
        return 7
    }

    private func openClue(_ id: String) {
        guard let evidence = CaseData.evidence(for: id) else { return }
        if !store.hasEvidence(id) {
            store.discover(id)
            Feedback.success()
            notify("NEW CLUE FOUND! +25 XP")
        } else {
            Feedback.tap()
        }
        selectedEvidence = evidence
    }

    private func accuse(_ id: String) {
        guard store.canAccuse else {
            notify("FINISH YOUR INVESTIGATION FIRST")
            return
        }
        if store.accuse(id) {
            Feedback.success()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                chapter = 7
            }
        } else {
            Feedback.tap()
            notify("NOT THE CULPRIT. CHECK THE S02 CREDENTIAL.")
        }
    }

    private func notify(_ text: String) {
        let token = UUID()
        messageID = token
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            message = text
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard messageID == token else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                message = nil
            }
        }
    }

    private func celebrationPanel(title: String, detail: String) -> some View {
        PlayPanel {
            HStack(spacing: 13) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(PlayColor.green)
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(PlayColor.text)
                    Text(detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PlayColor.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
