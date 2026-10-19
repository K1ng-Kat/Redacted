import Combine
import Foundation
import Security

/// Separate social identity and database: no Apple ID or iCloud is required.
/// Real network traffic is deliberately disabled until a Supabase project and
/// the secure SQL backend are configured; no fake online statuses are shown.
enum DetectiveSocialConfiguration {
    // The publishable key is intended to be shipped in clients; NEVER put a
    // Supabase service_role/secret key here. Configure the SQL RLS functions.
    static let projectURL =
        Bundle.main.object(forInfoDictionaryKey: "RDSocialProjectURL") as? String ?? ""
    static let publishableKey =
        Bundle.main.object(forInfoDictionaryKey: "RDSocialPublishableKey") as? String ?? ""

    static var isConfigured: Bool {
        guard let url = URL(string: projectURL), url.scheme == "https",
              let host = url.host, !host.isEmpty else { return false }
        return !publishableKey.isEmpty
    }
}

struct OnlineDetective: Codable, Identifiable, Hashable {
    let code: String
    let alias: String
    let lastSeen: Date?
    var id: String { code }
    var online: Bool {
        guard let lastSeen else { return false }
        let seconds = Date().timeIntervalSince(lastSeen)
        return seconds >= -30 && seconds < 105
    }

    enum CodingKeys: String, CodingKey {
        case code, alias
        case lastSeen
    }
}

struct DetectiveSocialRequest: Codable, Identifiable {
    let id: Int64
    let code: String
    let alias: String
}

struct DetectiveTaskForce: Codable {
    let id: String
    let code: String
    let name: String
    let isLeader: Bool
    let members: [DetectiveTaskForceMember]
    var onlineCount: Int { members.filter(\.online).count }
}

struct DetectiveTaskForceMember: Codable, Identifiable {
    let code: String
    let alias: String
    let lastSeen: Date?
    let leader: Bool
    var id: String { code }
    var online: Bool {
        guard let lastSeen else { return false }
        let seconds = Date().timeIntervalSince(lastSeen)
        return seconds >= -30 && seconds < 105
    }
}

private struct DetectiveSocialSnapshot: Decodable {
    let code: String
    let alias: String
    let friends: [OnlineDetective]
    let requests: [DetectiveSocialRequest]
    let taskForce: DetectiveTaskForce?
}

private struct DetectiveSocialReply: Decodable {
    let message: String?
}

private struct DetectiveSocialSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let email: String?
}

private struct DetectiveAuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

private enum SocialNetworkError: LocalizedError {
    case unconfigured
    case signInFailed
    case badResponse(String)
    case invalidSession

    var errorDescription: String? {
        switch self {
        case .unconfigured: "Online detective network isn't configured yet."
        case .signInFailed: "Could not create your detective network account."
        case .badResponse(let detail): detail
        case .invalidSession: "Your session expired. Try reconnecting."
        }
    }
}

/// Owns only social data, never campaign progress or currency. Anonymous
/// auth is stored in THIS DEVICE's keychain; a future opt-in identity link
/// is required to recover an anonymous social account after reinstall.
@MainActor
final class DetectiveSocialNetwork: ObservableObject {
    static let shared = DetectiveSocialNetwork()

    @Published private(set) var isBusy = false
    @Published private(set) var connected = false
    @Published private(set) var friends: [OnlineDetective] = []
    @Published private(set) var requests: [DetectiveSocialRequest] = []
    @Published private(set) var taskForce: DetectiveTaskForce?
    @Published private(set) var myCode = ""
    @Published private(set) var myAlias = ""
    @Published private(set) var message = ""
    @Published private(set) var lastChecked: Date?
    @Published private(set) var accountEmail: String?
    @Published private(set) var codeSentTo: String?
    @Published private(set) var codeSentAt: Date?

    var configured: Bool { DetectiveSocialConfiguration.isConfigured }
    var onlineFriends: [OnlineDetective] { friends.filter(\.online) }
    var offlineFriends: [OnlineDetective] { friends.filter { !$0.online } }

    private var token: DetectiveSocialSession?
    private var refreshing = false
    private let keychainKey = "com.UtilityFreak.Redacted.social.session.v1"

    private init() {
        token = readSession()
        accountEmail = token?.email
        if !configured {
            message = "Friends and Task Forces will be available when the detective network server is connected."
        }
    }

