import Foundation
import LocalAuthentication
import SwiftUI
import AntennaCore

enum BrowserPreference: String, CaseIterable {
    case embedded = "Embedded Safari"
    case safari = "Safari"
    case chrome = "Chrome"
}

enum PaginationPreference: String, CaseIterable {
    case automatic = "Automatic"
    case manual = "Manual"
}

enum AppRoute: Hashable {
    case post(String)
    case settings
    case redditAccount
    case privacy
    case subredditPicker
    case listing(String)
}

@MainActor
final class AppModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var accounts: [AccountSummary] = []
    @Published var path: [AppRoute] = []
    @Published var isMenuOpen = false
    @Published var selectedFeed = "Front"
    @Published var sort: FeedSort = .hot
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var writeErrorMessage: String?
    @Published private(set) var redditConnectionState: RedditConnectionState = .fixture
    @Published private(set) var redditConnectionError: String?
    @Published private(set) var isAuthenticatingReddit = false
    @Published var preferences: AppPreferences {
        didSet { savePreferences() }
    }
    @Published var defaultBrowser: BrowserPreference {
        didSet { UserDefaults.standard.set(defaultBrowser.rawValue, forKey: DefaultsKey.browser) }
    }
    @Published var pagination: PaginationPreference {
        didSet { UserDefaults.standard.set(pagination.rawValue, forKey: DefaultsKey.pagination) }
    }
    @Published var cellularDownloadLimitMB: Int {
        didSet { UserDefaults.standard.set(cellularDownloadLimitMB, forKey: DefaultsKey.cellularLimit) }
    }
    @Published var imageCacheLimitMB: Int {
        didSet {
            UserDefaults.standard.set(imageCacheLimitMB, forKey: DefaultsKey.imageCacheLimit)
            configureURLCache()
        }
    }
    @Published private(set) var recentlyViewedPostIDs: [String]
    @Published private(set) var pendingWriteKeys: Set<String> = []

    private let fixtureService: any RedditService
    private let oauth: RedditOAuthManager
    private(set) var service: any RedditService

    init(
        service: any RedditService,
        oauth: RedditOAuthManager = RedditOAuthManager()
    ) {
        fixtureService = service
        self.service = service
        self.oauth = oauth
        let defaults = UserDefaults.standard
        if
            let data = defaults.data(forKey: DefaultsKey.preferences),
            let decoded = try? JSONDecoder().decode(AppPreferences.self, from: data)
        {
            preferences = decoded
        } else {
            preferences = AppPreferences()
        }

        defaultBrowser = BrowserPreference(
            rawValue: defaults.string(forKey: DefaultsKey.browser) ?? ""
        ) ?? .embedded
        pagination = PaginationPreference(
            rawValue: defaults.string(forKey: DefaultsKey.pagination) ?? ""
        ) ?? .automatic
        cellularDownloadLimitMB = defaults.object(forKey: DefaultsKey.cellularLimit) as? Int ?? 10
        imageCacheLimitMB = defaults.object(forKey: DefaultsKey.imageCacheLimit) as? Int ?? 256
        recentlyViewedPostIDs = defaults.stringArray(forKey: DefaultsKey.history) ?? []
        configureURLCache()
        enforceCacheRetentionWindow()
    }

    var preferredColorScheme: ColorScheme? {
        switch preferences.theme {
        case .system: nil
        case .day: .light
        case .night: .dark
        }
    }

    func start() async {
        await restoreRedditConnection()
        async let loadPosts: Void = refresh()
        async let loadAccounts: Void = fetchAccounts()
        _ = await (loadPosts, loadAccounts)
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedPosts = try await service.posts(in: selectedFeed, sort: sort)
            let readIDs = Set(recentlyViewedPostIDs)
            posts = loadedPosts.map { post in
                var post = post
                if preferences.keepHistory, readIDs.contains(post.id) {
                    post.isRead = true
                }
                return post
            }
        } catch {
            errorMessage = "Could not load this feed. Pull to try again."
        }
    }

    func fetchAccounts() async {
        accounts = await service.accounts()
    }

    func openPost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isRead = true
        }
        if preferences.keepHistory {
            recentlyViewedPostIDs.removeAll { $0 == post.id }
            recentlyViewedPostIDs.insert(post.id, at: 0)
            recentlyViewedPostIDs = Array(recentlyViewedPostIDs.prefix(100))
            UserDefaults.standard.set(recentlyViewedPostIDs, forKey: DefaultsKey.history)
        }
        path.append(.post(post.id))
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func toggleMenu() {
        withAnimation(.snappy(duration: 0.22)) {
            isMenuOpen.toggle()
        }
    }

    func closeMenu() {
        withAnimation(.snappy(duration: 0.22)) {
            isMenuOpen = false
        }
    }

    func selectRoute(_ route: AppRoute) {
        closeMenu()
        path.append(route)
    }

    func setSort(_ newSort: FeedSort) {
        sort = newSort
        Task { await refresh() }
    }

    /// Opens a user-selected subreddit after validating the public Reddit name.
    /// Returns an error suitable for presenting inline, or `nil` on success.
    func openSubreddit(named input: String) async -> String? {
        let subreddit = normalizedSubredditName(input)
        guard subreddit.range(
            of: #"^[A-Za-z0-9_]{2,21}$"#,
            options: .regularExpression
        ) != nil else {
            return "Enter a subreddit name using 2–21 letters, numbers, or underscores."
        }

        let previousFeed = selectedFeed
        let previousPosts = posts
        selectedFeed = "/r/\(subreddit)"
        await refresh()

        if let loadingError = errorMessage {
            selectedFeed = previousFeed
            posts = previousPosts
            errorMessage = nil
            return loadingError
        }

        path.removeAll()
        closeMenu()
        return nil
    }

    func updatePost(id: String, _ change: (inout Post) -> Void) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        change(&posts[index])
    }

    func setHistoryRetention(_ keepHistory: Bool) {
        preferences.keepHistory = keepHistory
        if !keepHistory {
            clearReadHistory()
        }
    }

    func clearReadHistory() {
        recentlyViewedPostIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: DefaultsKey.history)
        for index in posts.indices {
            posts[index].isRead = false
        }
    }

    func clearMediaCache() {
        URLCache.shared.removeAllCachedResponses()
    }

    var isRedditOAuthConfigured: Bool {
        oauth.isConfigured
    }

    var redditRequestedScopes: String {
        oauth.requestedScopesDescription
    }

    var isRedditConnected: Bool {
        if case .connected = redditConnectionState { return true }
        return false
    }

    var connectedRedditUsername: String? {
        guard case let .connected(username) = redditConnectionState else { return nil }
        return username
    }

    var isUsingFixtureData: Bool { !isRedditConnected }

    func isWritePending(_ key: String) -> Bool {
        pendingWriteKeys.contains(key)
    }

    func vote(fullname: String, direction: VoteState) async -> Bool {
        await performWrite(key: "vote:\(fullname)") {
            try await self.service.vote(fullName: fullname, direction: direction)
        }
    }

    func setSaved(fullname: String, isSaved: Bool) async -> Bool {
        await performWrite(key: "save:\(fullname)") {
            try await self.service.setSaved(fullName: fullname, isSaved: isSaved)
        }
    }

    func submitComment(parentFullname: String, text: String) async -> Bool {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return false }
        return await performWrite(key: "comment:\(parentFullname)") {
            _ = try await self.service.submitComment(parentFullName: parentFullname, text: body)
        }
    }

    func edit(fullname: String, text: String) async -> Bool {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return false }
        return await performWrite(key: "edit:\(fullname)") {
            try await self.service.editText(fullName: fullname, text: body)
        }
    }

    func delete(fullname: String) async -> Bool {
        await performWrite(key: "delete:\(fullname)") {
            try await self.service.deleteText(fullName: fullname)
        }
    }

    private func performWrite(
        key: String,
        operation: () async throws -> Void
    ) async -> Bool {
        guard !pendingWriteKeys.contains(key) else { return false }
        pendingWriteKeys.insert(key)
        writeErrorMessage = nil
        defer { pendingWriteKeys.remove(key) }

        do {
            try await operation()
            return true
        } catch let RedditServiceError.rateLimited(retryAfter) {
            writeErrorMessage = "Reddit's rate limit was reached. Try again in \(max(1, Int(ceil(retryAfter)))) seconds."
        } catch RedditServiceError.unauthorized {
            writeErrorMessage = "Reddit authorization expired. Reconnect your account in Settings and try again."
        } catch RedditServiceError.forbidden {
            writeErrorMessage = "Reddit does not permit that action on this content or with the current account."
        } catch let RedditServiceError.apiError(_, message) {
            writeErrorMessage = message
        } catch let RedditServiceError.invalidRequest(message) {
            writeErrorMessage = message
        } catch RedditServiceError.unsupportedOperation {
            writeErrorMessage = "That Reddit action is not available in this build."
        } catch {
            writeErrorMessage = "Reddit did not accept that action. Check your connection and try again."
        }
        return false
    }

    func connectReddit() async {
        guard !isAuthenticatingReddit else { return }
        isAuthenticatingReddit = true
        redditConnectionError = nil
        redditConnectionState = .connecting
        defer { isAuthenticatingReddit = false }

        do {
            let account = try await oauth.authorize()
            activateLiveService(account: account)
            await refresh()
        } catch {
            redditConnectionError = error.localizedDescription
            redditConnectionState = .failed(message: error.localizedDescription)
        }
    }

    func disconnectReddit() async {
        await oauth.logout()
        service = fixtureService
        redditConnectionState = .fixture
        redditConnectionError = nil
        await fetchAccounts()
        await refresh()
    }

    func deleteAllRedditData() async {
        await oauth.logout()
        service = fixtureService
        redditConnectionState = .fixture
        redditConnectionError = nil
        clearReadHistory()
        clearMediaCache()
        await fetchAccounts()
        await refresh()
    }

    var biometricAvailabilityDescription: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Unavailable"
        }
        switch context.biometryType {
        case .faceID: return "Face ID available"
        case .touchID: return "Touch ID available"
        case .opticID: return "Optic ID available"
        case .none: return "Unavailable"
        @unknown default: return "Biometrics available"
        }
    }

    private func savePreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: DefaultsKey.preferences)
    }

    private func normalizedSubredditName(_ input: String) -> String {
        var name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.lowercased().hasPrefix("/r/") {
            name.removeFirst(3)
        } else if name.lowercased().hasPrefix("r/") {
            name.removeFirst(2)
        }
        return name
    }

    private func configureURLCache() {
        let bytes = imageCacheLimitMB * 1_024 * 1_024
        URLCache.shared.diskCapacity = bytes
        URLCache.shared.memoryCapacity = min(bytes / 4, 64 * 1_024 * 1_024)
    }

    private func enforceCacheRetentionWindow() {
        let defaults = UserDefaults.standard
        let lastPurge = defaults.object(forKey: DefaultsKey.lastCachePurge) as? Date
        if lastPurge.map({ Date().timeIntervalSince($0) >= 48 * 60 * 60 }) ?? true {
            clearMediaCache()
            defaults.set(Date(), forKey: DefaultsKey.lastCachePurge)
        }
    }

    private func restoreRedditConnection() async {
        guard oauth.hasStoredCredential else { return }
        do {
            if let account = try await oauth.restoreAccount() {
                activateLiveService(account: account)
            }
        } catch {
            redditConnectionError = error.localizedDescription
            redditConnectionState = .failed(message: error.localizedDescription)
        }
    }

    private func activateLiveService(account: AccountSummary) {
        guard let configuration = oauth.apiConfiguration else { return }
        let oauth = oauth
        service = DataAPIRedditService(
            configuration: configuration,
            account: account,
            tokenProvider: { try await oauth.validAccessToken() }
        )
        accounts = [account]
        redditConnectionState = .connected(username: account.username)
        redditConnectionError = nil
    }

    private enum DefaultsKey {
        static let preferences = "reantenna.preferences"
        static let browser = "reantenna.browser"
        static let pagination = "reantenna.pagination"
        static let cellularLimit = "reantenna.cellular-download-limit-mb"
        static let imageCacheLimit = "reantenna.image-cache-limit-mb"
        static let history = "reantenna.recently-viewed-post-ids"
        static let lastCachePurge = "reantenna.last-cache-purge"
    }
}
