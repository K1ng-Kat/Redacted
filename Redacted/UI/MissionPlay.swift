import SwiftUI

struct MissionPlayView: View {
    @ObservedObject var store: CampaignStore
    let mission: CampaignMission
    let back: () -> Void
    let next: () -> Void

    @AppStorage("redacted.fx.hints") private var hintsEnabled = true
    @State private var selectedSequence: [Int] = []
    @State private var typed = ""
    @State private var usedLetterIndices: [Int] = []
    @State private var frequency: Double = 50
    @State private var matchedItems: Set<Int> = []
    @State private var mistakes = 0
    @State private var hintUsed = false
    @State private var hintVisible = false
    @State private var feedback: String?
    @State private var payout: CasePayout?
    @State private var showHowToPlay = false

    private var scrambled: [Character] { Array(mission.solution.reversed()) }

    var body: some View {
        ZStack {
            GameBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let payout {
                        victory(payout)
                    } else {
                        missionIntro
                        if let feedback {
                            GameCard(accent: Art.coral) {
                                HStack(alignment: .top, spacing: 11) {
                                    Image(systemName: "exclamationmark.bubble.fill")
                                        .foregroundStyle(Art.gold)
                                    Text(feedback)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Art.paper)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        puzzle
                        if hintVisible {
                            GameCard(accent: Art.gold) {
                                VStack(alignment: .leading, spacing: 7) {
                                    GameKicker(text: "DETECTIVE'S HINT", color: Art.gold)
                                    Text(mission.hint)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Art.paper)
                                }
                            }
                        }
                        helpControls
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if mission.id == 1 && !store.progress.tutorialComplete {
                showHowToPlay = true
            }
        }
        .alert("WELCOME TO REDACTED", isPresented: $showHowToPlay) {
            Button("LET'S PLAY") { store.tutorialSeen() }
        } message: {
            Text("Solve one mystery per level. Follow the instruction above the puzzle, tap to interact, and earn coins and XP when you win. You can always use a hint or go back to the level map.")
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            Button {
                GameEffects.shared.tap()
                back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Art.paper)
                    .frame(width: 44, height: 44)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Art.edge, lineWidth: 1.3))
            }
            .buttonStyle(PressGameStyle())
            .accessibilityLabel("Back to level map")
            VStack(alignment: .leading, spacing: 4) {
                GameKicker(text: "LEVEL \(mission.id) / 100", color: Art.gold)
                Text("DISTRICT \(mission.episode + 1)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Art.paper)
            }
            Spacer()
            StatChip(icon: "circle.hexagongrid.fill", value: "\(store.coins)", label: "COINS")
        }
    }

