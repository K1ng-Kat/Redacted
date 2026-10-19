import Foundation

/// These are gameplay/reading preferences, never verified ages or birth dates.
/// The value stays in local UserDefaults and is not sent to a server.
enum DetectiveAgeMode: String, CaseIterable, Identifiable {
    case junior = "6-8"
    case explorer = "9-12"
    case investigator = "13-15"
    case expert = "16+"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .junior: "Ages 6–8 · Junior"
        case .explorer: "Ages 9–12 · Explorer"
        case .investigator: "Ages 13–15 · Investigator"
        case .expert: "Ages 16+ · Expert"
        }
    }

    var subtitle: String {
        switch self {
        case .junior: "Brief instructions · 2 choices · more clues"
        case .explorer: "Story clues · 3 choices · guided reasoning"
        case .investigator: "Evidence comparisons · 4 choices · transformed codes"
        case .expert: "Multi-step logic · 4 choices · tougher signal and codes"
        }
    }

    var choicesCount: Int {
        switch self {
        case .junior: 2
        case .explorer: 3
        case .investigator, .expert: 4
        }
    }

    var introduction: String {
        switch self {
        case .junior: "You are a detective! Follow the clues one step at a time."
        case .explorer: "A detective notices details. Read the evidence before you decide."
        case .investigator: "Compare testimony to recorded evidence before committing to an answer."
        case .expert: "Look for contradictions, indirect evidence, and the hidden rule in the data."
        }
    }
}

/// Each of the 100 authored stories remains in CampaignCatalog. This layer
/// changes each mission's playable questions, choice pool, and mechanical
/// answers for the four age/reading profiles without creating separate saves.
struct AgeAdjustedMission {
    let mission: CampaignMission
    let mode: DetectiveAgeMode

    var title: String { mission.title }

    private var easierStory: String {
        var text = mission.setup
        let simplerWords: [(String, String)] = [
            ("unauthorized", "not allowed"), ("transmitter", "radio"),
            ("contradicts", "does not match"), ("navigation log", "ship's travel record"),
            ("tamper", "break"), ("manifest", "cargo list"),
            ("counterfeit", "fake"), ("submerged", "underwater"),
            ("dispatch", "delivery"), ("restoration", "repair"),
            ("maintenance", "repair"), ("surveillance", "cameras"),
            ("compartment", "box"), ("frequency", "radio number"),
            ("documentation", "paperwork"), ("infrared", "heat"),
            ("diversion", "secret turn"), ("reassigned", "changed"),
            ("incident", "event"), ("authorization", "permission")
        ]
        for (old, new) in simplerWords {
            text = text.replacingOccurrences(of: old, with: new,
                                              options: [.caseInsensitive])
        }
        return text
    }

    var brief: String {
        switch mode {
        case .junior:
            return easierStory + "\n\n" + simpleQuestion
        case .explorer:
            return mission.setup + "\n\n" + middleQuestion
        case .investigator:
            return mission.setup + "\n\n" + investigatorQuestion
        case .expert:
            return mission.setup + "\n\n" + expertQuestion
        }
    }

    var instruction: String {
        switch mode {
        case .junior:
            switch mission.kind {
            case .findClue: return "Tap the object that looks like an important clue."
            case .timeline: return "Tap what happened first, then next, until all four are in order."
            case .keypad: return "Look at the number in the story. Enter its last 3 digits."
            case .contradiction: return "Which fact shows someone is not telling the truth?"
            case .anomaly: return "Tap the item that doesn't match the others."
            case .escapeRoute: return "Find the secret way someone could leave."
            case .anagram: return "Tap the letters to make the hidden word."
            case .signal: return "Move the radio dial to the number in the story."
            case .connect: return "Pick TWO clues that go together."
            case .verdict: return "Who do you think did it? Use what you learned."
            }
        case .explorer:
            return mission.kind.instruction
        case .investigator:
            switch mission.kind {
            case .keypad: return "Read the final three digits, then enter them BACKWARDS."
            case .signal: return "Tune 10 MHz ABOVE the logged value (wrap past 100 back to 0)."
            default: return mission.kind.instruction + " Use the strongest evidence."
            }
        case .expert:
            switch mission.kind {
            case .keypad: return "Take the last three digits; MOVE THE LAST DIGIT TO THE FRONT."
            case .signal: return "Tune to the MIRROR frequency: 100 minus the logged number."
            default: return mission.kind.instruction + " Eliminate the plausible false leads."
            }
        }
    }

