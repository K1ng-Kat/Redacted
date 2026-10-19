import CloudKit
import Combine
import Foundation

struct DetectiveFriend: Codable, Identifiable, Equatable {
    let id: String
    let alias: String
}

struct FriendPresence: Identifiable {
    let id: String
    let alias: String
    let online: Bool
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
    @Published private(set) var message = "Create a room or enter a friend's code."
    @Published private(set) var currentMystery: MultiplayerMystery?
    @Published private(set) var onlineFriends: [FriendPresence] = []
    @Published private(set) var requests: [DetectiveFriend] = []
    @Published private(set) var myFriends: [DetectiveFriend] = []
    @Published private(set) var socialEnabled = UserDefaults.standard.bool(forKey: "redacted.social.optin")

    private let db = CKContainer.default().publicCloudDatabase
    private weak var store: CampaignStore?
    private var roomPoll: Task<Void, Never>?
    private var heartbeat: Task<Void, Never>?
    private var host = false
    private var guestID = ""
    private var myResultCreated = false

    var playerID: String {
        let defaults = UserDefaults.standard
        if let value = defaults.string(forKey: "redacted.social.code"), value.count == 8 {
            return value
        }
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let code = String((0..<8).compactMap { _ in alphabet.randomElement() })
        defaults.set(code, forKey: "redacted.social.code")
        return code
    }

    var alias: String { "AGENT-" + playerID.suffix(4) }

    private init() {}

    func attach(_ store: CampaignStore) {
        self.store = store
        myFriends = store.progress.friendContacts
    }

    func activate() {
        guard !socialEnabled else { return }
        socialEnabled = true
        UserDefaults.standard.set(true, forKey: "redacted.social.optin")
    }

    func startPresence() {
        guard socialEnabled, heartbeat == nil else { return }
        heartbeat = Task { [weak self] in
            while !Task.isCancelled {
                await self?.writePresence()
                try? await Task.sleep(for: .seconds(40))
            }
        }
    }

    func stopPresence() {
        heartbeat?.cancel()
        heartbeat = nil
    }

    private func fetch(_ id: String) async throws -> CKRecord? {
        do { return try await db.record(for: CKRecord.ID(recordName: id)) }
        catch let error as CKError where error.code == .unknownItem { return nil }
    }

    private func writePresence() async {
        do {
            let recordName = "rd-player-" + playerID
            let record = try await fetch(recordName)
                ?? CKRecord(recordType: "RDPlayer", recordID: CKRecord.ID(recordName: recordName))
            record["alias"] = alias as NSString
            record["playerCode"] = playerID as NSString
            record["lastSeen"] = NSDate()
            try await db.save(record)
        } catch {
            message = "Online status unavailable: \(error.localizedDescription)"
        }
    }

