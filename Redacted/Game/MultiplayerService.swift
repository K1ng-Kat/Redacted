import Combine
import Foundation

enum DuelEmote: String, CaseIterable, Identifiable {
    case gg, wave, clue, brilliant, wow, hurry, thinking, applause
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .gg: "🤝"
        case .wave: "👋"
        case .clue: "🔍"
        case .brilliant: "💡"
        case .wow: "😮"
        case .hurry: "⏳"
        case .thinking: "🤔"
        case .applause: "👏"
        }
    }
    var label: String {
        switch self {
        case .gg: "Good game"
        case .wave: "Hello"
        case .clue: "Found a clue"
        case .brilliant: "Brilliant"
        case .wow: "Wow"
        case .hurry: "Time's ticking"
        case .thinking: "Thinking"
        case .applause: "Well played"
        }
    }
}

/// Kept for existing local save decoding. New friendships now belong to
/// the authenticated REDACTED ID account, not an iCloud friend record.
struct DetectiveFriend: Codable, Identifiable, Equatable {
    let id: String
    let alias: String
}

@MainActor
final class MultiplayerService: ObservableObject {
    static let shared = MultiplayerService()
    enum Phase: Equatable {
        case idle, hosting, joining, waiting, playing, won, lost, error
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var roomCode = ""
    @Published private(set) var opponent = ""
    @Published private(set) var message = "Create a room or join with a code."
    @Published private(set) var currentMystery: MultiplayerMystery?
    @Published private(set) var opponentEmote: DuelEmote?
    @Published private(set) var opponentEmoteLabel = ""
    @Published private(set) var emoteMessage = ""

    private var poll: Task<Void, Never>?
    private var lastSent = Date.distantPast
    private var lastReceived = Date.distantPast
    private var displayEmoteTask: Task<Void, Never>?
    private var submittedFinish = false

    private let social = DetectiveSocialNetwork.shared

    var playerID: String { social.myCode }
    var alias: String { social.myAlias }
    var inviteURL: URL? {
        guard !roomCode.isEmpty else { return nil }
        return URL(string: "redacted-detective://join/\(roomCode)")
    }

    private init() {}

    func attach(_ store: CampaignStore) {
        // 1v1 uses authenticated REDACTED ID now. It doesn't require
        // an iCloud account or write to CampaignProgress.
    }

    func activate() {}
    func startPresence() {}
    func stopPresence() {}

    private struct CreatedRoom: Decodable {
        let code: String
        let seed: Int
    }
    private struct JoinedRoom: Decodable {
        let code: String
        let seed: Int
    }
    private struct RoomSnapshot: Decodable {
        let code: String
        let seed: Int
        let phase: String
        let opponent: String
        let opponentEmote: String?
        let opponentEmoteAt: String?
    }
    private struct RPCStatus: Decodable { let success: Bool }

    private func roomRPC(_ name: String, _ fields: [String: Any]) async throws -> Data {
        guard social.accountEmail != nil else {
            throw NSError(domain: "REDACTED", code: 401,
                          userInfo: [NSLocalizedDescriptionKey:
                                    "Sign in to REDACTED ID to play multiplayer."])
        }
        return try await social.rpc(name, body: fields)
    }

