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

    private struct RequestReservation {
        let id: UUID
        let time: Date
    }

    private let configuration: RedditAPIConfiguration
    private let tokenProvider: AccessTokenProvider
    private let account: AccountSummary
    private let session: URLSession
    private var rateLimitBlockedUntil: Date?
    private var recentRequests: [RequestReservation] = []

    public private(set) var lastRateLimit: RedditRateLimit?

    public init(
        configuration: RedditAPIConfiguration,
        account: AccountSummary,
        session: URLSession? = nil,
        tokenProvider: @escaping AccessTokenProvider
    ) {
        self.configuration = configuration
        self.account = account
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.ephemeral
            sessionConfiguration.urlCache = nil
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: sessionConfiguration)
        }
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

    @discardableResult
    public func submitComment(parentFullName: String, text: String) async throws -> String {
        let parent = try validatedFullName(parentFullName)
        let body = try validatedText(text)
        let response: RedditJSONResponse = try await post(
            path: "/api/comment",
            form: [
                URLQueryItem(name: "api_type", value: "json"),
                URLQueryItem(name: "return_rtjson", value: "false"),
                URLQueryItem(name: "text", value: body),
                URLQueryItem(name: "thing_id", value: parent),
            ]
        )
        try response.throwFirstError()
        guard let fullName = response.json.data?.things?.first?.data.name, !fullName.isEmpty else {
            throw RedditServiceError.unavailable
        }
        return fullName
    }

    public func editText(fullName: String, text: String) async throws {
        let response: RedditJSONResponse = try await post(
            path: "/api/editusertext",
            form: [
                URLQueryItem(name: "api_type", value: "json"),
                URLQueryItem(name: "text", value: try validatedText(text)),
                URLQueryItem(name: "thing_id", value: try validatedFullName(fullName)),
            ]
        )
        try response.throwFirstError()
    }

    public func deleteText(fullName: String) async throws {
        try await postWithoutResponse(
            path: "/api/del",
            form: [URLQueryItem(name: "id", value: try validatedFullName(fullName))]
        )
    }

    public func vote(fullName: String, direction: VoteState) async throws {
        let dir: String
        switch direction {
        case .up: dir = "1"
        case .none: dir = "0"
        case .down: dir = "-1"
        }
        try await postWithoutResponse(
            path: "/api/vote",
            form: [
                URLQueryItem(name: "dir", value: dir),
                URLQueryItem(name: "id", value: try validatedFullName(fullName)),
            ]
        )
    }

    public func setSaved(fullName: String, isSaved: Bool) async throws {
        try await postWithoutResponse(
            path: isSaved ? "/api/save" : "/api/unsave",
            form: [URLQueryItem(name: "id", value: try validatedFullName(fullName))]
        )
    }

    private func request<Response: Decodable>(
        path: String,
        query: [URLQueryItem]
    ) async throws -> Response {
        let data = try await perform(path: path, query: query, method: "GET", body: nil)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw RedditServiceError.unavailable
        }
    }

    private func post<Response: Decodable>(
        path: String,
        form: [URLQueryItem]
    ) async throws -> Response {
        var encoder = URLComponents()
        encoder.queryItems = form
        guard let encoded = encoder.percentEncodedQuery?.data(using: .utf8) else {
            throw RedditServiceError.invalidRequest("The request could not be encoded.")
        }
        let data = try await perform(path: path, query: [], method: "POST", body: encoded)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw RedditServiceError.unavailable
        }
    }

    private func postWithoutResponse(path: String, form: [URLQueryItem]) async throws {
        var encoder = URLComponents()
        encoder.queryItems = form
        guard let encoded = encoder.percentEncodedQuery?.data(using: .utf8) else {
            throw RedditServiceError.invalidRequest("The request could not be encoded.")
        }
        _ = try await perform(path: path, query: [], method: "POST", body: encoded)
    }

    private func perform(
        path: String,
        query: [URLQueryItem],
        method: String,
        body: Data?
    ) async throws -> Data {
        guard configuration.isUsable else { throw RedditServiceError.unauthorized }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "oauth.reddit.com"
        components.path = path
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw RedditServiceError.unavailable }

        // Reserve before the first suspension. Actor methods are reentrant, so
        // checking here but appending after token acquisition would allow a
        // burst of concurrent calls to all observe the same available slot.
        let reservationID = try reserveRequestSlot()
        let token: String
        do {
            token = try await tokenProvider()
        } catch {
            cancelRequestReservation(reservationID)
            throw error
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RedditServiceError.unavailable
        }

        lastRateLimit = RedditRateLimit(
            used: http.value(forHTTPHeaderField: "x-ratelimit-used").flatMap(Double.init),
            remaining: http.value(forHTTPHeaderField: "x-ratelimit-remaining").flatMap(Double.init),
            resetAfter: http.value(forHTTPHeaderField: "x-ratelimit-reset").flatMap(Double.init)
        )
        if http.statusCode == 429 {
            rateLimitBlockedUntil = Date().addingTimeInterval(lastRateLimit?.resetAfter ?? 60)
        } else if let remaining = lastRateLimit?.remaining,
           remaining <= 0,
           let resetAfter = lastRateLimit?.resetAfter,
           resetAfter > 0
        {
            rateLimitBlockedUntil = Date().addingTimeInterval(resetAfter)
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401:
            throw RedditServiceError.unauthorized
        case 403:
            throw RedditServiceError.forbidden
        case 429:
            throw RedditServiceError.rateLimited(retryAfter: lastRateLimit?.resetAfter ?? 60)
        default:
            throw RedditServiceError.unavailable
        }
    }

    private func reserveRequestSlot() throws -> UUID {
        let now = Date()
        if let blockedUntil = rateLimitBlockedUntil {
            if blockedUntil > now {
                throw RedditServiceError.rateLimited(
                    retryAfter: max(1, blockedUntil.timeIntervalSince(now))
                )
            }
            rateLimitBlockedUntil = nil
        }

        recentRequests.removeAll { now.timeIntervalSince($0.time) >= 60 }
        if recentRequests.count >= 60, let oldest = recentRequests.first {
            throw RedditServiceError.rateLimited(
                retryAfter: max(1, 60 - now.timeIntervalSince(oldest.time))
            )
        }

        let id = UUID()
        recentRequests.append(RequestReservation(id: id, time: now))
        return id
    }

    private func cancelRequestReservation(_ id: UUID) {
        recentRequests.removeAll { $0.id == id }
    }

    private func validatedFullName(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: #"^t[13]_[A-Za-z0-9]+$"#, options: .regularExpression) != nil else {
            throw RedditServiceError.invalidRequest("A post or comment fullname is required.")
        }
        return trimmed
    }

    private func validatedText(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RedditServiceError.invalidRequest("Comment text cannot be empty.")
        }
        return trimmed
    }
}

private struct RedditJSONResponse: Decodable {
    let json: JSONBody

    struct JSONBody: Decodable {
        let errors: [[JSONValue]]
        let data: ResponseData?
    }

    struct ResponseData: Decodable {
        let things: [ResponseThing]?
    }

    struct ResponseThing: Decodable {
        let data: ThingData
    }

    struct ThingData: Decodable {
        let name: String?
    }

    func throwFirstError() throws {
        guard let error = json.errors.first else { return }
        let code = error.first?.stringValue ?? "UNKNOWN"
        let message = error.dropFirst().first?.stringValue ?? "Reddit rejected the request."
        throw RedditServiceError.apiError(code: code, message: message)
    }
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(Bool.self) { self = .boolean(value) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value") }
    }

    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
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
