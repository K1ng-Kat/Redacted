import Foundation
import SwiftUI
import Combine
import UIKit
import AVFoundation

struct CampaignProgress: Codable {
    var bestStars: [Int: Int] = [:]
    var lastLevel = 1
    var tutorialComplete = false
    var totalAttempts = 0
    var firstLaunchDate = Date()
    var xp = 0
    var coins = 50
    var hintTickets = 2
    var hintsBought = 0

    enum CodingKeys: String, CodingKey {
        case bestStars, lastLevel, tutorialComplete, totalAttempts,
             firstLaunchDate, xp, coins, hintTickets, hintsBought
    }

    init() {}

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        bestStars = try box.decodeIfPresent([Int: Int].self, forKey: .bestStars) ?? [:]
        lastLevel = try box.decodeIfPresent(Int.self, forKey: .lastLevel) ?? 1
        tutorialComplete = try box.decodeIfPresent(Bool.self, forKey: .tutorialComplete) ?? false
        totalAttempts = try box.decodeIfPresent(Int.self, forKey: .totalAttempts) ?? 0
        firstLaunchDate = try box.decodeIfPresent(Date.self, forKey: .firstLaunchDate) ?? Date()
        xp = try box.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        coins = try box.decodeIfPresent(Int.self, forKey: .coins) ?? 50
        hintTickets = try box.decodeIfPresent(Int.self, forKey: .hintTickets) ?? 2
        hintsBought = try box.decodeIfPresent(Int.self, forKey: .hintsBought) ?? 0
    }
}

struct CasePayout {
    let stars: Int
    let earnedXP: Int
    let earnedCoins: Int
    let earnedTickets: Int
    let levelsGained: Int
    let newRank: Int
    let firstClear: Bool
}

enum RankRewards {
    static let cosmetics: [(level: Int, title: String, color: String)] = [
        (1, "Midnight Blue", "midnight"),
        (3, "Crimson Files", "crimson"),
        (6, "Neon Signal", "neon"),
        (10, "Golden Evidence", "gold"),
        (15, "Ghost Protocol", "ghost"),
        (20, "Director's Office", "director")
    ]

    static func title(for rank: Int) -> String {
        switch rank {
        case ..<3: "Rookie Detective"
        case ..<6: "Field Investigator"
        case ..<10: "Senior Detective"
        case ..<15: "Special Agent"
        case ..<20: "Chief Investigator"
        default: "Agency Director"
        }
    }

    static func threshold(for rank: Int) -> Int {
        // XP needed to go from rank N to N+1.
        140 + (rank * 50)
    }

    static func rank(for totalXP: Int) -> Int {
        var xpLeft = max(0, totalXP)
        var rank = 1
        while rank < 100 && xpLeft >= threshold(for: rank) {
            xpLeft -= threshold(for: rank)
            rank += 1
        }
        return rank
    }

    static func progress(_ totalXP: Int) -> (current: Int, needed: Int) {
        var xpLeft = max(0, totalXP)
        var rank = 1
        while rank < 100 && xpLeft >= threshold(for: rank) {
            xpLeft -= threshold(for: rank)
            rank += 1
        }
        return (xpLeft, threshold(for: rank))
    }
}

@MainActor
final class CampaignStore: ObservableObject {
    private static let saveKey = "redacted.campaign.v1"
    static let hintPrice = 30

