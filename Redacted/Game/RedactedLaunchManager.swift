import Combine
import Foundation
import Network
import SwiftUI

/// Controls only boot-time work. The single-player campaign is local and must
/// never be blocked indefinitely by a Wi-Fi connection or an unfinished server.
@MainActor
final class RedactedLaunchManager: ObservableObject {
    @Published private(set) var progress = 0.02
    @Published private(set) var stage = "OPENING CASE FILES"
    @Published private(set) var issue: LaunchIssue?
    @Published private(set) var ready = false
    @Published private(set) var checking = false

    struct LaunchIssue: Equatable {
        enum Kind: Equatable { case connection, update }
        let kind: Kind
        let title: String
        let detail: String
        let storeURL: URL?
    }

    private var started = false
    private var pathStatus: NWPath.Status?
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "redacted.startup.network")
    private var verifying = false

    /// A future published JSON manifest can require a minimum build for online
    /// play. An empty configuration NEVER claims that the app is up to date.
    private var manifestURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "RDStartupManifestURL")
                as? String,
              let url = URL(string: raw), url.scheme == "https",
              url.host != nil
        else { return nil }
        return url
    }

    private struct PublishedManifest: Decodable {
        let minimumBuild: Int?
        let message: String?
        let appStoreURL: String?
    }

    func start() async {
        guard !started else { return }
        started = true

        // The native iOS LaunchScreen is static. This first in-app frame must
        // render before catalog decoding, SceneKit or online account setup.
        try? await Task.sleep(for: .milliseconds(100))
        guard !Task.isCancelled else { return }
        advance(to: 0.18, stage: "READING LOCAL CASE FILES")
        _ = UserDefaults.standard.data(forKey: "redacted.campaign.v1")
        await animateCheckpoint()

        _ = CampaignCatalog.levels.count
        advance(to: 0.42, stage: "PREPARING INVESTIGATIONS")
        await animateCheckpoint()

        let resources = ["MenuBossa", "LevelShop"]
        for name in resources {
            _ = Bundle.main.url(forResource: name, withExtension: "mp3")
        }
        advance(to: 0.64, stage: "CHECKING CONNECTION")

        // The offline toggle persists, so flight-mode users aren't prompted
        // on every launch once they explicitly choose offline play.
        if UserDefaults.standard.bool(forKey: "redacted.offlineMode") {
            await finish(offline: true)
            return
        }
        beginMonitoring()
        await checkConnection()
    }

    func retry() async {
        guard !verifying && !ready else { return }
        issue = nil
        stage = "RETRYING CONNECTION"
        // Restart the path monitor so Retry gets a fresh status even if the
        // previous callback arrived while airplane mode was enabled.
        monitor?.cancel()
        monitor = nil
        pathStatus = nil
        beginMonitoring()
        await checkConnection()
    }

    func playOffline() {
        guard !ready else { return }
        UserDefaults.standard.set(true, forKey: "redacted.offlineMode")
        issue = nil
        Task { await finish(offline: true) }
    }

    private func beginMonitoring() {
        guard monitor == nil else { return }
        let listener = NWPathMonitor()
        listener.pathUpdateHandler = { [weak self] path in
            let status = path.status
            Task { @MainActor in self?.pathStatus = status }
        }
        listener.start(queue: monitorQueue)
        monitor = listener
    }

    private func checkConnection() async {
        guard !verifying else { return }
        verifying = true
        checking = true
        defer {
            verifying = false
            checking = false
        }
        stage = "CHECKING CONNECTION"
        // NWPathMonitor's first callback is asynchronous. Wait for a bounded
        // result, never indefinitely, and don't assume Wi-Fi means internet.
        for _ in 0..<20 where pathStatus == nil {
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }
        }
        guard pathStatus == .satisfied else {
            issue = LaunchIssue(kind: .connection,
                                title: "CONNECTION UNAVAILABLE",
                                detail: "Redacted cannot reach a network. Try again, or open your saved investigations in Offline Mode.",
                                storeURL: nil)
            stage = "NETWORK UNAVAILABLE"
            return
        }
        advance(to: 0.76, stage: "VERIFYING STARTUP")

        if let url = manifestURL {
            var request = URLRequest(url: url)
            request.timeoutInterval = 4
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200 else { throw URLError(.badServerResponse) }
                let policy = try JSONDecoder().decode(PublishedManifest.self, from: data)
                if let minBuild = policy.minimumBuild,
                   minBuild > (Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0) {
                    let storeLink = policy.appStoreURL.flatMap(URL.init(string:))
                    let safeLink = storeLink?.scheme == "https" &&
                        storeLink?.host == "apps.apple.com" ? storeLink : nil
                    issue = LaunchIssue(kind: .update, title: "UPDATE AVAILABLE",
                                        detail: policy.message ?? "An updated version is required for online play. You can still investigate offline.",
                                        storeURL: safeLink)
                    stage = "UPDATE REQUIRED FOR ONLINE PLAY"
                    return
                }
            } catch {
                issue = LaunchIssue(kind: .connection,
                                    title: "CONNECTION CHECK FAILED",
                                    detail: "The online service did not respond. Retry, or continue with your locally saved cases.",
                                    storeURL: nil)
                stage = "NETWORK CHECK FAILED"
                return
            }
        }
        await finish(offline: false)
    }

    private func finish(offline: Bool) async {
        guard !ready else { return }
        issue = nil
        advance(to: 0.88, stage: offline ? "PREPARING OFFLINE CASES" : "OPENING DETECTIVE HQ")
        await animateCheckpoint()
        advance(to: 1.0, stage: offline ? "OFFLINE CASES READY" : "READY TO INVESTIGATE")
        // Let the animatable bar and matching number both reach 100% on screen
        // before switching to the game. This is presentation, not fake work.
        try? await Task.sleep(for: .milliseconds(480))
        guard !Task.isCancelled else { return }
        monitor?.cancel()
        monitor = nil
        ready = true
    }

    private func advance(to value: Double, stage title: String) {
        guard !ready else { return }
        progress = max(progress, min(value, 1))
        stage = title
    }

    private func animateCheckpoint() async {
        try? await Task.sleep(for: .milliseconds(260))
    }
}
