import AuthenticationServices
import Foundation
import Security
import UIKit
import AntennaCore

enum RedditConnectionState: Equatable {
    case fixture
    case connecting
    case connected(username: String)
    case failed(message: String)

    var description: String {
        switch self {
        case .fixture: "Fixture mode"
        case .connecting: "Connecting…"
        case let .connected(username): "u/\(username)"
        case .failed: "Connection failed"
        }
    }
}

enum RedditOAuthError: LocalizedError {
    case notConfigured
    case couldNotStart
    case invalidCallback
    case stateMismatch
    case accessDenied
    case tokenRejected
    case unavailable

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Reddit API approval and an installed-app client ID are required first."
        case .couldNotStart:
            "The Reddit sign-in window could not be opened."
        case .invalidCallback:
            "Reddit returned an invalid sign-in response."
        case .stateMismatch:
            "The Reddit sign-in response failed its security check."
        case .accessDenied:
            "Reddit access was not granted."
        case .tokenRejected:
            "Reddit rejected the authorization token. Check the client ID and redirect URI."
        case .unavailable:
            "Reddit is unavailable. Try again later."
        }
    }
}

@MainActor
final class RedditOAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    private struct StoredCredential: Codable {
        var accessToken: String
        var refreshToken: String?
        var expiresAt: Date
        var scope: String
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: TimeInterval
        let scope: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case scope
        }
    }

    private struct IdentityResponse: Decodable {
        let id: String
        let name: String
        let linkKarma: Int
        let commentKarma: Int

        enum CodingKeys: String, CodingKey {
            case id, name
            case linkKarma = "link_karma"
            case commentKarma = "comment_karma"
        }
    }

    private let callbackScheme = "reantenna"
    private let redirectURI = "reantenna://oauth"
    private let scopes = ["identity", "read"]
    private let keychain = RedditCredentialKeychain()
    private let session: URLSession
    private var credential: StoredCredential?
    private var authenticationSession: ASWebAuthenticationSession?

    let clientID: String
    let developerUsername: String

    init(bundle: Bundle = .main, session: URLSession? = nil) {
        clientID = (bundle.object(forInfoDictionaryKey: "RedditClientID") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        developerUsername = (
            bundle.object(forInfoDictionaryKey: "RedditDeveloperUsername") as? String ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.ephemeral
            sessionConfiguration.urlCache = nil
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: sessionConfiguration)
        }
        credential = keychain.load()
        super.init()
    }

    var isConfigured: Bool {
        !clientID.isEmpty && !developerUsername.isEmpty
    }

    var hasStoredCredential: Bool {
        credential != nil
    }

    var requestedScopesDescription: String {
        scopes.joined(separator: ", ")
    }

    var apiConfiguration: RedditAPIConfiguration? {
        guard isConfigured else { return nil }
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "0"
        return RedditAPIConfiguration(
            clientID: clientID,
            redirectURI: redirectURI,
            userAgent: "ios:com.chocotonic.reantenna:v\(version) (by /u/\(developerUsername))"
        )
    }

    func authorize() async throws -> AccountSummary {
        guard isConfigured else { throw RedditOAuthError.notConfigured }
        let state = try secureState()
        let authorizationURL = try makeAuthorizationURL(state: state)
        let callbackURL = try await openAuthorizationSession(url: authorizationURL)
        let code = try validateCallback(callbackURL, expectedState: state)
        credential = try await exchangeAuthorizationCode(code)
        if let credential {
            try keychain.save(credential)
        }
        return try await fetchIdentity()
    }

    func restoreAccount() async throws -> AccountSummary? {
        guard isConfigured, credential != nil else { return nil }
        return try await fetchIdentity()
    }

    func validAccessToken() async throws -> String {
        guard var credential else { throw RedditServiceError.unauthorized }
        if credential.expiresAt.timeIntervalSinceNow > 60 {
            return credential.accessToken
        }
        guard let refreshToken = credential.refreshToken else {
            throw RedditServiceError.unauthorized
        }

        let refreshed = try await tokenRequest(
            parameters: [
                URLQueryItem(name: "grant_type", value: "refresh_token"),
                URLQueryItem(name: "refresh_token", value: refreshToken),
            ]
        )
        credential.accessToken = refreshed.accessToken
        credential.refreshToken = refreshed.refreshToken ?? refreshToken
        credential.expiresAt = Date().addingTimeInterval(refreshed.expiresIn)
        credential.scope = refreshed.scope
        self.credential = credential
        try keychain.save(credential)
        return credential.accessToken
    }

    func logout() async {
        if let token = credential?.refreshToken ?? credential?.accessToken, isConfigured {
            try? await revoke(token: token)
        }
        credential = nil
        keychain.delete()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.flatMap(\.windows).first
            ?? ASPresentationAnchor()
    }

    private func makeAuthorizationURL(state: String) throws -> URL {
        var components = URLComponents(string: "https://www.reddit.com/api/v1/authorize.compact")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "duration", value: "permanent"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
        ]
        guard let url = components?.url else { throw RedditOAuthError.unavailable }
        return url
    }

    private func openAuthorizationSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.authenticationSession = nil
                    if let authenticationError = error as? ASWebAuthenticationSessionError,
                       authenticationError.code == .canceledLogin
                    {
                        continuation.resume(throwing: RedditOAuthError.accessDenied)
                    } else if error != nil {
                        continuation.resume(throwing: RedditOAuthError.unavailable)
                    } else if let callbackURL {
                        continuation.resume(returning: callbackURL)
                    } else {
                        continuation.resume(throwing: RedditOAuthError.invalidCallback)
                    }
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            authenticationSession = session
            if !session.start() {
                authenticationSession = nil
                continuation.resume(throwing: RedditOAuthError.couldNotStart)
            }
        }
    }

    private func validateCallback(_ url: URL, expectedState: String) throws -> String {
        guard url.scheme == callbackScheme, url.host == "oauth" else {
            throw RedditOAuthError.invalidCallback
        }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if items.first(where: { $0.name == "error" })?.value != nil {
            throw RedditOAuthError.accessDenied
        }
        guard items.first(where: { $0.name == "state" })?.value == expectedState else {
            throw RedditOAuthError.stateMismatch
        }
        guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            throw RedditOAuthError.invalidCallback
        }
        return code
    }

    private func exchangeAuthorizationCode(_ code: String) async throws -> StoredCredential {
        let token = try await tokenRequest(
            parameters: [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
            ]
        )
        return StoredCredential(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: Date().addingTimeInterval(token.expiresIn),
            scope: token.scope
        )
    }

    private func tokenRequest(parameters: [URLQueryItem]) async throws -> TokenResponse {
        guard let url = URL(string: "https://www.reddit.com/api/v1/access_token") else {
            throw RedditOAuthError.unavailable
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(Data("\(clientID):".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        request.setValue(apiConfiguration?.userAgent, forHTTPHeaderField: "User-Agent")
        var components = URLComponents()
        components.queryItems = parameters
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RedditOAuthError.unavailable }
        guard (200..<300).contains(http.statusCode) else { throw RedditOAuthError.tokenRejected }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func fetchIdentity() async throws -> AccountSummary {
        guard let url = URL(string: "https://oauth.reddit.com/api/v1/me") else {
            throw RedditOAuthError.unavailable
        }
        let token = try await validAccessToken()
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiConfiguration?.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RedditOAuthError.unavailable }
        guard (200..<300).contains(http.statusCode) else { throw RedditOAuthError.tokenRejected }
        let identity = try JSONDecoder().decode(IdentityResponse.self, from: data)
        return AccountSummary(
            id: identity.id,
            username: identity.name,
            karma: identity.linkKarma + identity.commentKarma
        )
    }

    private func revoke(token: String) async throws {
        guard let url = URL(string: "https://www.reddit.com/api/v1/revoke_token") else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(Data("\(clientID):".utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "token", value: token)]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        _ = try await session.data(for: request)
    }

    private func secureState() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw RedditOAuthError.unavailable
        }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private final class RedditCredentialKeychain {
    private let service = "com.chocotonic.reantenna.oauth"
    private let account = "reddit-token"

    func save<Value: Encodable>(_ value: Value) throws {
        let data = try JSONEncoder().encode(value)
        let key = query
        let updates = [kSecValueData as String: data]
        let status = SecItemUpdate(key as CFDictionary, updates as CFDictionary)
        if status == errSecItemNotFound {
            var item = key
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw RedditOAuthError.unavailable
            }
        } else if status != errSecSuccess {
            throw RedditOAuthError.unavailable
        }
    }

    func load<Value: Decodable>() -> Value? {
        var item = query
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(item as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func delete() {
        SecItemDelete(query as CFDictionary)
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