    @Published private(set) var progress: CampaignProgress {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey),
           let stored = try? JSONDecoder().decode(CampaignProgress.self, from: data) {
            progress = stored
        } else {
            progress = CampaignProgress()
        }
    }

    var levelsCompleted: Int { progress.bestStars.count }
    var totalStars: Int { progress.bestStars.values.reduce(0, +) }
    var coins: Int { progress.coins }
    var hintTickets: Int { progress.hintTickets }
    var accountXP: Int { progress.xp }
    var accountLevel: Int { RankRewards.rank(for: progress.xp) }
    var rankTitle: String { RankRewards.title(for: accountLevel) }
    var rankProgress: Double {
        let p = RankRewards.progress(progress.xp)
        return Double(p.current) / Double(p.needed)
    }
    var xpForNextRank: String {
        let p = RankRewards.progress(progress.xp)
        return "\(p.current)/\(p.needed) XP"
    }
    var unlockedThemes: [String] {
        RankRewards.cosmetics.filter { $0.level <= accountLevel }.map(\.color)
    }
    var unlockedLevel: Int {
        let firstIncomplete = (1...100).first { progress.bestStars[$0] == nil }
        return firstIncomplete ?? 100
    }
    var nextLevel: Int { unlockedLevel }
    var progressFraction: Double { Double(levelsCompleted) / 100.0 }
    var allCompleted: Bool { levelsCompleted == 100 }

    func isUnlocked(_ level: Int) -> Bool {
        (1...100).contains(level) && level <= unlockedLevel
    }

    func stars(for level: Int) -> Int { progress.bestStars[level] ?? 0 }

    func recordStarted(_ level: Int) {
        guard isUnlocked(level) else { return }
        progress.lastLevel = level
    }

    func tutorialSeen() {
        progress.tutorialComplete = true
    }

    func redeemHint() -> Bool {
        if progress.hintTickets > 0 {
            progress.hintTickets -= 1
            return true
        }
        guard progress.coins >= Self.hintPrice else { return false }
        progress.coins -= Self.hintPrice
        progress.hintsBought += 1
        return true
    }

    @discardableResult
    func complete(_ level: Int, mistakes: Int, hintUsed: Bool) -> CasePayout? {
        guard isUnlocked(level), (1...100).contains(level) else { return nil }
        let stars = max(1, 3 - (mistakes > 0 ? 1 : 0) - (mistakes > 2 || hintUsed ? 1 : 0))
        let previousStars = progress.bestStars[level] ?? 0
        let isFirstClear = previousStars == 0
        let improvedStars = max(0, stars - previousStars)
        let baseXP = isFirstClear ? 90 : 0
        let xp = baseXP + improvedStars * 20 + (level % 10 == 0 && isFirstClear ? 80 : 0)
        let coins = (isFirstClear ? 35 : 0) + improvedStars * 8 +
                    (level % 10 == 0 && isFirstClear ? 100 : 0)
        let oldRank = accountLevel

        progress.bestStars[level] = max(previousStars, stars)
        progress.lastLevel = min(100, level + 1)
        progress.totalAttempts += 1
        progress.xp += xp
        progress.coins += coins

        let newRank = accountLevel
        let levelsGained = max(0, newRank - oldRank)
        let bonusCoins = levelsGained * 60
        let bonusTickets = levelsGained
        if levelsGained > 0 {
            progress.coins += bonusCoins
            progress.hintTickets += bonusTickets
        }
        return CasePayout(
            stars: stars, earnedXP: xp,
            earnedCoins: coins + bonusCoins, earnedTickets: bonusTickets,
            levelsGained: levelsGained, newRank: newRank, firstClear: isFirstClear
        )
    }

    func episodeCompleted(_ episode: CampaignEpisode) -> Int {
        (episode.startLevel...episode.endLevel).filter { stars(for: $0) > 0 }.count
    }

    func resetProgress() {
        progress = CampaignProgress()
        UserDefaults.standard.set("midnight", forKey: "redacted.profile.theme")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
    }
}

// Procedural retro bleeps: no asset downloads or paid services.
@MainActor
final class GameEffects {
    static let shared = GameEffects()
    private var player: AVAudioPlayer?

    var hapticsOn: Bool {
        UserDefaults.standard.object(forKey: "redacted.fx.haptics") as? Bool ?? true
    }
    var soundOn: Bool {
        UserDefaults.standard.object(forKey: "redacted.fx.sound") as? Bool ?? true
    }

    func tap() {
        if hapticsOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        play(frequencies: [430], duration: 0.085, volume: 0.20)
    }

    func mistake() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        play(frequencies: [220, 180], duration: 0.22, volume: 0.18)
    }

    func success() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        play(frequencies: [523, 659, 784], duration: 0.34, volume: 0.23)
    }

    private func play(frequencies: [Double], duration: Double, volume: Float) {
        guard soundOn else { return }
        let sampleRate = 22_050
        let count = Int(Double(sampleRate) * duration)
        guard count > 0 else { return }
        var samples = Data(capacity: count * 2)
        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)
            let position = min(frequencies.count - 1, Int((t / duration) * Double(frequencies.count)))
            let phase = 2 * Double.pi * frequencies[position] * t
            let envelope = min(1.0, t * 65.0) * max(0.0, 1.0 - (t / duration))
            let value = Int16(max(-32767, min(32767, sin(phase) * envelope * 12500)))
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { samples.append(contentsOf: $0) }
        }

        var wave = Data()
        func bytes(_ text: String) { wave.append(contentsOf: text.utf8) }
        func u16(_ number: UInt16) {
            var value = number.littleEndian
            withUnsafeBytes(of: &value) { wave.append(contentsOf: $0) }
        }
        func u32(_ number: UInt32) {
            var value = number.littleEndian
            withUnsafeBytes(of: &value) { wave.append(contentsOf: $0) }
        }
        bytes("RIFF")
        u32(UInt32(36 + samples.count))
        bytes("WAVEfmt ")
        u32(16)
        u16(1)
        u16(1)
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))
        u16(2)
        u16(16)
        bytes("data")
        u32(UInt32(samples.count))
        wave.append(samples)

        do {
            player = try AVAudioPlayer(data: wave)
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Gameplay must not fail because of audio.
        }
    }
}
