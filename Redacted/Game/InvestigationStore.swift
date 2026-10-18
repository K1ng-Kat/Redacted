import Foundation
import SwiftUI
import Combine

struct CaseProgress: Codable {
    var started = false
    var collectedEvidence: Set<String> = []
    var askedQuestions: Set<String> = []
    var solvedDeductions: Set<String> = []
    var incorrectDeductions = 0
    var incorrectAccusations = 0
    var caseClosed = false
}

@MainActor
final class InvestigationStore: ObservableObject {
    private static let storageKey = "redacted.case001.progress.v1"

    @Published private(set) var state: CaseProgress {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let restored = try? JSONDecoder().decode(CaseProgress.self, from: data) {
            state = restored
        } else {
            state = CaseProgress()
        }
    }

    private let defaults: UserDefaults

    var evidenceCount: Int { state.collectedEvidence.count }
    var answeredCount: Int { state.askedQuestions.count }
    var deductionCount: Int { state.solvedDeductions.count }

    var interviewedCount: Int {
        CaseData.suspects.filter { suspect in
            suspect.questions.contains { state.askedQuestions.contains($0.id) }
        }.count
    }

    var progressFraction: Double {
        let completed = evidenceCount + interviewedCount + deductionCount
        return Double(completed) / Double(CaseData.evidence.count + CaseData.suspects.count + CaseData.deductions.count)
    }

    var canAccuse: Bool {
        evidenceCount >= 6 &&
        interviewedCount == CaseData.suspects.count &&
        deductionCount == CaseData.deductions.count
    }

    func start() {
        state.started = true
    }

    func hasEvidence(_ id: String) -> Bool {
        state.collectedEvidence.contains(id)
    }

    func discover(_ id: String) {
        guard CaseData.evidence(for: id) != nil else { return }
        state.collectedEvidence.insert(id)
    }

    func hasAsked(_ id: String) -> Bool {
        state.askedQuestions.contains(id)
    }

    func ask(_ questionID: String) {
        guard CaseData.suspects.contains(where: { $0.questions.contains(where: { $0.id == questionID }) }) else { return }
        state.askedQuestions.insert(questionID)
    }

    func deductionIsSolved(_ id: String) -> Bool {
        state.solvedDeductions.contains(id)
    }

    func isDeductionReady(_ deduction: CaseDeduction) -> Bool {
        deduction.requiredEvidence.allSatisfy { hasEvidence($0) }
    }

    @discardableResult
    func submitDeduction(_ deduction: CaseDeduction, option: Int) -> Bool {
        guard isDeductionReady(deduction), !deductionIsSolved(deduction.id),
              deduction.options.indices.contains(option) else { return false }
        if option == deduction.correctIndex {
            state.solvedDeductions.insert(deduction.id)
            return true
        }
        state.incorrectDeductions += 1
        return false
    }

    @discardableResult
    func accuse(_ suspectID: String) -> Bool {
        guard canAccuse && !state.caseClosed,
              CaseData.suspect(for: suspectID) != nil else { return false }
        if suspectID == CaseData.culpritID {
            state.caseClosed = true
            return true
        }
        state.incorrectAccusations += 1
        return false
    }

    func reset() {
        state = CaseProgress()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
