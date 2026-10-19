import Combine
import Foundation

/// Private account-backed campaign saves, independent from Apple/iCloud.
/// A remote save never silently overwrites an unrelated device's progress.
/// Conflicting writes are rejected by the database revision guard.
@MainActor
final class RedactedAccountSave: ObservableObject {
    static let shared = RedactedAccountSave()

    @Published private(set) var status = "Sign in with email to back up your progress."
    @Published private(set) var syncing = false
    @Published private(set) var needsSaveChoice = false
    @Published private(set) var lastSynced: Date?

    private weak var store: CampaignStore?
    private var ready = false
    private var revision: Int?
    private var pendingRemote: CampaignSaveCodec.SaveEnvelope?
    private var pendingUpload: Task<Void, Never>?
    private let preferencesKey = "redacted.account.save.email"
    private let revisionKey = "redacted.account.save.revision"
    private let syncTimeKey = "redacted.account.save.lastsynced"

    private struct ServerSave: Decodable {
        let exists: Bool
        let revision: Int
        let payload: CampaignSaveCodec.SaveEnvelope?
    }

    private struct WriteResult: Decodable {
        let revision: Int
        let success: Bool
    }

    private init() {}

    func attach(_ campaign: CampaignStore) {
        store = campaign
        if DetectiveSocialNetwork.shared.accountEmail != nil {
            Task { await accountConnected() }
        }
    }

    func accountSignedOut() {
        pendingUpload?.cancel()
        pendingUpload = nil
        revision = nil
        ready = false
        pendingRemote = nil
        needsSaveChoice = false
        status = "Signed out. Local campaign is still on this device."
    }

    func accountConnected() async {
        guard let email = DetectiveSocialNetwork.shared.accountEmail, store != nil,
              !syncing else { return }
        ready = false
        syncing = true
        defer { syncing = false }
        do {
            let response = try await DetectiveSocialNetwork.shared.rpc(
                "rd_account_save_get", body: [:])
            let remote = try JSONDecoder().decode(ServerSave.self, from: response)
            revision = remote.revision
            if remote.exists, let snapshot = remote.payload {
                let sameAccount = UserDefaults.standard.string(forKey: preferencesKey) == email
                let knownRevision = UserDefaults.standard.object(forKey: revisionKey) as? Int
                if sameAccount, knownRevision == remote.revision {
                    needsSaveChoice = false
                    pendingRemote = nil
                    ready = true
                    status = "Account save connected. Progress is backed up."
                    // If this device has played offline since last sync,
                    // upload those local changes after checking the revision.
                    let local = UserDefaults.standard.object(
                        forKey: "redacted.save.modified") as? Date ?? .distantPast
                    let synced = UserDefaults.standard.object(forKey: syncTimeKey)
                        as? Date ?? .distantPast
                    if local > synced { scheduleUpload() }
                } else {
                    pendingRemote = snapshot
                    needsSaveChoice = true
                    status = "Account save found. Choose which progress to keep."
                }
            } else {
                pendingRemote = nil
                needsSaveChoice = false
                ready = true
                revision = 0
                status = "Creating your first private REDACTED backup…"
                // New account only. Safe initial upload, with expected revision 0.
                scheduleUpload()
            }
        } catch {
            status = "Account save unavailable: " + error.localizedDescription
            ready = false
        }
    }

    func restoreAccountSave() {
        guard let snapshot = pendingRemote, let store,
              let email = DetectiveSocialNetwork.shared.accountEmail,
              let revision else { return }
        pendingUpload?.cancel()
        store.restoreCloudProgress(snapshot.progress)
        snapshot.preferences.restore()
        markSynced(email: email, revision: revision)
        ready = true
        needsSaveChoice = false
        pendingRemote = nil
        status = "Account progress restored to this device."
    }

    func keepDeviceSave() async {
        // Explicit user choice. Overwriting a cloud save is never automatic
        // when first linking a device or after a concurrent edit.
        guard needsSaveChoice else { return }
        needsSaveChoice = false
        ready = true
        pendingRemote = nil
        await syncNow()
    }

    func scheduleUpload() {
        guard ready, !needsSaveChoice, store != nil else { return }
        pendingUpload?.cancel()
        pendingUpload = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(2)) }
            catch { return }
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    func syncNow() async {
        guard ready, !needsSaveChoice, let store,
              let email = DetectiveSocialNetwork.shared.accountEmail,
              let revision, !syncing else { return }
        syncing = true
        defer { syncing = false }
        do {
            let envelope = CampaignSaveCodec.SaveEnvelope(
                progress: store.progress,
                preferences: CampaignSaveCodec.SavedPreferences(),
                updatedAt: Date()
            )
            let data = try JSONEncoder().encode(envelope)
            guard let object = try JSONSerialization.jsonObject(with: data)
                    as? [String: Any] else {
                status = "Could not encode your progress."
                return
            }
            let response = try await DetectiveSocialNetwork.shared.rpc(
                "rd_account_save_put",
                body: ["p_payload": object, "p_expected_revision": revision]
            )
            let written = try JSONDecoder().decode(WriteResult.self, from: response)
            guard written.success else {
                status = "Server did not confirm this backup."
                return
            }
            self.revision = written.revision
            markSynced(email: email, revision: written.revision)
            status = "Progress backed up to your REDACTED account."
            lastSynced = Date()
        } catch {
            ready = false
            status = "Backup paused: " + error.localizedDescription
                + " Tap Check Account Save to resolve; local progress is safe."
        }
    }

    func checkAgain() async { await accountConnected() }

    func accountDeleted() {
        accountSignedOut()
        UserDefaults.standard.removeObject(forKey: preferencesKey)
        UserDefaults.standard.removeObject(forKey: revisionKey)
        UserDefaults.standard.removeObject(forKey: syncTimeKey)
        lastSynced = nil
    }

    private func markSynced(email: String, revision: Int) {
        UserDefaults.standard.set(email, forKey: preferencesKey)
        UserDefaults.standard.set(revision, forKey: revisionKey)
        UserDefaults.standard.set(Date(), forKey: syncTimeKey)
    }
}
