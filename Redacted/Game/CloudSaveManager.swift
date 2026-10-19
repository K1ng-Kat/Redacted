import Foundation

/// Local and REDACTED ID account backup serialization. No Apple ID, iCloud
/// or CloudKit dependency. Backward-compatible with previous saved campaign
/// JSON so existing on-device rewards and level progress are preserved.
enum CampaignSaveCodec {
    struct SaveEnvelope: Codable {
        let progress: CampaignProgress
        let preferences: SavedPreferences
        let updatedAt: Date
    }

    struct SavedPreferences: Codable {
        var ageMode: String
        var equippedTheme: String
        var settings: [String: String]

        static let names = [
            "redacted.fx.sound", "redacted.fx.haptics",
            "redacted.fx.motion", "redacted.fx.hints",
            "redacted.music.enabled", "redacted.music.menu.volume",
            "redacted.music.level.volume", "redacted.setup.complete",
            "redacted.tutorial.home", "redacted.tutorial.lastDistrict"
        ]

        init() {
            let defaults = UserDefaults.standard
            ageMode = defaults.string(forKey: "redacted.age.mode") ?? "13-15"
            equippedTheme = defaults.string(forKey: "redacted.profile.theme") ?? "midnight"
            settings = [:]
            for key in Self.names {
                if let value = defaults.object(forKey: key) {
                    settings[key] = String(describing: value)
                }
            }
        }

        func restore() {
            let defaults = UserDefaults.standard
            defaults.set(ageMode, forKey: "redacted.age.mode")
            defaults.set(equippedTheme, forKey: "redacted.profile.theme")
            for (key, raw) in settings {
                if key == "redacted.music.menu.volume" ||
                   key == "redacted.music.level.volume" {
                    if let number = Double(raw) { defaults.set(number, forKey: key) }
                } else if key == "redacted.tutorial.lastDistrict" {
                    if let number = Int(raw) { defaults.set(number, forKey: key) }
                } else {
                    defaults.set(raw == "1" || raw.lowercased() == "true", forKey: key)
                }
            }
        }
    }


}
