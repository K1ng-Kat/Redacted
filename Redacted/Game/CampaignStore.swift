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
    var crystals = 0
    var crystalDistricts: Set<Int> = []
    var hintTickets = 2
    var hintsBought = 0
    var snippets = 0
    var ownedCosmetics: Set<String> = []
    var equippedCosmetics: [String: String] = [:]
    var friendContacts: [DetectiveFriend] = []
    var socialID: String = CampaignProgress.newSocialID()

    static func newSocialID() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).compactMap { _ in alphabet.randomElement() })
    }

    enum CodingKeys: String, CodingKey {
        case bestStars, lastLevel, tutorialComplete, totalAttempts,
             firstLaunchDate, xp, coins, crystals, crystalDistricts, hintTickets, hintsBought,
             snippets, ownedCosmetics, equippedCosmetics, friendContacts, socialID
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
        crystals = max(0, try box.decodeIfPresent(Int.self, forKey: .crystals) ?? 0)
        crystalDistricts = try box.decodeIfPresent(Set<Int>.self, forKey: .crystalDistricts) ?? []
        // Migrate already-passed districts once without repeating the reward.
        for district in 0..<10 where !crystalDistricts.contains(district) {
            let stages = (district * 10 + 1)...(district * 10 + 10)
            let cleared = stages.allSatisfy { (bestStars[$0] ?? 0) > 0 }
            let perfect = stages.filter { (bestStars[$0] ?? 0) == 3 }.count
            if cleared && perfect >= 7 {
                crystalDistricts.insert(district)
                crystals += 1
            }
        }
        hintTickets = try box.decodeIfPresent(Int.self, forKey: .hintTickets) ?? 2
        hintsBought = try box.decodeIfPresent(Int.self, forKey: .hintsBought) ?? 0
        snippets = max(0, try box.decodeIfPresent(Int.self, forKey: .snippets) ?? 0)
        ownedCosmetics = try box.decodeIfPresent(Set<String>.self, forKey: .ownedCosmetics) ?? []
        equippedCosmetics = try box.decodeIfPresent([String: String].self, forKey: .equippedCosmetics) ?? [:]
        friendContacts = try box.decodeIfPresent([DetectiveFriend].self, forKey: .friendContacts) ?? []
        socialID = try box.decodeIfPresent(String.self, forKey: .socialID)
            ?? UserDefaults.standard.string(forKey: "redacted.social.code")
            ?? Self.newSocialID()
    }
}

struct CasePayout {
    let stars: Int
    let earnedXP: Int
    let earnedCoins: Int
    let earnedTickets: Int
    let earnedCrystals: Int
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
        160 + (rank * 65)
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
    static let hintPrice = 2

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
    var crystals: Int { progress.crystals }
    var hintTickets: Int { progress.hintTickets }
    var snippets: Int { progress.snippets }
    var ownedCosmetics: Set<String> { progress.ownedCosmetics }
    func equippedCosmetic(in slot: CosmeticSlot) -> String? { progress.equippedCosmetics[slot.rawValue] }
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
    static let perfectStarsRequired = 7

    func perfectLevels(in district: Int) -> Int {
        guard (0..<10).contains(district) else { return 0 }
        let start = district * 10 + 1
        return (start..<(start + 10)).filter { stars(for: $0) == 3 }.count
    }

    func districtUnlocked(_ district: Int) -> Bool {
        guard (0..<10).contains(district) else { return false }
        if district == 0 { return true }
        return (0..<district).allSatisfy { prior in
            let chapter = CampaignCatalog.episodes[prior]
            return episodeCompleted(chapter) == 10 &&
                   perfectLevels(in: prior) >= Self.perfectStarsRequired
        }
    }

    var unlockedLevel: Int {
        for level in 1...100 where isUnlocked(level) && stars(for: level) == 0 {
            return level
        }
        for level in 1...100 where isUnlocked(level) && stars(for: level) < 3 {
            return level
        }
        return 100
    }

