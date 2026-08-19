import Foundation

public enum RedditOAuthScopePolicy {
    public static let requiredScopes = ["identity", "read", "submit", "edit", "vote", "save"]

    public static func requiresReauthorization(grantedScope: String) -> Bool {
        let grantedScopes = Set(
            grantedScope
                .split(whereSeparator: { $0.isWhitespace || $0 == "," })
                .map { $0.lowercased() }
        )
        return !Set(requiredScopes).isSubset(of: grantedScopes)
    }
}

public enum RedditServiceError: Error, Equatable, Sendable {
    case unauthorized
    case forbidden
    case rateLimited(retryAfter: TimeInterval)
    case unavailable
    case missingPost
    case unsupportedOperation
    case invalidRequest(String)
    case apiError(code: String, message: String)
}

public protocol RedditService: Sendable {
    func posts(in feed: String, sort: FeedSort) async throws -> [Post]
    func thread(id: String) async throws -> ThreadPage
    func accounts() async -> [AccountSummary]
    /// Creates a comment or reply. `parentFullName` must be a Reddit fullname,
    /// such as `t3_abc123` for a post or `t1_def456` for a comment.
    @discardableResult
    func submitComment(parentFullName: String, text: String) async throws -> String
    func editText(fullName: String, text: String) async throws
    func deleteText(fullName: String) async throws
    func vote(fullName: String, direction: VoteState) async throws
    func setSaved(fullName: String, isSaved: Bool) async throws
}

public extension RedditService {
    @discardableResult
    func submitComment(parentFullName: String, text: String) async throws -> String {
        throw RedditServiceError.unsupportedOperation
    }

    func editText(fullName: String, text: String) async throws {
        throw RedditServiceError.unsupportedOperation
    }

    func deleteText(fullName: String) async throws {
        throw RedditServiceError.unsupportedOperation
    }

    func vote(fullName: String, direction: VoteState) async throws {
        throw RedditServiceError.unsupportedOperation
    }

    func setSaved(fullName: String, isSaved: Bool) async throws {
        throw RedditServiceError.unsupportedOperation
    }
}
