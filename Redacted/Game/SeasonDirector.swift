import Foundation
import SwiftUI

/// Seasonal presentation never edits campaign saves or detective cosmetics.
/// The date schedule is deliberately explicit so a future backend can replace
/// the calendar without changing the view layer.
enum SeasonTone: Int, CaseIterable {
    case midnight, signal, ember, ultraviolet
}

struct RedactedSeason: Equatable, Identifiable {
    let chapter: Int
    let number: Int
    let startsAt: Date
    let endsAt: Date
    let tone: SeasonTone

    var id: String { "chapter-\(chapter)-season-\(number)" }
    var heading: String { "CHAPTER \(chapter) · SEASON \(number)" }
    var duration: TimeInterval { endsAt.timeIntervalSince(startsAt) }

    /// Public releases never embed unreleased plot titles, character names
    /// or unreleased artwork. Publishing real season content is a separate step.
    var title: String {
        if chapter == 1 && number == 1 { return "SHADOW PROTOCOL" }
        return "CLASSIFIED OPERATION"
    }

    #if DEBUG
    var developerTitle: String {
        return "UNRELEASED SEASON PREVIEW"
    }
    #endif
}

enum SeasonCalendar {
    /// Development launch schedule. Replace with the official UTC launch date
    /// before shipping the first season. UTC avoids DST and timezone ambiguity.
    static let epoch = Date(timeIntervalSince1970: 1793491200) // Nov 1, 2026 00:00 UTC
    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func season(at time: Date) -> RedactedSeason {
        let months = utc.dateComponents([.month], from: epoch, to: time).month ?? 0
        // Each season is two UTC calendar months, not a floating 60-day timer.
        let index = max(0, Int(floor(Double(months) / 2)))
        let startsAt = utc.date(byAdding: .month, value: index * 2, to: epoch)!
        let endsAt = utc.date(byAdding: .month, value: (index + 1) * 2, to: epoch)!
        return RedactedSeason(
            chapter: index / 4 + 1,
            number: index % 4 + 1,
            startsAt: startsAt,
            endsAt: endsAt,
            tone: SeasonTone.allCases[index % SeasonTone.allCases.count]
        )
    }

    static func next(after season: RedactedSeason) -> RedactedSeason {
        self.season(at: season.endsAt)
    }
}

struct SeasonActivity: Codable, Equatable {
    var casesCompleted = 0
    var starsEarned = 0
    var intelCollected = 0
}

/// Production mode always follows the live UTC schedule. Preview is compiled
/// exclusively into DEBUG builds, so there is no secret switch in App Store builds.
/// Note: a device clock is NOT authoritative for paid or competitive rewards.
@MainActor
final class SeasonDirector: ObservableObject {
    static let shared = SeasonDirector()

    @Published private(set) var live: RedactedSeason
    @Published private(set) var activity: SeasonActivity
    #if DEBUG
    @Published private(set) var previewingNext = false
    #endif

    private var rolloverTimer: Timer?
    private init() {
        let current = SeasonCalendar.season(at: Date())
        live = current
        activity = Self.readActivity(for: current.id)
        applyAppearance()
        scheduleRollover()
    }

    var upcoming: RedactedSeason { SeasonCalendar.next(after: live) }

    var displayed: RedactedSeason {
        #if DEBUG
        return previewingNext ? upcoming : live
        #else
        return live
        #endif
    }

    var isPreviewing: Bool {
        #if DEBUG
        return previewingNext
        #else
        return false
        #endif
    }

    #if DEBUG
    func setPreview(_ enabled: Bool) {
        guard previewingNext != enabled else { return }
        previewingNext = enabled
        applyAppearance()
    }
    #endif

    func refresh() {
        let updated = SeasonCalendar.season(at: Date())
        if updated.id != live.id {
            live = updated
            activity = Self.readActivity(for: updated.id)
            #if DEBUG
            previewingNext = false
            #endif
        }
        applyAppearance()
        scheduleRollover()
    }

    func recordCompletedCase(stars: Int) {
        // Developer preview never changes live-season statistics.
        guard !isPreviewing else { return }
        refreshIfExpired()
        activity.casesCompleted += 1
        activity.starsEarned += max(0, min(3, stars))
        activity.intelCollected += 10 + max(0, min(3, stars)) * 5
        if let data = try? JSONEncoder().encode(activity) {
            UserDefaults.standard.set(data, forKey: Self.storageKey(for: live.id))
        }
    }

    private func refreshIfExpired() {
        if Date() >= live.endsAt { refresh() }
    }

    private func applyAppearance() {
        UserDefaults.standard.set(displayed.tone.rawValue, forKey: "redacted.season.activeTone")
    }

    private func scheduleRollover() {
        rolloverTimer?.invalidate()
        // Reschedule at most daily to survive long-running sessions; the
        // exact boundary is used whenever it's within the scheduling window.
        let delay = max(0.1, min(86_400, live.endsAt.timeIntervalSinceNow))
        rolloverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private static func storageKey(for id: String) -> String {
        "redacted.season.activity.\(id)"
    }

    private static func readActivity(for id: String) -> SeasonActivity {
        guard let data = UserDefaults.standard.data(forKey: storageKey(for: id)),
              let saved = try? JSONDecoder().decode(SeasonActivity.self, from: data)
        else { return SeasonActivity() }
        return saved
    }
}