    var nextLevel: Int { unlockedLevel }
    var progressFraction: Double { Double(levelsCompleted) / 100.0 }
    var allCompleted: Bool { levelsCompleted == 100 }

    func isUnlocked(_ level: Int) -> Bool {
        guard (1...100).contains(level) else { return false }
        let district = (level - 1) / 10
        guard districtUnlocked(district) else { return false }
        return level % 10 == 1 || stars(for: level - 1) > 0
    }

    func canAdvance(after level: Int) -> Bool {
        level < 100 && isUnlocked(level + 1)
    }

    func stars(for level: Int) -> Int { progress.bestStars[level] ?? 0 }

    func recordStarted(_ level: Int) {
        guard isUnlocked(level) else { return }
        progress.lastLevel = level
    }

    func tutorialSeen() {
        progress.tutorialComplete = true
    }


    @discardableResult
    func buySnippets(pack: SnippetPack) -> Bool {
        guard progress.coins >= pack.coins else { return false }
        progress.coins -= pack.coins
        progress.snippets += pack.count
        return true
    }

    @discardableResult
    func unlockCosmetic(_ cosmetic: DetectiveCosmetic, crystals: Bool) -> Bool {
        guard accountLevel >= cosmetic.requiredRank,
              !progress.ownedCosmetics.contains(cosmetic.id) else { return false }
        if crystals {
            guard progress.crystals >= cosmetic.crystalPrice else { return false }
            progress.crystals -= cosmetic.crystalPrice
        } else {
            guard progress.snippets >= cosmetic.snippetPrice else { return false }
            progress.snippets -= cosmetic.snippetPrice
        }
        progress.ownedCosmetics.insert(cosmetic.id)
        progress.equippedCosmetics[cosmetic.slot.rawValue] = cosmetic.id
        return true
    }

    func equipCosmetic(_ cosmetic: DetectiveCosmetic) {
        guard progress.ownedCosmetics.contains(cosmetic.id) else { return }
        progress.equippedCosmetics[cosmetic.slot.rawValue] = cosmetic.id
    }

    func persistSocialIdentity() {
        save()
    }

    func addFriend(_ friend: DetectiveFriend) {
        guard !progress.friendContacts.contains(where: { $0.id == friend.id }) else { return }
        progress.friendContacts.append(friend)
    }

    func removeFriend(_ code: String) {
        progress.friendContacts.removeAll { $0.id == code }
    }

    func unequipCosmetic(slot: CosmeticSlot) {
        progress.equippedCosmetics.removeValue(forKey: slot.rawValue)
    }

    func redeemHint() -> Bool {
        if progress.hintTickets > 0 {
            progress.hintTickets -= 1
            return true
        }
        guard progress.crystals >= Self.hintPrice else { return false }
        progress.crystals -= Self.hintPrice
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

        // One non-repeatable crystal when ALL district unlock requirements are met.
        // It may happen on a replay of an earlier level, not only level 10.
        var earnedCrystals = 0
        let district = (level - 1) / 10
        if !progress.crystalDistricts.contains(district) {
            let range = (district * 10 + 1)...(district * 10 + 10)
            if range.allSatisfy({ (progress.bestStars[$0] ?? 0) > 0 }) &&
               range.filter({ (progress.bestStars[$0] ?? 0) == 3 }).count >= 7 {
                progress.crystalDistricts.insert(district)
                progress.crystals += 1
                earnedCrystals = 1
            }
        }

        let newRank = accountLevel
        let levelsGained = max(0, newRank - oldRank)
        let bonusCoins = levelsGained * 60
        let bonusTickets = 0
        if levelsGained > 0 {
            progress.coins += bonusCoins
        }
        return CasePayout(
            stars: stars, earnedXP: xp,
            earnedCoins: coins + bonusCoins, earnedTickets: bonusTickets,
            earnedCrystals: earnedCrystals,
            levelsGained: levelsGained, newRank: newRank, firstClear: isFirstClear
        )
    }

