import Foundation

// Tests production Foundation-only case logic, without a simulator or seeded
// random state. It must pass for every authored case in every age profile.
@main
enum ValidateCasework {
    static func main() {
        precondition(CampaignCatalog.levels.count == 100, "Campaign must remain at 100 cases")
        precondition(CampaignCatalog.episodes.count == 10, "Campaign must have 10 districts")
        var checked = 0
        for mission in CampaignCatalog.levels {
            precondition((1...100).contains(mission.id))
            for profile in DetectiveAgeMode.allCases {
                let adjusted = AgeAdjustedMission(mission: mission, mode: profile)
                let dossier = CaseEvidence.dossier(for: mission, mode: profile)
                let expectedCount: Int
                switch profile {
                case .junior: expectedCount = 2
                case .explorer: expectedCount = 3
                case .investigator: expectedCount = 4
                case .expert: expectedCount = 5
                }
                precondition(dossier.count == expectedCount,
                             "Wrong dossier size at case \(mission.id), \(profile)")
                precondition(dossier == CaseEvidence.dossier(for: mission, mode: profile),
                             "Evidence order must not jump during SwiftUI redraws")
                precondition(Set(dossier.map(\.id)).count == expectedCount,
                             "Duplicate evidence in case \(mission.id)")
                precondition(dossier.allSatisfy { !$0.title.isEmpty && !$0.detail.isEmpty })
                precondition(!adjusted.brief.isEmpty && !adjusted.instruction.isEmpty)
                let valid = Set(dossier.filter(\.corroborated).map(\.id))
                precondition(valid.count == CaseEvidence.requiredEvidenceCount(for: profile))
                precondition(CaseEvidence.verifies(valid, mission: mission, mode: profile))
                for note in dossier where !note.corroborated {
                    let altered = Set(valid.sorted().dropLast()).union([note.id])
                    precondition(!CaseEvidence.verifies(altered, mission: mission, mode: profile),
                                 "False evidence passed at case \(mission.id)")
                }

                precondition((2...5).contains(profile.attemptsAllowed))
                if profile.needsClosingArgument {
                    let theories = CaseEvidence.theories(for: mission)
                    precondition(theories.count == 3)
                    precondition(theories.filter(\.supported).count == 1)
                    precondition(Set(theories.map(\.id)).count == 3)
                    precondition(theories == CaseEvidence.theories(for: mission))
                }

                switch mission.kind {
                case .timeline:
                    precondition(adjusted.timelineChoices.count == 4)
                    precondition(adjusted.timelineAnswer.count == 4)
                    precondition(Set(adjusted.timelineAnswer) == Set(0..<4))
                    let actual = adjusted.timelineAnswer.map { adjusted.timelineChoices[$0] }
                    let canonical = mission.correctSequence.map { mission.choices[$0] }
                    precondition(actual == canonical,
                                 "Timeline cannot be completed at case \(mission.id), \(profile)")
                case .keypad:
                    precondition(adjusted.actualCode.count == 3)
                    precondition(adjusted.actualCode.allSatisfy(\.isNumber))
                case .signal:
                    precondition((0...100).contains(adjusted.frequency))
                case .anagram:
                    let sortedScramble = CaseEvidence.scrambledWord(for: mission).sorted()
                    precondition(sortedScramble == Array(mission.solution).sorted(),
                                 "Anagram loses letters")
                case .connect:
                    precondition(mission.pairIndices.count == 2)
                    precondition(mission.pairIndices.isSubset(of: Set(adjusted.visiblePairChoices)))
                default:
                    precondition(adjusted.visibleChoices.contains(mission.correctIndex),
                                 "Correct answer hidden for \(profile) in case \(mission.id)")
                    precondition(adjusted.visibleChoices.count == profile.choicesCount,
                                 "Unexpected choice count at case \(mission.id)")
                }
                checked += 1
            }
        }
        print("PASS: \(checked) case/profile combinations; 100 cases, 4 ages, all evidence, solutions and closing arguments validated")
    }
}
