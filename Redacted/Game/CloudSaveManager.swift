import AuthenticationServices
import CloudKit
import Combine
import Foundation
import Security

/// Optional Apple account identity + private iCloud save for the same iCloud account.
/// Sign in with Apple does NOT itself provide cross-device storage: CloudKit
/// requires a signed-in iCloud account and the app's CloudKit entitlement.
@MainActor
final class CloudSaveManager: ObservableObject {
    static let shared = CloudSaveManager()

    @Published private(set) var signedIn = false
    @Published private(set) var syncing = false
    @Published private(set) var status = "Not signed in"
    @Published private(set) var lastSynced: Date?

    private weak var store: CampaignStore?
    private var pendingUpload: Task<Void, Never>?
    private var busy = false

    private let recordID = CKRecord.ID(recordName: "redacted-campaign-save-v1")
    private let database = CKContainer.default().privateCloudDatabase

    private init() {}

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

    private var keychainID: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.UtilityFreak.Redacted.appleSignIn",
            kSecAttrAccount as String: "apple-user",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func setKeychainID(_ id: String?) {
        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.UtilityFreak.Redacted.appleSignIn",
            kSecAttrAccount as String: "apple-user"
        ]
        SecItemDelete(lookup as CFDictionary)
        guard let id, let data = id.data(using: .utf8) else { return }
        var save = lookup
        save[kSecValueData as String] = data
        save[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(save as CFDictionary, nil)
    }

    func attach(_ store: CampaignStore) {
        self.store = store
        guard let userID = keychainID else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
            Task { @MainActor in
                if state == .authorized {
                    self.signedIn = true
                    self.status = "Checking iCloud save…"
                    await self.syncNow()
                } else {
                    self.signedIn = false
                    self.status = error == nil ? "Sign in again to sync" : "Apple sign-in unavailable"
                }
            }
        }
    }

    func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                status = "Apple sign-in did not return an account"
                return
            }
            setKeychainID(credential.user)
            signedIn = true
            status = "Checking private iCloud save…"
            Task { await syncNow() }
        case .failure(let error):
            status = "Sign-in not completed: \(error.localizedDescription)"
        }
    }

    func signOut() {
        pendingUpload?.cancel()
        setKeychainID(nil)
        signedIn = false
        status = "Signed out (local progress is kept)"
        lastSynced = nil
    }

    func settingsChanged() {
        guard signedIn else { return }
        UserDefaults.standard.set(Date(), forKey: "redacted.save.modified")
        if let store { scheduleUpload(progress: store.progress) }
    }

    func scheduleUpload(progress: CampaignProgress) {
        guard signedIn, store != nil else { return }
        pendingUpload?.cancel()
        pendingUpload = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    /// Latest committed save wins for the spendable wallet; it is never added
    /// across two devices (which would duplicate consumable crystals).
    func syncNow() async {
        guard signedIn, !busy, let store else { return }
        busy = true
        syncing = true
        defer { syncing = false; busy = false }

        do {
            let account = try await CKContainer.default().accountStatus()
            guard account == .available else {
                status = "Sign into iCloud in Settings to sync across devices"
                return
            }

            let localTime = UserDefaults.standard.object(forKey: "redacted.save.modified") as? Date
                ?? .distantPast
            let remote: CKRecord?
            do {
                remote = try await database.record(for: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                remote = nil
            }

            if let remote,
               let data = remote["payload"] as? Data,
               let snapshot = try? JSONDecoder().decode(SaveEnvelope.self, from: data),
               snapshot.updatedAt > localTime {
                store.restoreCloudProgress(snapshot.progress)
                snapshot.preferences.restore()
                UserDefaults.standard.set(snapshot.updatedAt, forKey: "redacted.save.modified")
                lastSynced = Date()
                status = "Progress restored from iCloud"
                return
            }

            let envelope = SaveEnvelope(
                progress: store.progress,
                preferences: SavedPreferences(),
                updatedAt: localTime == .distantPast ? Date() : localTime
            )
            let record = remote ?? CKRecord(recordType: "RedactedCampaignSave", recordID: recordID)
            record["payload"] = try JSONEncoder().encode(envelope) as NSData
            record["updatedAt"] = envelope.updatedAt as NSDate
            _ = try await database.save(record)
            lastSynced = Date()
            status = "Progress saved to iCloud"
        } catch let error as CKError where error.code == .serverRecordChanged {
            // A second device updated this record while we were uploading.
            // Refresh on the next manual/automatic attempt; never overwrite it blindly.
            status = "Another device updated this save. Tap Sync Now to refresh."
        } catch {
            status = "Cloud sync unavailable: \(error.localizedDescription)"
        }
    }
}