    /// Called when a social page first opens, not on every app launch.
    func connect() async {
        guard configured else {
            connected = false
            message = "The detective network server hasn't been connected yet. No iCloud account will be required."
            return
        }
        guard accountEmail != nil else {
            connected = false
            message = "Sign in with your email to use REDACTED Friends and Task Forces."
            return
        }
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await rpc("rd_social_bootstrap", body: [:])
            connected = true
            await heartbeat()
            try await loadSnapshot()
            message = ""
        } catch {
            connected = false
            message = error.localizedDescription
        }
    }

    func refresh() async {
        guard configured else { return }
        if !connected {
            await connect()
            return
        }
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            await heartbeat()
            try await loadSnapshot()
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }

    /// Heartbeats are sent only while the social tab is visible or the player
    /// deliberately checks their Task Force. No background location or polling.
    func heartbeat() async {
        guard connected else { return }
        do {
            try await rpc("rd_social_heartbeat", body: [:])
        } catch {
            // A failed heartbeat should not remove previously loaded friends.
        }
    }

    func sendRequest(code: String) async {
        await mutate("rd_social_send_request", body: ["p_code": code])
    }

    func respond(id: Int64, accept: Bool) async {
        await mutate("rd_social_respond_request",
                     body: ["p_id": id, "p_accept": accept])
    }

    func removeFriend(code: String) async {
        await mutate("rd_social_remove_friend", body: ["p_code": code])
    }

    func createTaskForce(name: String) async {
        await mutate("rd_task_force_create", body: ["p_name": name])
    }

    func joinTaskForce(code: String) async {
        await mutate("rd_task_force_join", body: ["p_code": code])
    }

    func leaveTaskForce() async {
        await mutate("rd_task_force_leave", body: [:])
    }

    private func mutate(_ name: String, body: [String: Any]) async {
        guard connected, !isBusy else {
            if !connected { message = "Connect to the detective network first." }
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let raw = try await rpc(name, body: body)
            let reply = try JSONDecoder().decode(DetectiveSocialReply.self, from: raw)
            try await loadSnapshot()
            message = reply.message ?? "Updated."
        } catch {
            message = error.localizedDescription
        }
    }

    private func loadSnapshot() async throws {
        let raw = try await rpc("rd_social_snapshot", body: [:])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let simple = ISO8601DateFormatter()
            simple.formatOptions = [.withInternetDateTime]
            if let parsed = fractional.date(from: timestamp) ?? simple.date(from: timestamp) {
                return parsed
            }
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid presence timestamp"
            )
        }
        let snapshot = try decoder.decode(DetectiveSocialSnapshot.self, from: raw)
        myCode = snapshot.code
        myAlias = snapshot.alias
        friends = snapshot.friends.sorted {
            if $0.online != $1.online { return $0.online && !$1.online }
            return $0.alias < $1.alias
        }
        requests = snapshot.requests
        taskForce = snapshot.taskForce
        lastChecked = Date()
    }

    // MARK: Secure anonymous session management

    private func makeRequest(path: String, body: Data, bearer: String?) throws -> URLRequest {
        guard configured,
              let base = URL(string: DetectiveSocialConfiguration.projectURL) else {
            throw SocialNetworkError.unconfigured
        }
        let pathParts = path.split(separator: "?", maxSplits: 1).map(String.init)
        var url = base.appendingPathComponent(pathParts[0])
        if pathParts.count == 2 {
            var urlParts = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlParts?.percentEncodedQuery = pathParts[1]
            if let value = urlParts?.url { url = value }
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(DetectiveSocialConfiguration.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearer { req.setValue("Bearer " + bearer, forHTTPHeaderField: "Authorization") }
        req.timeoutInterval = 14
        req.httpBody = body
        return req
    }

    private func call(_ path: String, body: Data, bearer: String?) async throws -> Data {
        let req = try makeRequest(path: path, body: body, bearer: bearer)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw SocialNetworkError.badResponse("Network response unavailable.")
        }
        guard (200..<300).contains(http.statusCode) else {
            struct NetworkProblem: Decodable { let message: String?; let error: String? }
            let body = try? JSONDecoder().decode(NetworkProblem.self, from: data)
            throw SocialNetworkError.badResponse(
                body?.message ?? body?.error ?? "Social server returned HTTP \(http.statusCode)."
            )
        }
        return data
    }

    /// Sign-in and sign-up share the same verified email-code flow.
    /// Supabase Auth verifies codes on the server; the app never knows the
    /// expected OTP and doesn't store it.
    func sendEmailCode(to rawEmail: String) async {
        guard configured else {
            message = "Email service is not connected yet."
            return
        }
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard email.count <= 254,
              email.range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Z0-9a-z.\-]+\.[A-Za-z]{2,}$"#,
                          options: .regularExpression) != nil else {
            message = "Enter a valid email address."
            return
        }
        guard !isBusy else { return }
        if let last = codeSentAt, Date().timeIntervalSince(last) < 60 {
            message = "Wait 60 seconds before requesting a new code."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "email": email, "create_user": true
            ] as [String: Any])
            _ = try await call("/auth/v1/otp", body: body, bearer: nil)
            codeSentTo = email
            codeSentAt = Date()
            message = "Check your inbox for your six-digit REDACTED code."
        } catch {
            message = error.localizedDescription
        }
    }

    func cancelEmailCode() {
        codeSentTo = nil
        // Keep last send time: changing email must not bypass rate limits.
        message = ""
    }

    func verifyEmailCode(_ submitted: String) async {
        guard configured, let email = codeSentTo else {
            message = "Request an email code first."
            return
        }
        let digits = submitted.filter(\.isNumber)
        guard digits.count == 6 else {
            message = "Enter all six digits of the verification code."
            return
        }
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "email": email, "token": digits, "type": "email"
            ])
            let raw = try await call("/auth/v1/verify", body: body, bearer: nil)
            try persistAuth(raw, email: email)
            codeSentTo = nil
            codeSentAt = nil
            connected = false
            try await rpc("rd_social_bootstrap", body: [:])
            connected = true
            try await loadSnapshot()
            message = "Signed into REDACTED."
            await RedactedAccountSave.shared.accountConnected()
        } catch {
            message = "Could not verify code: " + error.localizedDescription
        }
    }

    func deleteAccount() async {
        guard accountEmail != nil, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await rpc("rd_account_delete", body: [:])
            // Account auth has already been deleted on the server.
            clearLocalAccount()
            RedactedAccountSave.shared.accountDeleted()
            message = "REDACTED ID deleted. Local campaign remains on this device."
        } catch {
            message = "Could not delete account: " + error.localizedDescription
        }
    }

    func signOut() async {
        if configured, let access = token?.accessToken {
            _ = try? await call("/auth/v1/logout", body: Data("{}".utf8),
                                bearer: access)
        }
        clearLocalAccount()
        message = "Signed out. Your local campaign remains on this device."
        RedactedAccountSave.shared.accountSignedOut()
    }

    private func clearLocalAccount() {
        clearKeychainSession()
        token = nil
        accountEmail = nil
        codeSentTo = nil
        codeSentAt = nil
        connected = false
        friends = []
        requests = []
        taskForce = nil
        myCode = ""
        myAlias = ""
        lastChecked = nil
    }

    private func renewSession() async throws {
        guard let previous = token else { throw SocialNetworkError.invalidSession }
        let body = try JSONSerialization.data(withJSONObject:
            ["refresh_token": previous.refreshToken])
        let raw = try await call("/auth/v1/token?grant_type=refresh_token",
                                 body: body, bearer: nil)
        try persistAuth(raw, email: previous.email)
    }

    private func persistAuth(_ raw: Data, email: String?) throws {
        let auth = try JSONDecoder().decode(DetectiveAuthResponse.self, from: raw)
        guard !auth.accessToken.isEmpty, !auth.refreshToken.isEmpty else {
            throw SocialNetworkError.signInFailed
        }
        let session = DetectiveSocialSession(
            accessToken: auth.accessToken,
            refreshToken: auth.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(max(60, auth.expiresIn)) - 30),
            email: email
        )
        token = session
        accountEmail = email
        saveSession(session)
    }

    func rpc(_ name: String, body: [String: Any]) async throws -> Data {
        guard token != nil else { throw SocialNetworkError.invalidSession }
        if let session = token, Date() >= session.expiresAt {
            try await renewSession()
        }
        let data = try JSONSerialization.data(withJSONObject: body)
        do {
            return try await call("/rest/v1/rpc/" + name, body: data,
                                  bearer: token?.accessToken)
        } catch {
            // Never silently issue a NEW anonymous account after a session
            // expires: doing so would lose existing friends and group access.
            throw error
        }
    }

    private func readSession() -> DetectiveSocialSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey,
            kSecAttrAccount as String: "social-user",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(DetectiveSocialSession.self, from: data)
    }

    private func clearKeychainSession() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey,
            kSecAttrAccount as String: "social-user"
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func saveSession(_ value: DetectiveSocialSession) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainKey,
            kSecAttrAccount as String: "social-user"
        ]
        SecItemDelete(query as CFDictionary)
        guard let data = try? JSONEncoder().encode(value) else { return }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }
}
