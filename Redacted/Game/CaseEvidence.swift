import Foundation

/// An authored case has two independent, case-specific corroborating records
/// and plausible noise. Reading the two reliable documents is required
/// before the deduction is submitted. Deterministic ordering prevents the
/// answer from always appearing in the same positions.
struct CaseEvidenceNote: Identifiable, Equatable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
    let corroborated: Bool
}

struct CaseDeduction: Identifiable, Equatable {
    let id: Int
    let statement: String
    let supported: Bool
}

enum CaseEvidence {
    static func dossier(for mission: CampaignMission,
                        mode: DetectiveAgeMode) -> [CaseEvidenceNote] {
        let records = rawEvidence(for: mission, mode: mode)
        let visible: [CaseEvidenceNote]
        switch mode {
        case .junior:
            visible = [records[0], records[2]]
        case .explorer:
            visible = [records[0], records[1], records[2]]
        case .investigator:
            visible = Array(records.prefix(4))
        case .expert:
            visible = records
        }
        // A different, reproducible permutation for each level and age mode.
        // Use the same order when the view recomputes or the app restarts.
        var shuffled = visible
        var seed = UInt64(mission.id * 104729 + mode.choicesCount * 8191)
        if shuffled.count > 1 {
            for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
                seed = seed &* 2862933555777941757 &+ 3037000493
                let j = Int(seed % UInt64(i + 1))
                shuffled.swapAt(i, j)
            }
        }
        return shuffled
    }

    static func requiredEvidenceCount(for mode: DetectiveAgeMode) -> Int {
        mode == .junior ? 1 : 2
    }

    static func verifies(_ selection: Set<Int>,
                         mission: CampaignMission,
                         mode: DetectiveAgeMode) -> Bool {
        let notes = dossier(for: mission, mode: mode)
        let required = requiredEvidenceCount(for: mode)
        let selected = notes.filter { selection.contains($0.id) }
        return selected.count == required &&
            selected.allSatisfy(\.corroborated)
    }

    static func introduction(for mission: CampaignMission,
                             mode: DetectiveAgeMode) -> String {
        if mode == .junior {
            return mission.setup
        }
        switch mission.kind {
        case .keypad:
            return "A restricted lock protects a lead in \(mission.title). Investigators recovered a label and a separate access protocol. Read both before entering a code."
        case .signal:
            return "The signal connected to \(mission.title) was recorded by two systems. The original carrier and the receiver calibration are in separate records. Find the working channel."
        case .anagram:
            return "An intercepted note contains a jumbled password linked to \(mission.title). The original letters are intact, but their order is not. Review the archive notes before decoding."
        case .anomaly:
            return "One item connected to \(mission.title) may be a forgery. Investigators have both the official standard and a later inspection report. Look for the inconsistency."
        case .escapeRoute:
            return "A suspect left during the incident in \(mission.title). Public routes, surveillance coverage and access privileges need to be compared before a path can be reconstructed."
        case .verdict:
            return "This district's investigation leads to \(mission.title). Do not confuse suspicion with proof: compare authority, access and the records of what actually changed."
        case .timeline:
            return "Four events in \(mission.title) have been recovered, but the original timestamps are scattered across records. Determine which events must precede the others."
        case .findClue:
            return mission.setup + " Compare the scene records before choosing what to inspect."
        case .contradiction:
            return mission.setup + " Check the independent records; a witness statement is not a verified fact."
        case .connect:
            return mission.setup + " Two sources must corroborate the same conclusion."
        }
    }

    static func scrambledWord(for mission: CampaignMission) -> [Character] {
        var word = Array(mission.solution)
        guard word.count > 2 else { return word }
        var seed = UInt64(mission.id * 7919 + 853)
        for i in stride(from: word.count - 1, through: 1, by: -1) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            word.swapAt(i, Int(seed % UInt64(i + 1)))
        }
        if word == Array(mission.solution) { word.reverse() }
        return word
    }

    /// Final cross-examination is available for the two older profiles.
    /// This asks WHY the answer is supported, not only which one sounds right.
    static func theories(for mission: CampaignMission) -> [CaseDeduction] {
        let reason: String
        let falseLeadA: String
        let falseLeadB: String
        switch mission.kind {
        case .findClue:
            reason = "The before/after images and the fresh contact trace corroborate the same physical change."
            falseLeadA = "The object is closest to the most nervous witness, so it must be the evidence."
            falseLeadB = "A hallway rumor establishes the physical trace even without an object-level comparison."
        case .timeline:
            reason = "Two synchronized records establish necessary before-and-after relationships."
            falseLeadA = "The order in which records were discovered is the original order of the events."
            falseLeadB = "A witness's recollection outweighs synchronized timestamps when their stories disagree."
        case .keypad:
            reason = "The photographed identifier and the active lock protocol must both be used to calculate the entry."
            falseLeadA = "The retired combination is safer because technicians have used it before."
            falseLeadB = "Any three digits from the identifier work as long as the number is from the correct depot."
        case .contradiction:
            reason = "An independent timestamped record can disprove a specific claim in the witness statement."
            falseLeadA = "An interested witness repeating the same statement makes the original claim conclusive."
            falseLeadB = "The testimony is automatically invalid because it sounds unusual."
        case .anomaly:
            reason = "The inspected item's unusual feature conflicts with a verified reference standard."
            falseLeadA = "Any cosmetic difference proves forgery regardless of the approved specification."
            falseLeadB = "An old, edited advertisement is more trustworthy than the official reference."
        case .escapeRoute:
            reason = "The service-access audit fits the missing public-camera trail and the route's geography."
            falseLeadA = "The shortest public path is necessarily the escape route even if cameras show no suspect."
            falseLeadB = "A tourist map proves no private maintenance passages exist."
        case .anagram:
            reason = "Every recovered tile is used once, producing a valid archive-length codeword."
            falseLeadA = "A shorter word is acceptable if its meaning fits the investigation."
            falseLeadB = "The messenger's incomplete transcription outranks the recovered original tiles."
        case .signal:
            reason = "The authenticated transmitter reading must be transformed using the receiver's current calibration."
            falseLeadA = "The receiver's old preset is trustworthy even when calibration was changed."
            falseLeadB = "The strongest static noise on the dial is proof that it is the authenticated signal."
        case .connect:
            reason = "The paired traces were independently logged and their documented connection supports one conclusion."
            falseLeadA = "Two objects found close together must have the same origin."
            falseLeadB = "An unsigned artifact is reliable when its story sounds like the other evidence."
        case .verdict:
            reason = "The suspect's privileged access matches the signed instruction and the timing of the system change."
            falseLeadA = "A public sighting proves the visitor could authorize a protected system change."
            falseLeadB = "Suspicion alone establishes responsibility even without an audit trail."
        }
        var options = [
            CaseDeduction(id: 0, statement: reason, supported: true),
            CaseDeduction(id: 1, statement: falseLeadA, supported: false),
            CaseDeduction(id: 2, statement: falseLeadB, supported: false)
        ]
        var seed = UInt64(mission.id * 3253 + 13)
        for i in stride(from: options.count - 1, through: 1, by: -1) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            options.swapAt(i, Int(seed % UInt64(i + 1)))
        }
        return options
    }

    static func failedEvidenceFeedback(mode: DetectiveAgeMode) -> String {
        if mode == .junior {
            return "That report isn't strong enough. Look for a record made when the incident happened."
        }
        return "One of those records lacks independent verification or doesn't establish the claim. Check the source and timestamp before pinning evidence."
    }

    private struct Record {
        let title: String
        let detail: String
        let symbol: String
        let reliable: Bool
    }

    private static func rawEvidence(for mission: CampaignMission,
                                    mode: DetectiveAgeMode) -> [CaseEvidenceNote] {
        let episode = CampaignCatalog.episode(mission.episode)?.title ?? "THE DISTRICT"
        let alternatives = mission.decoys
        let misleading = alternatives.first ?? "Unverified report"
        let events = mission.choices
        let sorted = mission.correctSequence.map { events[$0] }
        let rule = AgeAdjustedMission(mission: mission, mode: mode).instruction
        let seed = String(format: "%d%03d", (mission.id % 9) + 1,
                          Int(mission.solution) ?? 0)

        let commonUnverified = Record(
            title: "UNVERIFIED TIP",
            detail: "A caller names \(misleading.lowercased()), but supplies no timestamp or material record. The account has not been corroborated.",
            symbol: "bubble.left", reliable: false
        )
        let oldReport = Record(
            title: "OLD ARCHIVE ENTRY",
            detail: "A related note from \(episode) was entered well before the incident. It establishes background, not what happened during this case.",
            symbol: "archivebox", reliable: false
        )
        let rumor = Record(
            title: "SUBJECT INTERVIEW",
            detail: "An interested witness remembers a different sequence, but their statement conflicts with the independent incident records.",
            symbol: "person.crop.circle.badge.questionmark", reliable: false
        )

        let candidates: [Record]
        switch mission.kind {
        case .findClue:
            candidates = [
                Record(title: "BEFORE / AFTER IMAGES",
                       detail: "The inspected detail differs from a verified reference or its earlier documented condition. The nearby comparison objects show no matching discrepancy.",
                       symbol: "photo.on.rectangle.angled", reliable: true),
                Record(title: "FORENSIC COMPARISON",
                       detail: "An independent examination confirms that the disputed detail is meaningful to the incident, not ordinary wear, packaging variation or unrelated background.",
                       symbol: "viewfinder", reliable: true),
                commonUnverified, oldReport,
                Record(title: "VAGUE SECURITY REPORT",
                       detail: "Security noticed movement in a nearby hallway, but the recording does not show contact with the object.",
                       symbol: "video.slash", reliable: false)
            ]
        case .timeline:
            candidates = [
                Record(title: "SYNCHRONIZED CAMERA",
                       detail: "Two frames establish that “\(sorted[0])” occurred before “\(sorted[1])”. The camera clock was checked against dispatch.",
                       symbol: "video", reliable: true),
                Record(title: "DISPATCH / CONTROL LOG",
                       detail: "The control record places “\(sorted[2])” after “\(sorted[1])”, and “\(sorted[3])” after the control action.",
                       symbol: "clock.arrow.circlepath", reliable: true),
                rumor, oldReport,
                Record(title: "UNCALIBRATED PHONE",
                       detail: "A bystander's phone lists “\(sorted[3])” first, but its clock had been reset and does not match the official timebase.",
                       symbol: "iphone", reliable: false)
            ]
        case .keypad:
            candidates = [
                Record(title: "SEALED IDENTIFIER",
                       detail: "Equipment label \(seed) was photographed beside the restricted lock. The first digit identifies the depot; the last three identify this case.",
                       symbol: "number.square", reliable: true),
                Record(title: "LOCK FIRMWARE MANUAL",
                       detail: "The active protocol states: \(rule) The rule applies to the label, not a nearby employee badge.",
                       symbol: "lock.doc", reliable: true),
                Record(title: "RETIRED COMBINATION",
                       detail: "A technician left the old value \(misleading) on a scrap of paper; the log marks it deactivated before the incident.",
                       symbol: "doc.text", reliable: false),
                oldReport,
                Record(title: "UNSIGNED SERVICE NOTE",
                       detail: "A loose slip suggests skipping all security transforms, but it has no author or approval date.",
                       symbol: "note.text", reliable: false)
            ]
        case .contradiction:
            candidates = [
                Record(title: "SIGNED TESTIMONY",
                       detail: "The statement in the case brief is on file. The speaker insists their account is complete and accurate.",
                       symbol: "text.bubble", reliable: true),
                Record(title: "INDEPENDENT AUDIT",
                       detail: "A timestamped system record from the disputed window exists. It was preserved automatically and does not depend on the witness's recollection.",
                       symbol: "checkmark.shield", reliable: true),
                commonUnverified, oldReport,
                Record(title: "SECONDHAND STATEMENT",
                       detail: "A friend repeats the witness's claim but never observed the incident personally.",
                       symbol: "person.2", reliable: false)
            ]
        case .anomaly:
            candidates = [
                Record(title: "APPROVED REFERENCE",
                       detail: "\(mission.setup) The standard predates the incident and was independently authenticated.",
                       symbol: "checkmark.seal", reliable: true),
                Record(title: "CURRENT INSPECTION",
                       detail: "One inspected item has a feature inconsistent with the authorized specification. The other samples were checked against the reference.",
                       symbol: "magnifyingglass.circle", reliable: true),
                oldReport, rumor,
                Record(title: "UNVERIFIED SALES PHOTO",
                       detail: "An advertisement displays several similar items, but its image was edited and cannot establish authenticity.",
                       symbol: "photo.badge.exclamationmark", reliable: false)
            ]
        case .escapeRoute:
            candidates = [
                Record(title: "CAMERA COVERAGE MAP",
                       detail: "The public entrances, stairs and main corridors were covered during the incident. The cameras recorded no suspect using them.",
                       symbol: "video.fill", reliable: true),
                Record(title: "SERVICE ACCESS AUDIT",
                       detail: "A restricted service route links the relevant locations without passing public surveillance. Access activity was recorded during the window.",
                       symbol: "key.horizontal", reliable: true),
                commonUnverified, oldReport,
                Record(title: "PUBLIC WAYFINDING MAP",
                       detail: "A tourist brochure shows every public exit, but does not include maintenance-only infrastructure.",
                       symbol: "map", reliable: false)
            ]
        case .anagram:
            candidates = [
                Record(title: "RECOVERED CHARACTER STRIP",
                       detail: "The recovered letter tiles contain “\(scrambledWord(for: mission).map(String.init).joined())”. No letters were added or removed.",
                       symbol: "textformat.abc", reliable: true),
                Record(title: "ARCHIVE WORD-LENGTH RULE",
                       detail: "The access phrase is a single meaningful \(mission.solution.count)-letter word linked to the district evidence. Case and spacing are ignored.",
                       symbol: "text.book.closed", reliable: true),
                oldReport, commonUnverified,
                Record(title: "INCOMPLETE TRANSCRIPTION",
                       detail: "A messenger copied only part of the intercepted word and admits at least one character is missing.",
                       symbol: "pencil.line", reliable: false)
            ]
        case .signal:
            candidates = [
                Record(title: "TRANSMITTER LOG",
                       detail: "The verified carrier recorded by the transmitter is \(mission.solution) MHz. This is a source reading, not necessarily the receiver setting.",
                       symbol: "antenna.radiowaves.left.and.right", reliable: true),
                Record(title: "CALIBRATION BULLETIN",
                       detail: "The receiver's active calibration says: \(rule) Apply the transform to the source reading before locking the dial.",
                       symbol: "slider.horizontal.3", reliable: true),
                Record(title: "OLD CHANNEL PRESET",
                       detail: "A receiver was left on a legacy preset before the incident; that saved setting does not reflect the current calibration.",
                       symbol: "radio", reliable: false),
                rumor,
                Record(title: "RADIO INTERFERENCE",
                       detail: "A nearby emitter produced brief static, but no authenticated transmission was recovered from that source.",
                       symbol: "waveform.path", reliable: false)
            ]
        case .connect:
            candidates = [
                Record(title: "CHAIN OF CUSTODY",
                       detail: "The two authenticated traces were recovered within the same incident window and sealed separately before analysis.",
                       symbol: "shippingbox", reliable: true),
                Record(title: "LAB CROSS-CHECK",
                       detail: "The meaningful link requires two independently documented pieces of evidence. A loose object without the second record proves nothing.",
                       symbol: "link", reliable: true),
                commonUnverified, oldReport,
                Record(title: "UNTRACKED OBJECT",
                       detail: "A third item lacks a collection time or authorized signature. Its origin cannot be verified.",
                       symbol: "questionmark.folder", reliable: false)
            ]
        case .verdict:
            candidates = [
                Record(title: "ACCESS PERMISSIONS",
                       detail: "\(mission.hint) Revisit “\(CampaignCatalog.mission(mission.id - 2)?.title ?? "the earlier incident")” for the opportunity window.",
                       symbol: "person.badge.key", reliable: true),
                Record(title: "AUDIT TRAIL",
                       detail: "The signed system change coincides with “\(CampaignCatalog.mission(mission.id - 1)?.title ?? "the previous lead")”. Compare that lead with the suspects' responsibilities.",
                       symbol: "list.bullet.clipboard", reliable: true),
                commonUnverified, rumor,
                Record(title: "PUBLIC SIGHTING",
                       detail: "A visitor appeared near the site, but public proximity does not establish permission to change protected records.",
                       symbol: "figure.walk", reliable: false)
            ]
        }
        return candidates.enumerated().map { index, source in
            CaseEvidenceNote(id: index,
                             title: source.title,
                             detail: source.detail,
                             symbol: source.symbol,
                             corroborated: source.reliable)
        }
    }
}
