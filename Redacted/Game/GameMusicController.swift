import AVFoundation
import Foundation

@MainActor
final class GameMusicController {
    static let shared = GameMusicController()

    enum Scene { case menu, level }

    private var menuPlayer: AVAudioPlayer?
    private var levelPlayer: AVAudioPlayer?
    private var prepared = false
    private init() {}

    func prepare() {
        guard !prepared else { return }
        prepared = true
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: [.mixWithOthers])
        } catch {
            #if DEBUG
            print("REDACTED audio session setup: \(error)")
            #endif
        }
        menuPlayer = load(named: "MenuBossa")
        levelPlayer = load(named: "LevelShop")
    }

    func update(scene: Scene, enabled: Bool,
                menuVolume: Double, levelVolume: Double) {
        prepare()
        let active = scene == .menu ? menuPlayer : levelPlayer
        let inactive = scene == .menu ? levelPlayer : menuPlayer

        // Prevent both tracks being audible, even briefly.
        inactive?.volume = 0
        inactive?.pause()

        let desired = scene == .menu ? menuVolume : levelVolume
        let volume = Float(min(1, max(0, desired)))
        guard enabled, volume > 0, let active else {
            menuPlayer?.pause()
            levelPlayer?.pause()
            return
        }
        active.volume = volume
        if !active.isPlaying {
            active.play()
        }
    }

    func pause() {
        menuPlayer?.pause()
        levelPlayer?.pause()
    }

    private func load(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            #if DEBUG
            print("REDACTED: Missing bundled \(name).mp3")
            #endif
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            return player
        } catch {
            #if DEBUG
            print("REDACTED: Failed audio initialization: \(error)")
            #endif
            return nil
        }
    }
}
