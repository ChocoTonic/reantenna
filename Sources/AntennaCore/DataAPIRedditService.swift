import Foundation

public struct RedditAPIConfiguration: Hashable, Sendable {
    public let clientID: String
    public let redirectURI: String
    public let userAgent: String

    public init(clientID: String, redirectURI: String, userAgent: String) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.userAgent = userAgent
    }

    public var isUsable: Bool {
        !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !redirectURI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && userAgent.contains(":" )
    }
}

public struct RedditRateLimit: Hashable, Sendable {
    public let used: Double?
    public let remaining: Double?
    public let resetAfter: TimeInterval?

    public init(used: Double?, remaining: Double?, resetAfter: TimeInterval?) {
        self.used = used
        self.remaining = remaining
        self.resetAfter = resetAfter
    }
}

/// Approval-gated Reddit Data API transport. Construct this only with a newly
/// approved client ID and tokens stored by the replacement app. Never pass
/// credentials recovered from the historic Antenna backup.
public actor DataAPIRedditService: RedditService {
    public typealias AccessTokenProvider = @Sendable () async throws -> String

    private let configuration: RedditAPIConfiguration
    private let tokenProvider: AccessTokenProvider
    private let account: AccountSummary
    private let session: URLSession

    public private(set) var lastRateLimit: RedditRateLimit?

    public init(
        configuration: RedditAPIConfiguration,
        account: AccountSummary,
        session: URLSession = .shared,
        tokenProvider: @escaping AccessTokenProvider
    ) {
        self.configuration = configuration
        self.account = account
        self.session = session
        self.tokenProvider = tokenProvider
    }

    public func posts(in feed: String, sort: FeedSort) async throws -> [Post] {
        let normalizedFeed = feed.trimmingCharacters(in: .whitespacesAndNewlines)
        let path: String
        switch normalizedFeed.lowercased() {
        case "front", "home", "": path = "/\(sort.rawValue).json"
        case "all": path = "/r/all/\(sort.rawValue).json"
        case "popular": path = "/r/popular/\(sort.rawValue).json"
        default:
            let subreddit = normalizedFeed
                .replacingOccurrences(of: "/r/", with: "")
                .replacingOccurrences(of: "r/", with: "")
            path = "/r/\(subreddit)/\(sort.rawValue).json"
        }

        let listing: ListingEnvelope<PostData> = try await request(
            path: path,
            query: [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "raw_json", value: "1"),
            ]
        )
        return listing.data.children.compactMap { $0.data.post }
    }

    public func thread(id: String) async throws -> ThreadPage {
        let cleanID = id.replacingOccurrences(of: "t3_", with: "")
        let listings: [ThreadListing] = try await request(
            path: "/comments/\(cleanID).json",
            query: [
                URLQueryItem(name: "limit", value: "500"),
                URLQueryItem(name: "raw_json", value: "1"),
            ]
        )

        guard
            let postData = listings.first?.data.children.first?.data,
            let post = postData.post
        else {
            throw RedditServiceError.missingPost
        }

        let comments = listings.dropFirst().first?.data.children.compactMap { $0.data.comment } ?? []
        return ThreadPage(post: post, comments: comments)
    }

    public func accounts() async -> [AccountSummary] {
        [account]
    }

    private func request<Response: Decodable>(
        path: String,
        query: [URLQueryItem]
    ) async throws -> Response {
        guard configuration.isUsable else { throw RedditServiceError.unauthorized }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "oauth.reddit.com"
        components.path = path
        components.queryItems = query
        guard let url = components.url else { throw RedditServiceError.unavailable }

        let token = try await tokenProvider()
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RedditServiceError.unavailable
        }

        lastRateLimit = RedditRateLimit(
            used: http.value(forHTTPHeaderField: "x-ratelimit-used").flatMap(Double.init),
            remaining: http.value(forHTTPHeaderField: "x-ratelimit-remaining").flatMap(Double.init),
            resetAfter: http.value(forHTTPHeaderField: "x-ratelimit-reset").flatMap(Double.init)
        )

        switch http.statusCode {
        case 200..<300:
            return try JSONDecoder().decode(Response.self, from: data)
        case 401, 403:
            throw RedditServiceError.unauthorized
        case 429:
            throw RedditServiceError.rateLimited(retryAfter: lastRateLimit?.resetAfter ?? 60)
        default:
            throw RedditServiceError.unavailable
        }
    }
}