    private func pollRoom() {
        roomPoll?.cancel()
        roomPoll = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshRoom()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func hostRoom() async {
        activate()
        startPresence()
        leaveRoom()
        phase = .hosting
        message = "Creating private code…"
        for _ in 0..<5 {
            let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
            let code = String((0..<6).compactMap { _ in alphabet.randomElement() })
            let record = CKRecord(recordType: "RDRoom", recordID:
                                  CKRecord.ID(recordName: "rd-room-" + code))
            record["host"] = playerID as NSString
            record["hostAlias"] = alias as NSString
            record["seed"] = NSNumber(value: Int.random(in: 0..<1000))
            record["state"] = "waiting" as NSString
            record["created"] = NSDate()
            do {
                _ = try await db.save(record)
                host = true
                roomCode = code
                currentMystery = MultiplayerMystery.make(record["seed"] as? Int ?? 0)
                phase = .waiting
                message = "Share this code. The race starts automatically when one player joins."
                pollRoom()
                return
            } catch let e as CKError where e.code == .serverRecordChanged {
                continue
            } catch {
                phase = .error
                message = "Could not create room: \(error.localizedDescription)"
                return
            }
        }
        phase = .error
        message = "Could not reserve a room code. Try again."
    }

    func joinRoom(_ rawCode: String) async {
        activate()
        startPresence()
        leaveRoom()
        let code = rawCode.uppercased().filter { $0.isASCII && $0.isLetter || $0.isNumber }
        guard code.count == 6 else {
            phase = .error
            message = "Enter a valid 6-character room code."
            return
        }
        phase = .joining
        message = "Looking up room \(code)…"
        do {
            guard let record = try await fetch("rd-room-" + code),
                  record["state"] as? String == "waiting",
                  let owner = record["host"] as? String else {
                phase = .error
                message = "Room expired, full, or not found."
                return
            }
            guard owner != playerID else {
                phase = .error
                message = "You can't join your own room."
                return
            }
            guard let created = record["created"] as? Date,
                  Date().timeIntervalSince(created) < 3600 else {
                phase = .error
                message = "This room has expired."
                return
            }
            let join = CKRecord(recordType: "RDJoin", recordID:
                                CKRecord.ID(recordName: "rd-join-" + code))
            join["player"] = playerID as NSString
            join["alias"] = alias as NSString
            join["joinedAt"] = NSDate()
            _ = try await db.save(join)
            host = false
            roomCode = code
            opponent = record["hostAlias"] as? String ?? "OPPONENT"
            currentMystery = MultiplayerMystery.make(record["seed"] as? Int ?? 0)
            phase = .waiting
            message = "Joined. Waiting for host to start the mystery…"
            pollRoom()
        } catch let e as CKError where e.code == .serverRecordChanged {
            phase = .error
            message = "Someone already joined this room. Ask for a new code."
        } catch {
            phase = .error
            message = "Could not join: \(error.localizedDescription)"
        }
    }

    func leaveRoom() {
        roomPoll?.cancel()
        roomPoll = nil
        phase = .idle
        roomCode = ""
        opponent = ""
        guestID = ""
        currentMystery = nil
        myResultCreated = false
        message = "Create a room or enter a friend's code."
    }

    func refreshRoom() async {
        guard !roomCode.isEmpty else { return }
        let code = roomCode
        do {
            guard let room = try await fetch("rd-room-" + code) else {
                phase = .error
                message = "This room no longer exists."
                return
            }
            if host {
                if let joined = try await fetch("rd-join-" + code) {
                    guestID = joined["player"] as? String ?? ""
                    opponent = joined["alias"] as? String ?? "OPPONENT"
                    if room["state"] as? String == "waiting" {
                        room["state"] = "playing" as NSString
                        room["started"] = NSDate()
                        _ = try await db.save(room)
                    }
                }
            } else {
                guestID = playerID
            }

            if room["state"] as? String == "playing" && !myResultCreated {
                phase = .playing
                message = "Same mystery, same questions. First correct completion wins."
            }

            let myRecord = try await fetch("rd-finish-" + code + "-" + playerID)
            let otherID = host ? guestID : (room["host"] as? String ?? "")
            if !otherID.isEmpty {
                let other = try await fetch("rd-finish-" + code + "-" + otherID)
                if myResultCreated || myRecord != nil || other != nil {
                    if myRecord == nil && other != nil {
                        phase = .lost
                        message = "\(opponent) solved the mystery first."
                    } else if let mine = myRecord, let theirs = other {
                        let mineDate = mine.creationDate ?? .distantFuture
                        let theirDate = theirs.creationDate ?? .distantFuture
                        phase = mineDate <= theirDate ? .won : .lost
                        message = phase == .won ? "You finished first!" : "Opponent finished first."
                    } else if myRecord != nil {
                        phase = .won
                        message = "Case complete! Waiting for opponent's result."
                    }
                }
            }
        } catch {
            message = "Connection interrupted. Retrying…"
        }
    }

    func finishMystery() async {
        guard phase == .playing, !roomCode.isEmpty, !myResultCreated else { return }
        let code = roomCode
        do {
            let record = CKRecord(recordType: "RDFinish", recordID:
                                  CKRecord.ID(recordName: "rd-finish-" + code + "-" + playerID))
            record["player"] = playerID as NSString
            record["roomCode"] = code as NSString
            record["caseSeed"] = NSNumber(value: currentMystery?.id ?? 0)
            _ = try await db.save(record)
            myResultCreated = true
            phase = .won
            message = "Mystery completed. Checking the other detective's finish time…"
            await refreshRoom()
        } catch {
            message = "Could not submit finish: \(error.localizedDescription)"
        }
    }

    func refreshFriends() async {
        activate()
        startPresence()
        guard let store else { return }
        myFriends = store.progress.friendContacts

        var fresh: [FriendPresence] = []
        for friend in myFriends {
            do {
                let record = try await fetch("rd-player-" + friend.id)
                let seen = record?["lastSeen"] as? Date ?? .distantPast
                let online = Date().timeIntervalSince(seen) <= 105
                fresh.append(FriendPresence(id: friend.id, alias: friend.alias, online: online))
            } catch {
                fresh.append(FriendPresence(id: friend.id, alias: friend.alias, online: false))
            }
        }
        onlineFriends = fresh

        do {
            let predicate = NSPredicate(format: "recipient == %@", playerID)
            let query = CKQuery(recordType: "RDFriendRequest", predicate: predicate)
            let matches = try await db.records(matching: query, resultsLimit: 80)
            let inbound = matches.matchResults.compactMap { _, result -> DetectiveFriend? in
                guard case .success(let record) = result,
                      let id = record["sender"] as? String,
                      let alias = record["alias"] as? String,
                      !store.progress.friendContacts.contains(where: { $0.id == id })
                else { return nil }
                return DetectiveFriend(id: id, alias: alias)
            }
            requests = inbound
        } catch {
            // Public CloudKit queries need the recipient field indexed.
            message = "Friend requests unavailable: \(error.localizedDescription)"
        }

        // When a friend request was accepted, the recipient creates a known
        // acceptance record that the sender can read without public searching.
        let outgoing = UserDefaults.standard.stringArray(forKey: "redacted.social.outgoing") ?? []
        for id in outgoing {
            if let accepted = try? await fetch("rd-accepted-" + id + "-" + playerID),
               let alias = accepted["alias"] as? String {
                store.addFriend(DetectiveFriend(id: id, alias: alias))
            }
        }
        myFriends = store.progress.friendContacts
    }

    func requestFriend(_ raw: String) async {
        activate()
        startPresence()
        let code = raw.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count == 8, code != playerID else {
            message = "Enter another detective's 8-character friend code."
            return
        }
        do {
            guard let friend = try await fetch("rd-player-" + code),
                  let theirAlias = friend["alias"] as? String else {
                message = "No detective found. Their app must have Friends enabled."
                return
            }
            if store?.progress.friendContacts.contains(where: { $0.id == code }) == true {
                message = "Already friends with \(theirAlias)."
                return
            }
            let id = "rd-friend-" + playerID + "-" + code
            let record = try await fetch(id)
                ?? CKRecord(recordType: "RDFriendRequest", recordID: CKRecord.ID(recordName: id))
            record["recipient"] = code as NSString
            record["sender"] = playerID as NSString
            record["alias"] = alias as NSString
            _ = try await db.save(record)
            var outgoing = UserDefaults.standard.stringArray(forKey: "redacted.social.outgoing") ?? []
            if !outgoing.contains(code) {
                outgoing.append(code)
                UserDefaults.standard.set(outgoing, forKey: "redacted.social.outgoing")
            }
            message = "Friend request sent to \(theirAlias)."
        } catch {
            message = "Could not send friend request: \(error.localizedDescription)"
        }
    }

    func acceptFriend(_ request: DetectiveFriend) async {
        guard let store else { return }
        do {
            let id = "rd-accepted-" + playerID + "-" + request.id
            let accepted = try await fetch(id) ??
                CKRecord(recordType: "RDFriendAccepted", recordID: CKRecord.ID(recordName: id))
            accepted["alias"] = alias as NSString
            _ = try await db.save(accepted)
            store.addFriend(request)
            requests.removeAll { $0.id == request.id }
            await refreshFriends()
            message = "Added \(request.alias)."
        } catch {
            message = "Could not accept: \(error.localizedDescription)"
        }
    }

    var inviteURL: URL? {
        guard !roomCode.isEmpty else { return nil }
        return URL(string: "redacted-detective://join/\(roomCode)")
    }
}
