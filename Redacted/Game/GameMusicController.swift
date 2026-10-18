import AVFoundation
import Foundation

/// Plays two bundled CC0 tracks. Never streams music from a third-party server.
/// Missing resources fail quietly without affecting gameplay.
@MainActor
final class GameMusicController {
    static let shared = GameMusicController()

    enum Scene {
        case menu
        case level
    }

    private var menuPlayer: AVAudioPlayer?
    private var levelPlayer: AVAudioPlayer?
    private var currentScene: Scene = .menu

    private init() {}

    func prepare() {
        if menuPlayer == nil {
            menuPlayer = load(named: "MenuBossa")
        }
        if levelPlayer == nil {
            levelPlayer = load(named: "LevelShop")
        }
    }

    func update(scene: Scene,
                enabled: Bool,
                menuVolume: Double,
                levelVolume: Double) {
        currentScene = scene

        prepare()

        let menuTarget: Float = enabled && scene == .menu
            ? Float(min(1, max(0, menuVolume))) : 0
        let levelTarget: Float = enabled && scene == .level
            ? Float(min(1, max(0, levelVolume))) : 0

        transition(menuPlayer, to: menuTarget)
        transition(levelPlayer, to: levelTarget)
    }

    func pause() {
        menuPlayer?.pause()
        levelPlayer?.pause()
    }

    private func transition(_ player: AVAudioPlayer?, to target: Float) {
        guard let player else { return }
        if target > 0 && !player.isPlaying {
            // Ensure fade-in is audible even when switching from a paused track.
            player.volume = 0
            player.play()
        }
        if player.isPlaying {
            player.setVolume(target, fadeDuration: 0.55)
        }
    }

    private func load(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else {
            return nil
        }

        do {
            // Ambient audio respects the silent switch and mixes with other audio.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }
}