    private var missionIntro: some View {
        VStack(alignment: .leading, spacing: 13) {
            ZStack(alignment: .bottomLeading) {
                DistrictIllustration(episode: mission.episode)
                LinearGradient(colors: [.clear, Art.ink.opacity(0.9)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 7) {
                    GameKicker(text: mission.kind.title, color: Art.gold)
                    GameTitle(text: mission.title, size: 28)
                }
                .padding(19)
            }
            .frame(height: 178)
            .clipShape(RoundedRectangle(cornerRadius: 19))
            GameCard(accent: Art.cyan) {
                VStack(alignment: .leading, spacing: 9) {
                    GameKicker(text: "CASE BRIEF", color: Art.cyan)
                    Text(mission.setup)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Art.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "hand.point.up.left.fill")
                            .foregroundStyle(Art.gold)
                        Text(mission.kind.instruction)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Art.faded)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var puzzle: some View {
        switch mission.kind {
        case .findClue:
            spotScene
        case .timeline:
            timelinePuzzle
        case .keypad:
            keypadPuzzle
        case .contradiction, .anomaly, .escapeRoute, .verdict:
            choicePuzzle
        case .anagram:
            wordPuzzle
        case .signal:
            signalPuzzle
        case .connect:
            connectionPuzzle
        }
    }

    private var spotScene: some View {
        VStack(alignment: .leading, spacing: 10) {
            GameKicker(text: "SEARCH THE SCENE", color: Art.gold)
            ZStack {
                DistrictIllustration(episode: mission.episode)
                VStack(spacing: 52) {
                    HStack(spacing: 25) {
                        objectButton(index: 0, symbol: "lock.doc.fill")
                        Spacer()
                        objectButton(index: 1, symbol: "camera.metering.center.weighted")
                    }
                    HStack(spacing: 25) {
                        objectButton(index: 2, symbol: "shippingbox.fill")
                        Spacer()
                        objectButton(index: 3, symbol: "magnifyingglass.circle.fill")
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 40)
            }
            .frame(height: 330)
            .clipShape(RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(Art.edge.opacity(0.7), lineWidth: 2))
            Text("Tap a glowing object to inspect it.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Art.faded)
        }
    }

    private func objectButton(index: Int, symbol: String) -> some View {
        Button {
            GameEffects.shared.tap()
            check(index == mission.correctIndex)
        } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(Art.ink)
                    .frame(width: 66, height: 66)
                    .background(Art.gold)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                Text(mission.choices[index].uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 117)
                    .frame(minHeight: 32)
                    .padding(5)
                    .background(Art.ink.opacity(0.93))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
        .buttonStyle(PressGameStyle())
        .accessibilityLabel("Inspect \(mission.choices[index])")
    }

    private var timelinePuzzle: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                GameKicker(text: "TAP IN CHRONOLOGICAL ORDER", color: Art.gold)
                Spacer()
                Text("\(selectedSequence.count)/4")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Art.paper)
            }
            ForEach(mission.choices.indices, id: \.self) { index in
                let chosenPosition = selectedSequence.firstIndex(of: index)
                Button {
                    guard chosenPosition == nil else { return }
                    GameEffects.shared.tap()
                    selectedSequence.append(index)
                    if selectedSequence.count == 4 {
                        let correct = selectedSequence == mission.correctSequence
                        if !correct { selectedSequence = [] }
                        check(correct, wrongText: "Timeline incorrect. Try ordering the four events again.")
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Art.gold)
                        Text(mission.choices[index])
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Art.paper)
                        Spacer(minLength: 0)
                        if let chosenPosition {
                            Text("\(chosenPosition + 1)")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(Art.ink)
                                .frame(width: 35, height: 35)
                                .background(Art.mint)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "circle.dotted")
                                .foregroundStyle(Art.faded)
                        }
                    }
                    .padding(15)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(chosenPosition != nil ? Art.mint : Art.edge.opacity(0.7), lineWidth: 1.4))
                }
                .buttonStyle(PressGameStyle())
                .disabled(chosenPosition != nil)
            }
            GameButton(title: "Clear my order", icon: "arrow.counterclockwise",
                       color: Art.blueLight, bottom: Art.blueDeep) {
                selectedSequence = []
                feedback = nil
            }
        }
    }

    private var keypadPuzzle: some View {
        VStack(spacing: 17) {
            GameCard(accent: Art.gold) {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Art.gold)
                    Spacer()
                    Text(String(repeating: "•", count: typed.count) +
                         String(repeating: "–", count: max(0, 3 - typed.count)))
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                        .tracking(8)
                        .foregroundStyle(Art.paper)
                    Spacer()
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(Art.gold)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)], spacing: 13) {
                ForEach(1...9, id: \.self) { digit in
                    digitKey("\(digit)")
                }
                digitKey("DEL")
                digitKey("0")
                digitKey("GO")
            }
        }
    }

    private func digitKey(_ title: String) -> some View {
        Button {
            GameEffects.shared.tap()
            if title == "DEL" {
                if !typed.isEmpty { typed.removeLast() }
            } else if title == "GO" {
                if typed.count == 3 {
                    let valid = typed == mission.solution
                    if !valid { typed = "" }
                    check(valid, wrongText: "That combination didn't unlock it. Try the clue in the case brief.")
                }
            } else if typed.count < 3 {
                typed += title
            }
        } label: {
            Text(title)
                .font(.system(size: title == "GO" ? 21 : 28, weight: .black, design: .rounded))
                .foregroundStyle(title == "GO" ? Art.ink : Art.paper)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(title == "GO" ? Art.gold : Art.blueLight)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15)
                    .stroke(.white.opacity(0.24), lineWidth: 1.5))
        }
        .buttonStyle(PressGameStyle())
        .accessibilityLabel(title == "DEL" ? "Delete digit" : title == "GO" ? "Try code" : "Digit \(title)")
    }

    private var choicePuzzle: some View {
        VStack(alignment: .leading, spacing: 13) {
            GameKicker(text: mission.isFinale ? "FINAL ACCUSATION" : "CHOOSE YOUR ANSWER", color: Art.gold)
            ForEach(mission.choices.indices, id: \.self) { index in
                Button {
                    GameEffects.shared.tap()
                    check(index == mission.correctIndex)
                } label: {
                    HStack(spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(Art.ink)
                            .frame(width: 44, height: 44)
                            .background(mission.isFinale ? Art.coral : Art.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Text(mission.choices[index])
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Art.paper)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Art.gold)
                    }
                    .padding(13)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Art.edge.opacity(0.65), lineWidth: 1.5))
                }
                .buttonStyle(PressGameStyle())
            }
        }
    }

    private var wordPuzzle: some View {
        VStack(alignment: .leading, spacing: 17) {
            GameKicker(text: "TAP THE LETTERS IN THE RIGHT ORDER", color: Art.gold)
            GameCard(accent: Art.cyan) {
                Text(usedLetterIndices.map { String(scrambled[$0]) }.joined().uppercased() +
                     String(repeating: " _", count: scrambled.count - usedLetterIndices.count))
                    .font(.system(size: 29, weight: .black, design: .monospaced))
                    .tracking(5)
                    .foregroundStyle(Art.paper)
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                ForEach(scrambled.indices, id: \.self) { index in
                    Button {
                        guard !usedLetterIndices.contains(index) else { return }
                        GameEffects.shared.tap()
                        usedLetterIndices.append(index)
                        if usedLetterIndices.count == scrambled.count {
                            let attempt = usedLetterIndices.map { String(scrambled[$0]) }.joined()
                            if attempt != mission.solution { usedLetterIndices = [] }
                            check(attempt == mission.solution, wrongText: "Those letters aren't in the correct order. Try again.")
                        }
                    } label: {
                        Text(String(scrambled[index]))
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(Art.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                            .background(usedLetterIndices.contains(index) ? Art.faded : Art.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(usedLetterIndices.contains(index))
                    .buttonStyle(PressGameStyle())
                }
            }
            GameButton(title: "Clear letters", icon: "arrow.counterclockwise",
                       color: Art.blueLight, bottom: Art.blueDeep) {
                usedLetterIndices = []
                feedback = nil
            }
        }
    }

    private var signalPuzzle: some View {
        VStack(alignment: .leading, spacing: 17) {
            GameCard(accent: Art.cyan) {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(Art.cyan)
                    Text("\(Int(frequency)) MHz")
                        .font(.system(size: 37, weight: .black, design: .monospaced))
                        .foregroundStyle(Art.paper)
                    Slider(value: $frequency, in: 0...100, step: 5)
                        .tint(Art.gold)
                        .accessibilityLabel("Radio frequency")
                    HStack {
                        GameKicker(text: "0 MHz")
                        Spacer()
                        GameKicker(text: "100 MHz")
                    }
                }
            }
            GameButton(title: "Lock frequency", icon: "waveform.path") {
                check(abs(frequency - mission.expectedFrequency) < 2.6,
                      wrongText: "No clear signal at this frequency. Try the frequency mentioned in the case.")
            }
        }
    }

    private var connectionPuzzle: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                GameKicker(text: "PICK TWO CONNECTED EVIDENCE ITEMS", color: Art.gold)
                Spacer()
                Text("\(matchedItems.count)/2")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Art.paper)
            }
            ForEach(mission.choices.indices, id: \.self) { index in
                Button {
                    GameEffects.shared.tap()
                    if matchedItems.contains(index) {
                        matchedItems.remove(index)
                    } else if matchedItems.count < 2 {
                        matchedItems.insert(index)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: matchedItems.contains(index) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 25))
                            .foregroundStyle(matchedItems.contains(index) ? Art.mint : Art.gold)
                        Text(mission.choices[index])
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Art.paper)
                        Spacer()
                    }
                    .padding(17)
                    .background(Art.blueDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(matchedItems.contains(index) ? Art.mint : Art.edge.opacity(0.6), lineWidth: 1.5))
                }
                .buttonStyle(PressGameStyle())
            }
            GameButton(title: "Connect clues", icon: "link", inactive: matchedItems.count != 2) {
                let correct = matchedItems == mission.pairIndices
                if !correct { matchedItems = [] }
                check(correct, wrongText: "These two items don't establish a connection. Try another pair.")
            }
        }
    }

    private var helpControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hintsEnabled && !hintVisible {
                GameButton(
                    title: store.hintTickets > 0 ? "USE FREE HINT (\(store.hintTickets))" :
                        "BUY HINT · \(CampaignStore.hintPrice) COINS",
                    icon: "lightbulb.fill", color: Art.blueLight, bottom: Art.blueDeep,
                    inactive: store.hintTickets == 0 && store.coins < CampaignStore.hintPrice
                ) {
                    if store.redeemHint() {
                        hintVisible = true
                        hintUsed = true
                        GameEffects.shared.success()
                    }
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Art.cyan)
                Text("Solve to earn XP, coins, and stars. Every cleared case unlocks the next one. Hints can reduce your star rating.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Art.faded)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func victory(_ payout: CasePayout) -> some View {
        VStack(alignment: .leading, spacing: 19) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(Art.mint)
                GameTitle(text: "CASE CLOSED!", size: 38)
                StarStrip(earned: payout.stars, size: 46)
                Text(payout.firstClear ? "NEW LEVEL COMPLETE!" : "CASE REPLAYED!")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Art.cyan)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)

            GameCard(accent: Art.gold) {
                VStack(alignment: .leading, spacing: 14) {
                    GameKicker(text: "WHAT YOU DISCOVERED", color: Art.gold)
                    Text(mission.outcome)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Art.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 10) {
                rewardTile(icon: "circle.hexagongrid.fill", text: "+\(payout.earnedCoins)", label: "COINS", color: Art.gold)
                rewardTile(icon: "bolt.circle.fill", text: "+\(payout.earnedXP)", label: "XP", color: Art.cyan)
            }
            if payout.levelsGained > 0 {
                GameCard(accent: Art.mint) {
                    VStack(alignment: .leading, spacing: 9) {
                        GameKicker(text: "DETECTIVE LEVEL UP!", color: Art.mint)
                        GameTitle(text: "LEVEL \(payout.newRank) REACHED", size: 24)
                        Text("+60 bonus coins and +1 free hint per rank gained are included in your rewards.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Art.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("New ranks also unlock profile titles and selectable color themes.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Art.faded)
                    }
                }
            }
            if store.allCompleted || mission.id == 100 {
                GameButton(title: "Return to HQ", icon: "house.fill", action: back)
            } else {
                GameButton(title: "NEXT LEVEL", icon: "arrow.right", action: next)
            }
            GameButton(title: "LEVEL MAP", icon: "square.grid.2x2.fill",
                       color: Art.blueLight, bottom: Art.blueDeep, action: back)
        }
    }

    private func rewardTile(icon: String, text: String, label: String, color: Color) -> some View {
        GameCard(accent: color) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 29))
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Art.paper)
                    GameKicker(text: label, color: Art.faded)
                }
            }
        }
    }

    private func check(_ success: Bool, wrongText: String? = nil) {
        guard payout == nil else { return }
        if success {
            GameEffects.shared.success()
            feedback = nil
            payout = store.complete(mission.id, mistakes: mistakes, hintUsed: hintUsed)
        } else {
            mistakes += 1
            GameEffects.shared.mistake()
            feedback = wrongText ?? "Not quite. Examine the case brief and try again. You'll get it."
        }
    }
}