    private func beginPolling() {
        poll?.cancel()
        poll = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshRoom()
                do { try await Task.sleep(for: .seconds(2)) }
                catch { break }
            }
        }
    }

    func hostRoom() async {
        guard social.accountEmail != nil else {
            phase = .error
            message = "Sign in to REDACTED ID to host a match."
            return
        }
        leaveRoom()
        phase = .hosting
        message = "Creating secure detective match…"
        do {
            let raw = try await roomRPC("rd_duel_create", [:])
            let newRoom = try JSONDecoder().decode(CreatedRoom.self, from: raw)
            roomCode = newRoom.code
            currentMystery = MultiplayerMystery.make(newRoom.seed)
            phase = .waiting
            message = "Share your private room code. The duel starts when your opponent joins."
            beginPolling()
        } catch {
            phase = .error
            message = error.localizedDescription
        }
    }

    func joinRoom(_ rawCode: String) async {
        guard social.accountEmail != nil else {
            phase = .error
            message = "Sign in to REDACTED ID before joining the duel."
            return
        }
        let code = rawCode.uppercased()
            .filter { $0.isASCII && ($0.isNumber || ("A"..."F").contains(String($0))) }
        guard code.count == 6 else {
            phase = .error
            message = "Enter the six-character invite code."
            return
        }
        leaveRoom()
        phase = .joining
        message = "Joining private match…"
        do {
            let raw = try await roomRPC("rd_duel_join", ["p_code": code])
            let joined = try JSONDecoder().decode(JoinedRoom.self, from: raw)
            roomCode = joined.code
            currentMystery = MultiplayerMystery.make(joined.seed)
            phase = .playing
            message = "Both detectives received the same case. First verified completion wins."
            beginPolling()
        } catch {
            phase = .error
            message = error.localizedDescription
        }
    }

    func leaveRoom() {
        poll?.cancel()
        poll = nil
        displayEmoteTask?.cancel()
        opponentEmote = nil
        roomCode = ""
        currentMystery = nil
        opponent = ""
        lastReceived = .distantPast
        lastSent = .distantPast
        submittedFinish = false
        emoteMessage = ""
        phase = .idle
        message = "Create a room or join with a code."
    }

    func refreshRoom() async {
        let code = roomCode
        guard !code.isEmpty else { return }
        do {
            let raw = try await roomRPC("rd_duel_snapshot", ["p_code": code])
            guard code == roomCode else { return }
            let info = try JSONDecoder().decode(RoomSnapshot.self, from: raw)
            opponent = info.opponent
            switch info.phase {
            case "waiting":
                phase = .waiting
                message = "Waiting for a second detective to join…"
            case "playing":
                if !submittedFinish {
                    phase = .playing
                    message = "Find three clues before your opponent!"
                }
            case "won":
                phase = .won
                message = "You solved the mystery first!"
            case "lost":
                phase = .lost
                message = "Your opponent solved the case first."
            default:
                phase = .error
                message = "Unknown match state."
            }
            if phase == .playing,
               let word = info.opponentEmote,
               let emote = DuelEmote(rawValue: word),
               let stampText = info.opponentEmoteAt {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let fallback = ISO8601DateFormatter()
                fallback.formatOptions = [.withInternetDateTime]
                if let stamp = iso.date(from: stampText) ?? fallback.date(from: stampText),
                   stamp > lastReceived, stamp <= Date().addingTimeInterval(5) {
                    lastReceived = stamp
                    displayEmoteTask?.cancel()
                    opponentEmote = emote
                    opponentEmoteLabel = opponent
                    displayEmoteTask = Task { [weak self] in
                        do { try await Task.sleep(for: .seconds(3)) }
                        catch { return }
                        self?.opponentEmote = nil
                    }
                }
            }
        } catch {
            if !submittedFinish { message = "Connection interrupted. Reconnecting…" }
        }
    }

    /// The database checks all three correct answers against this room's
    /// case seed and timestamps the winner on the server.
    func finishMystery(evidence: Int, code: String, suspect: Int) async {
        guard phase == .playing, !roomCode.isEmpty, !submittedFinish else { return }
        submittedFinish = true
        do {
            let raw = try await roomRPC("rd_duel_finish", [
                "p_code": roomCode,
                "p_evidence": evidence,
                "p_envelope": code,
                "p_suspect": suspect
            ])
            let response = try JSONDecoder().decode(RPCStatus.self, from: raw)
            guard response.success else {
                submittedFinish = false
                message = "Server couldn't validate this result."
                return
            }
            await refreshRoom()
        } catch {
            submittedFinish = false
            message = "Finish not submitted: " + error.localizedDescription
        }
    }

    func sendEmote(_ emote: DuelEmote) async {
        guard phase == .playing, !roomCode.isEmpty else { return }
        guard Date().timeIntervalSince(lastSent) >= 5 else {
            emoteMessage = "Wait a moment before sending again."
            return
        }
        do {
            let raw = try await roomRPC("rd_duel_emote", [
                "p_code": roomCode, "p_emote": emote.rawValue
            ])
            let status = try JSONDecoder().decode(RPCStatus.self, from: raw)
            if status.success {
                lastSent = Date()
                emoteMessage = "Sent " + emote.emoji
            }
        } catch {
            emoteMessage = "Emote unavailable: " + error.localizedDescription
        }
    }
}
