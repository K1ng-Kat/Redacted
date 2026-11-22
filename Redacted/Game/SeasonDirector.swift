import Combine
import Foundation
import SwiftUI

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
    var title: String { chapter == 1 && number == 1 ? "THE INVESTIGATION BEGINS" : "CLASSIFIED" }
}

/// Publishing a date is deliberate. An empty RDSeasonLaunchUTC means that
/// no launch schedule has been announced; the UI will not invent a deadline.
/// Once set to an ISO-8601 UTC timestamp, the two-month calendar rotates
/// automatically without a new app binary for each scheduled change.
enum SeasonCalendar {
    static var publishedLaunch: Date? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "RDSeasonLaunchUTC") as? String,
              !raw.isEmpty,
              let date = ISO8601DateFormatter().date(from: raw)
        else { return nil }
        return date
    }

    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func season(at time: Date) -> RedactedSeason {
        guard let epoch = publishedLaunch else {
            return RedactedSeason(chapter: 1, number: 1,
                                  startsAt: .distantPast, endsAt: .distantFuture,
                                  tone: .midnight)
        }
        let months = utc.dateComponents([.month], from: epoch, to: time).month ?? 0
        let index = max(0, Int(floor(Double(months) / 2)))
        let start = utc.date(byAdding: .month, value: index * 2, to: epoch)!
        let end = utc.date(byAdding: .month, value: (index + 1) * 2, to: epoch)!
        return RedactedSeason(chapter: index / 4 + 1,
                              number: index % 4 + 1,
                              startsAt: start, endsAt: end,
                              tone: SeasonTone.allCases[index % SeasonTone.allCases.count])
    }

    static func next(after season: RedactedSeason) -> RedactedSeason {
        guard publishedLaunch != nil else {
            return RedactedSeason(chapter: 1, number: 2,
                                  startsAt: .distantFuture, endsAt: .distantFuture,
                                  tone: .signal)
        }
        return self.season(at: season.endsAt)
    }
}

struct SeasonActivity: Codable, Equatable {
    var casesCompleted = 0
    var starsEarned = 0
    var intelCollected = 0
}

/// Dates and visual themes are local presentation features. Competitive
/// events, paid passes or time-limited purchases must have server authority.
@MainActor
final class SeasonDirector: ObservableObject {
    static let shared = SeasonDirector()

    @Published private(set) var live: RedactedSeason
    @Published private(set) var activity: SeasonActivity

    private var rolloverTimer: Timer?
    private init() {
        let current = SeasonCalendar.season(at: Date())
        live = current
        activity = Self.readActivity(for: current.id)
        applyAppearance()
        scheduleRollover()
    }

    var displayed: RedactedSeason { live }
    var upcoming: RedactedSeason { SeasonCalendar.next(after: live) }
    var hasPublishedSchedule: Bool { SeasonCalendar.publishedLaunch != nil }

    func refresh() {
        let updated = SeasonCalendar.season(at: Date())
        if updated.id != live.id {
            live = updated
            activity = Self.readActivity(for: updated.id)
        }
        applyAppearance()
        scheduleRollover()
    }

    func recordCompletedCase(stars: Int) {
        if hasPublishedSchedule && Date() >= live.endsAt { refresh() }
        activity.casesCompleted += 1
        activity.starsEarned += max(0, min(3, stars))
        activity.intelCollected += 10 + max(0, min(3, stars)) * 5
        if let data = try? JSONEncoder().encode(activity) {
            UserDefaults.standard.set(data, forKey: Self.storageKey(for: live.id))
        }
    }

    private func applyAppearance() {
        UserDefaults.standard.set(live.tone.rawValue, forKey: "redacted.season.activeTone")
    }

    private func scheduleRollover() {
        rolloverTimer?.invalidate()
        guard hasPublishedSchedule else { return }
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