    private var simpleQuestion: String {
        switch mission.kind {
        case .findClue: "Which object has the best clue?"
        case .timeline: "What happened first?"
        case .keypad: "Can you find the three numbers for the lock?"
        case .contradiction: "Which clue shows the story is wrong?"
        case .anomaly: "Which one is different?"
        case .escapeRoute: "Which way could the person sneak out?"
        case .anagram: "What word do the letters make?"
        case .signal: "What number should the radio show?"
        case .connect: "Which two clues belong together?"
        case .verdict: "Who was in charge of this mystery?"
        }
    }

    private var middleQuestion: String {
        switch mission.kind {
        case .timeline: "Use the order of cause and effect to arrange the four events."
        case .contradiction: "Which recorded fact disagrees with the witness?"
        case .connect: "Which evidence pair supports the same conclusion?"
        case .verdict: "Who had the opportunity to carry out this plan?"
        default: "Look for a specific fact that supports your answer."
        }
    }

    private var investigatorQuestion: String {
        switch mission.kind {
        case .keypad: "The evidence locker uses a reversed three-digit security entry."
        case .signal: "The receiver is calibrated ten units above the written frequency."
        case .timeline: "An event cannot occur before its necessary cause."
        case .contradiction: "Which independent record invalidates the witness's timeline?"
        case .anomaly: "Find a detail inconsistent with the standard procedure."
        case .escapeRoute: "Which route best explains the lack of camera footage?"
        case .verdict: "Distinguish access, motive, and opportunity."
        default: "Separate what you can prove from what you merely suspect."
        }
    }

    private var expertQuestion: String {
        switch mission.kind {
        case .keypad: "The entry algorithm moves the final digit to the start."
        case .signal: "The transmitter uses the complement to 100 instead of the logged reading."
        case .timeline: "Determine the only order consistent with the prerequisite events."
        case .contradiction: "Which independent observation falsifies the stated alibi?"
        case .anomaly: "Identify the anomaly least consistent with the stated standard."
        case .escapeRoute: "Prefer the path that minimizes exposure to surveillance."
        case .connect: "Select the two mutually reinforcing pieces of physical evidence."
        case .verdict: "Weigh authority, documented action, and the opportunity to conceal it."
        default: "Determine the necessary conclusion without assuming unproven details."
        }
    }

    var timelineChoices: [String] {
        guard mission.kind == .timeline else { return mission.choices }
        let indices: [Int]
        switch mode {
        case .junior, .explorer: indices = [0, 1, 2, 3]
        case .investigator: indices = [2, 0, 3, 1]
        case .expert: indices = [3, 2, 0, 1]
        }
        return indices.map { mission.choices[$0] }
    }

    var timelineAnswer: [Int] {
        guard mission.kind == .timeline else { return mission.correctSequence }
        let originals: [Int]
        switch mode {
        case .junior, .explorer: originals = [0, 1, 2, 3]
        case .investigator: originals = [2, 0, 3, 1]
        case .expert: originals = [3, 2, 0, 1]
        }
        return mission.correctSequence.compactMap { originals.firstIndex(of: $0) }
    }

    /// Indexed by original 4-answer indices so scoring remains deterministic.
    var visibleChoices: [Int] {
        let all = Array(mission.choices.indices)
        guard mission.kind != .timeline, mission.kind != .connect,
              mode.choicesCount < 4 else { return all }

        let answer = mission.correctIndex
        let wrong = all.filter { $0 != answer }
        let shifted = Array(wrong.dropFirst(mission.id % wrong.count)) +
                      Array(wrong.prefix(mission.id % wrong.count))
        return all.filter { $0 == answer || shifted.prefix(mode.choicesCount - 1).contains($0) }
    }

    var visiblePairChoices: [Int] {
        if mode == .junior { return [0, 1, 3] }
        return Array(mission.choices.indices)
    }

    var actualCode: String {
        let original = mission.solution
        guard mission.kind == .keypad else { return original }
        switch mode {
        case .junior, .explorer: return original
        case .investigator: return String(original.reversed())
        case .expert:
            guard let last = original.last else { return original }
            return String(last) + String(original.dropLast())
        }
    }

    var frequency: Double {
        let logged = mission.expectedFrequency
        guard mission.kind == .signal else { return logged }
        switch mode {
        case .junior, .explorer: return logged
        case .investigator: return Double((Int(logged) + 10) % 100)
        case .expert: return 100 - logged
        }
    }

    var clue: String {
        switch mode {
        case .junior:
            return mission.hint + " Look carefully at the highlighted details in the story."
        case .explorer:
            return mission.hint
        case .investigator:
            return mission.hint + " " + instruction
        case .expert:
            switch mission.kind {
            case .keypad, .signal: return instruction + " Work out the transformed value before you enter it."
            default: return "Compare the two most credible facts. " + mission.hint
            }
        }
    }

    var wordStartingLetter: Character? {
        mode == .junior ? mission.solution.first : nil
    }
}
