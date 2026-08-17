import Foundation
import SwiftUI
import AntennaCore

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

    let service: any RedditService

    init(service: any RedditService) {
        self.service = service
        if
            let data = UserDefaults.standard.data(forKey: "threadline.preferences"),
            let decoded = try? JSONDecoder().decode(AppPreferences.self, from: data)
        {
            preferences = decoded
        } else {
            preferences = AppPreferences()
        }
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
            posts = try await service.posts(in: selectedFeed, sort: sort)
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

    private func savePreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: "threadline.preferences")
    }
}
