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

    let service: any RedditService

    init(service: any RedditService) {
        self.service = service
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
    }

    var preferredColorScheme: ColorScheme? {
        switch preferences.theme {
        case .system: nil
        case .day: .light
        case .night: .dark
        }
    }

    func start() async {
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

    private func configureURLCache() {
        let bytes = imageCacheLimitMB * 1_024 * 1_024
        URLCache.shared.diskCapacity = bytes
        URLCache.shared.memoryCapacity = min(bytes / 4, 64 * 1_024 * 1_024)
    }

    private enum DefaultsKey {
        static let preferences = "threadline.preferences"
        static let browser = "threadline.browser"
        static let pagination = "threadline.pagination"
        static let cellularLimit = "threadline.cellular-download-limit-mb"
        static let imageCacheLimit = "threadline.image-cache-limit-mb"
        static let history = "threadline.recently-viewed-post-ids"
    }
}
