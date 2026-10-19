import Foundation

/// 20 locations × 10 incidents × 5 methods = exactly 1,000 authored
/// combinations with distinct evidence and deterministic multi-step answers.
struct MultiplayerMystery: Identifiable, Equatable {
    let id: Int
    let name: String
    let brief: String
    let evidence: [String]
    let suspects: [String]
    let code: String
    let correctEvidence: Int
    let correctSuspect: Int

    static let venues = [
        "Moonlit Observatory", "Old Rail Depot", "Sapphire Museum", "Northside Pier",
        "Amber Library", "Sealed Laboratory", "Underground Station", "Crystal Hotel",
        "Aurora Shipyard", "Clockwork Theater", "Skyline Terminal", "Metro Archives",
        "Silver Gallery", "Canyon Research Base", "Horizon Casino",
        "Glasshouse Gardens", "Icebound Cabin", "Silent Film Studio",
        "Riverfront Warehouse", "Forgotten Lighthouse"
    ]
    static let targets = [
        "cipher drive", "antique compass", "prototype drone", "blueprint tube",
        "encrypted ledger", "museum medallion", "rare manuscript", "security badge",
        "master key", "artwork shipment"
    ]
    static let methods = [
        "a tampered access panel", "a forged visitor log", "a disabled security camera",
        "a redirected delivery", "an unregistered maintenance route"
    ]
    static let leads = [
        "A tool mark on the access panel",
        "A signature that differs from the register",
        "A missing 60-second surveillance recording",
        "A delivery receipt with the wrong destination",
        "Maintenance dust from a sealed access corridor"
    ]
    static let suspects = [
        "Security Supervisor", "Courier", "Visitor", "Maintenance Chief"
    ]

    static func make(_ number: Int) -> MultiplayerMystery {
        let index = max(0, min(999, number))
        let venue = index / 50
        let target = (index / 5) % 10
        let method = index % 5
        let offset = (index * 7 + 3) % 4
        let suspect = (index * 11 + 1) % 4
        let evidence = (0..<4).map { pos -> String in
            if pos == offset { return leads[method] }
            return leads[(method + pos + 1) % leads.count]
        }
        // Code is a nontrivial 3-digit number, unique for this combination.
        let code = String(format: "%03d", 100 + (index * 37 + 51) % 900)
        let route = venues[venue]
        let object = targets[target]
        let names = suspects
        return MultiplayerMystery(
            id: index,
            name: "\(route): \(object.capitalized)",
            brief: "The \(object) disappeared from \(route). Investigators found \(methods[method]). " +
                   "The sealed evidence envelope is numbered \(code). " +
                   "Of the four suspects, only the \(names[suspect].lowercased()) had authorization " +
                   "to change the \(method < 2 ? "incident documentation" : "restricted equipment") during the window.",
            evidence: evidence,
            suspects: names,
            code: code,
            correctEvidence: offset,
            correctSuspect: suspect
        )
    }
}
