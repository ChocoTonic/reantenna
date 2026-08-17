import Foundation

public enum FeedSort: String, CaseIterable, Codable, Sendable {
    case hot
    case new
    case top
    case rising
    case controversial

    public var title: String { rawValue.capitalized }
}

public enum FeedLayout: String, CaseIterable, Codable, Sendable {
    case compact
    case thumbnail
    case grid
}

public enum ThemeMode: String, CaseIterable, Codable, Sendable {
    case system
    case day
    case night
}

public enum VoteState: Int, Codable, Sendable {
    case down = -1
    case none = 0
    case up = 1
}

public enum PostKind: String, Codable, Sendable {
    case image
    case video
    case link
    case text
    case gallery

    public var systemImage: String {
        switch self {
        case .image: "photo"
        case .video: "play.rectangle.fill"
        case .link: "link"
        case .text: "text.alignleft"
        case .gallery: "square.grid.2x2"
        }
    }
}

public struct Post: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let author: String
    public let subreddit: String
    public let domain: String
    public let age: String
    public let flair: String?
    public let kind: PostKind
    public let body: String?
    public var score: Int
    public var commentCount: Int
    public var vote: VoteState
    public var isSaved: Bool
    public var isHidden: Bool
    public var isRead: Bool
    public var isNSFW: Bool

    public init(
        id: String,
        title: String,
        author: String,
        subreddit: String,
        domain: String,
        age: String,
        flair: String? = nil,
        kind: PostKind,
        body: String? = nil,
        score: Int,
        commentCount: Int,
        vote: VoteState = .none,
        isSaved: Bool = false,
        isHidden: Bool = false,
        isRead: Bool = false,
        isNSFW: Bool = false
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.subreddit = subreddit
        self.domain = domain
        self.age = age
        self.flair = flair
        self.kind = kind
        self.body = body
        self.score = score
        self.commentCount = commentCount
        self.vote = vote
        self.isSaved = isSaved
        self.isHidden = isHidden
        self.isRead = isRead
        self.isNSFW = isNSFW
    }
}

public struct Comment: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let author: String
    public let body: String
    public let age: String
    public var score: Int
    public var vote: VoteState
    public let isOriginalPoster: Bool
    public var children: [Comment]

    public init(
        id: String,
        author: String,
        body: String,
        age: String,
        score: Int,
        vote: VoteState = .none,
        isOriginalPoster: Bool = false,
        children: [Comment] = []
    ) {
        self.id = id
        self.author = author
        self.body = body
        self.age = age
        self.score = score
        self.vote = vote
        self.isOriginalPoster = isOriginalPoster
        self.children = children
    }
}

public struct ThreadPage: Hashable, Codable, Sendable {
    public let post: Post
    public let comments: [Comment]

    public init(post: Post, comments: [Comment]) {
        self.post = post
        self.comments = comments
    }
}

public struct AccountSummary: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let username: String
    public let karma: Int

    public init(id: String, username: String, karma: Int) {
        self.id = id
        self.username = username
        self.karma = karma
    }
}

public struct AppPreferences: Hashable, Codable, Sendable {
    public var theme: ThemeMode = .system
    public var layout: FeedLayout = .compact
    public var previewLinks = true
    public var limitCellularDownloads = true
    public var keepHistory = true
    public var quickTapCollapsesComments = true
    public var collapseChildCommentsByDefault = false
    public var showNextPost = true
    public var textScale = 1.0

    public init() {}
}