    func episodeCompleted(_ episode: CampaignEpisode) -> Int {
        (episode.startLevel...episode.endLevel).filter { stars(for: $0) > 0 }.count
    }

    /// A cloud restore replaces the local snapshot without creating a new payout.
    func restoreCloudProgress(_ restored: CampaignProgress) {
        isApplyingCloudSave = true
        progress = restored
        isApplyingCloudSave = false
    }

    private var isApplyingCloudSave = false

    func resetProgress() {
        progress = CampaignProgress()
        UserDefaults.standard.set("midnight", forKey: "redacted.profile.theme")
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
        if !isApplyingCloudSave {
            UserDefaults.standard.set(Date(), forKey: "redacted.save.modified")
            CloudSaveManager.shared.scheduleUpload(progress: progress)
        }
    }
}

// Procedural retro bleeps: no asset downloads or paid services.
@MainActor
final class GameEffects {
    static let shared = GameEffects()

    private enum Sound: Hashable { case tap, mistake, success, coin }
    private var players: [Sound: [AVAudioPlayer]] = [:]
    private var indices: [Sound: Int] = [:]

    private init() {
        prepare(.tap, frequencies: [480], duration: 0.075, volume: 0.13, count: 2)
        prepare(.mistake, frequencies: [230, 180], duration: 0.18, volume: 0.17, count: 1)
        prepare(.success, frequencies: [523, 659, 784], duration: 0.30, volume: 0.21, count: 1)
        prepare(.coin, frequencies: [950, 1250], duration: 0.085, volume: 0.10, count: 4)
    }

    var hapticsOn: Bool {
        UserDefaults.standard.object(forKey: "redacted.fx.haptics") as? Bool ?? true
    }
    var soundOn: Bool {
        UserDefaults.standard.object(forKey: "redacted.fx.sound") as? Bool ?? true
    }

    func tap() {
        if hapticsOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        play(.tap)
    }

    func mistake() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        play(.mistake)
    }

    func success() {
        if hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        play(.success)
    }

    func coinTick() { play(.coin) }

    private func play(_ sound: Sound) {
        guard soundOn, let bank = players[sound], !bank.isEmpty else { return }
        let index = indices[sound, default: 0] % bank.count
        indices[sound] = index + 1
        let player = bank[index]
        if player.isPlaying { player.stop() }
        player.currentTime = 0
        player.play()
    }

    private func prepare(_ sound: Sound, frequencies: [Double],
                         duration: Double, volume: Float, count: Int) {
        let data = wave(frequencies: frequencies, duration: duration)
        var bank: [AVAudioPlayer] = []
        for _ in 0..<count {
            if let player = try? AVAudioPlayer(data: data) {
                player.volume = volume
                player.prepareToPlay()
                bank.append(player)
            }
        }
        players[sound] = bank
    }

    private func wave(frequencies: [Double], duration: Double) -> Data {
        let sampleRate = 22_050
        let count = Int(Double(sampleRate) * duration)
        var pcm = Data(capacity: count * 2)

        for i in 0..<count {
            let time = Double(i) / Double(sampleRate)
            let note = min(frequencies.count - 1,
                           Int(Double(frequencies.count) * time / duration))
            let envelope = min(1, time * 130) * pow(max(0, 1 - time / duration), 2)
            let sample = Int16(sin(2 * Double.pi * frequencies[note] * time) * envelope * 11000)
            var little = sample.littleEndian
            withUnsafeBytes(of: &little) { pcm.append(contentsOf: $0) }
        }

        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        func u32(_ value: UInt32) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }

        ascii("RIFF")
        u32(UInt32(36 + pcm.count))
        ascii("WAVEfmt ")
        u32(16)
        u16(1)
        u16(1)
        u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2))
        u16(2)
        u16(16)
        ascii("data")
        u32(UInt32(pcm.count))
        data.append(pcm)
        return data
    }
}
