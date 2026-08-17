import Foundation

public enum RedditServiceError: Error, Equatable, Sendable {
    case unauthorized
    case rateLimited(retryAfter: TimeInterval)
    case unavailable
    case missingPost
}

public protocol RedditService: Sendable {
    func posts(in feed: String, sort: FeedSort) async throws -> [Post]
    func thread(id: String) async throws -> ThreadPage
    func accounts() async -> [AccountSummary]
}