private struct ListingEnvelope<DataType: Decodable>: Decodable {
    let data: ListingData<DataType>
}

private struct ListingData<DataType: Decodable>: Decodable {
    let children: [Thing<DataType>]
}

private struct Thing<DataType: Decodable>: Decodable {
    let kind: String?
    let data: DataType
}

private typealias ThreadListing = ListingEnvelope<PostOrCommentData>

private struct PostOrCommentData: Decodable {
    let id: String?
    let name: String?
    let title: String?
    let author: String?
    let subreddit: String?
    let domain: String?
    let createdUTC: Double?
    let linkFlairText: String?
    let selftext: String?
    let score: Int?
    let numComments: Int?
    let likes: Bool?
    let saved: Bool?
    let hidden: Bool?
    let over18: Bool?
    let isSelf: Bool?
    let isVideo: Bool?
    let postHint: String?
    let body: String?
    let isSubmitter: Bool?
    let replies: Replies?

    enum CodingKeys: String, CodingKey {
        case id, name, title, author, subreddit, domain, score, likes, saved, hidden, body, replies
        case createdUTC = "created_utc"
        case linkFlairText = "link_flair_text"
        case selftext
        case numComments = "num_comments"
        case over18 = "over_18"
        case isSelf = "is_self"
        case isVideo = "is_video"
        case postHint = "post_hint"
        case isSubmitter = "is_submitter"
    }

    var post: Post? {
        guard let id, let title else { return nil }
        return Post(
            id: id,
            title: title,
            author: author ?? "[deleted]",
            subreddit: subreddit ?? "unknown",
            domain: domain ?? "reddit.com",
            age: relativeAge(since: createdUTC),
            flair: linkFlairText,
            kind: postKind,
            body: selftext?.isEmpty == false ? selftext : nil,
            score: score ?? 0,
            commentCount: numComments ?? 0,
            vote: voteState,
            isSaved: saved ?? false,
            isHidden: hidden ?? false,
            isNSFW: over18 ?? false
        )
    }

    var comment: Comment? {
        guard let id, let body else { return nil }
        let childComments = replies?.listing?.data.children.compactMap { $0.data.comment } ?? []
        return Comment(
            id: id,
            author: author ?? "[deleted]",
            body: body,
            age: relativeAge(since: createdUTC),
            score: score ?? 0,
            vote: voteState,
            isOriginalPoster: isSubmitter ?? false,
            children: childComments
        )
    }

    private var voteState: VoteState {
        switch likes {
        case true: .up
        case false: .down
        case nil: .none
        }
    }

    private var postKind: PostKind {
        if isSelf == true { return .text }
        if isVideo == true { return .video }
        switch postHint {
        case "image": return .image
        case "hosted:video", "rich:video": return .video
        case "link": return .link
        default: return domain?.contains("imgur") == true ? .gallery : .link
        }
    }
}

private typealias PostData = PostOrCommentData

private enum Replies: Decodable {
    case listing(ThreadListing)
    case none

    init(from decoder: Decoder) throws {
        if let listing = try? ThreadListing(from: decoder) {
            self = .listing(listing)
        } else {
            self = .none
        }
    }

    var listing: ThreadListing? {
        guard case let .listing(value) = self else { return nil }
        return value
    }
}

private func relativeAge(since timestamp: Double?) -> String {
    guard let timestamp else { return "now" }
    let seconds = max(0, Date().timeIntervalSince1970 - timestamp)
    switch seconds {
    case ..<60: return "now"
    case ..<3_600: return "\(Int(seconds / 60)) min"
    case ..<86_400: return "\(Int(seconds / 3_600)) hr"
    default: return "\(Int(seconds / 86_400)) d"
    }
}
