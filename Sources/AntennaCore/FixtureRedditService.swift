import Foundation

public actor FixtureRedditService: RedditService {
    private var storedPosts: [Post]
    private var storedCommentsByPost: [String: [Comment]]
    private var nextCommentID = 1

    public init() {
        storedPosts = Self.fixturePosts
        storedCommentsByPost = ["p008": Self.fixtureComments]
    }

    public func posts(in feed: String, sort: FeedSort) async throws -> [Post] {
        storedPosts
            .filter { !$0.isHidden }
            .sorted { lhs, rhs in
                switch sort {
                case .new: lhs.id > rhs.id
                case .top: lhs.score > rhs.score
                case .controversial: abs(lhs.score) < abs(rhs.score)
                case .hot, .rising: lhs.commentCount > rhs.commentCount
                }
            }
    }

    public func thread(id: String) async throws -> ThreadPage {
        guard let post = storedPosts.first(where: { $0.id == id }) else {
            throw RedditServiceError.missingPost
        }
        return ThreadPage(post: post, comments: storedCommentsByPost[id, default: []])
    }

    public func accounts() async -> [AccountSummary] {
        [AccountSummary(id: "local", username: "local_reader", karma: 12_480)]
    }

    @discardableResult
    public func submitComment(parentFullName: String, text: String) async throws -> String {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            throw RedditServiceError.invalidRequest("Comment text cannot be empty.")
        }
        let id = "fixture-write-\(nextCommentID)"
        nextCommentID += 1
        let comment = Comment(
            id: id,
            author: "local_reader",
            body: body,
            age: "now",
            score: 1,
            vote: .up
        )

        if parentFullName.hasPrefix("t3_") {
            let postID = String(parentFullName.dropFirst(3))
            guard storedPosts.contains(where: { $0.id == postID }) else {
                throw RedditServiceError.invalidRequest("The parent post was not found.")
            }
            storedCommentsByPost[postID, default: []].insert(comment, at: 0)
        } else if parentFullName.hasPrefix("t1_") {
            let parentID = String(parentFullName.dropFirst(3))
            guard mutateComments(containing: parentID, { comments in
                Self.append(comment, toParent: parentID, in: &comments)
            }) else {
                throw RedditServiceError.invalidRequest("The parent comment was not found.")
            }
        } else {
            throw RedditServiceError.invalidRequest("A post or comment fullname is required.")
        }
        return "t1_\(id)"
    }

    public func editText(fullName: String, text: String) async throws {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            throw RedditServiceError.invalidRequest("Comment text cannot be empty.")
        }
        if fullName.hasPrefix("t1_") {
            let id = String(fullName.dropFirst(3))
            guard mutateComments(containing: id, { comments in
                Self.editComment(id: id, body: body, in: &comments)
            }) else {
                throw RedditServiceError.forbidden
            }
        } else if fullName.hasPrefix("t3_"),
                  let index = storedPosts.firstIndex(where: { $0.id == String(fullName.dropFirst(3)) && $0.author == "local_reader" })
        {
            storedPosts[index].body = body
        } else {
            throw RedditServiceError.forbidden
        }
    }

    public func deleteText(fullName: String) async throws {
        if fullName.hasPrefix("t1_") {
            let id = String(fullName.dropFirst(3))
            guard mutateComments(containing: id, { comments in
                Self.deleteComment(id: id, in: &comments)
            }) else {
                throw RedditServiceError.forbidden
            }
        } else if fullName.hasPrefix("t3_"),
                  let index = storedPosts.firstIndex(where: { $0.id == String(fullName.dropFirst(3)) && $0.author == "local_reader" })
        {
            storedPosts.remove(at: index)
        } else {
            throw RedditServiceError.forbidden
        }
    }

    public func vote(fullName: String, direction: VoteState) async throws {
        if fullName.hasPrefix("t3_"),
           let index = storedPosts.firstIndex(where: { $0.id == String(fullName.dropFirst(3)) })
        {
            let previous = storedPosts[index].vote
            storedPosts[index].vote = direction
            storedPosts[index].score += direction.rawValue - previous.rawValue
        } else if fullName.hasPrefix("t1_") {
            let id = String(fullName.dropFirst(3))
            guard mutateComments(containing: id, { comments in
                Self.voteComment(id: id, direction: direction, in: &comments)
            }) else {
                throw RedditServiceError.invalidRequest("The comment was not found.")
            }
        } else {
            throw RedditServiceError.invalidRequest("The post or comment was not found.")
        }
    }

    public func setSaved(fullName: String, isSaved: Bool) async throws {
        guard fullName.hasPrefix("t3_"),
              let index = storedPosts.firstIndex(where: { $0.id == String(fullName.dropFirst(3)) })
        else {
            throw RedditServiceError.invalidRequest("The post was not found.")
        }
        storedPosts[index].isSaved = isSaved
    }

    /// Applies a mutation only to the discussion that owns `commentID`.
    private func mutateComments(
        containing commentID: String,
        _ mutation: (inout [Comment]) -> Bool
    ) -> Bool {
        for postID in Array(storedCommentsByPost.keys) {
            var comments = storedCommentsByPost[postID, default: []]
            guard Self.containsComment(id: commentID, in: comments) else { continue }
            guard mutation(&comments) else { return false }
            storedCommentsByPost[postID] = comments
            return true
        }
        return false
    }

    private static func containsComment(id: String, in comments: [Comment]) -> Bool {
        comments.contains { comment in
            comment.id == id || containsComment(id: id, in: comment.children)
        }
    }

    private static func append(_ comment: Comment, toParent id: String, in comments: inout [Comment]) -> Bool {
        for index in comments.indices {
            if comments[index].id == id {
                comments[index].children.append(comment)
                return true
            }
            if append(comment, toParent: id, in: &comments[index].children) { return true }
        }
        return false
    }

    private static func editComment(id: String, body: String, in comments: inout [Comment]) -> Bool {
        for index in comments.indices {
            if comments[index].id == id, comments[index].author == "local_reader" {
                comments[index].body = body
                return true
            }
            if editComment(id: id, body: body, in: &comments[index].children) { return true }
        }
        return false
    }

    private static func deleteComment(id: String, in comments: inout [Comment]) -> Bool {
        if let index = comments.firstIndex(where: { $0.id == id && $0.author == "local_reader" }) {
            comments.remove(at: index)
            return true
        }
        for index in comments.indices {
            if deleteComment(id: id, in: &comments[index].children) { return true }
        }
        return false
    }

    private static func voteComment(id: String, direction: VoteState, in comments: inout [Comment]) -> Bool {
        for index in comments.indices {
            if comments[index].id == id {
                let previous = comments[index].vote
                comments[index].vote = direction
                comments[index].score += direction.rawValue - previous.rawValue
                return true
            }
            if voteComment(id: id, direction: direction, in: &comments[index].children) { return true }
        }
        return false
    }

    public static let fixturePosts: [Post] = [
        Post(
            id: "p008",
            title: "The night sky over the desert, stitched from 24 exposures",
            author: "quiet_shutter",
            subreddit: "space",
            domain: "i.redd.it",
            age: "18 min",
            flair: "Photo",
            kind: .image,
            score: 12_842,
            commentCount: 417
        ),
        Post(
            id: "p007",
            title: "A tiny interaction detail that makes old apps feel instant",
            author: "native_first",
            subreddit: "iosprogramming",
            domain: "self.iosprogramming",
            age: "42 min",
            flair: "Discussion",
            kind: .text,
            body: "The interface responds before the network does. Preserve position, acknowledge the gesture, and let loading happen afterward.",
            score: 638,
            commentCount: 92
        ),
        Post(
            id: "p006",
            title: "Restoring a 1970s receiver and hearing it come alive",
            author: "signal_path",
            subreddit: "vintageaudio",
            domain: "youtube.com",
            age: "1 hr",
            kind: .video,
            score: 2_194,
            commentCount: 128,
            isRead: true
        ),
        Post(
            id: "p005",
            title: "Why dense information layouts still deserve a place on mobile",
            author: "smalltype",
            subreddit: "design",
            domain: "example.com",
            age: "2 hr",
            flair: "Article",
            kind: .link,
            score: 4_011,
            commentCount: 306
        ),
        Post(
            id: "p004",
            title: "Built a walnut stand for my favorite pocket computer",
            author: "grain_match",
            subreddit: "woodworking",
            domain: "imgur.com",
            age: "3 hr",
            kind: .gallery,
            score: 8_322,
            commentCount: 214
        ),
        Post(
            id: "p003",
            title: "What is the oldest app you still wish you could use?",
            author: "archive_mode",
            subreddit: "iphone",
            domain: "self.iphone",
            age: "4 hr",
            flair: "Question",
            kind: .text,
            body: "Mine was a fast Reddit client with a strange but perfect swipe menu.",
            score: 1_506,
            commentCount: 389
        ),
        Post(
            id: "p002",
            title: "A field guide to recognizing birds by silhouette",
            author: "ridgewalker",
            subreddit: "birding",
            domain: "fieldnotes.example",
            age: "5 hr",
            kind: .link,
            score: 932,
            commentCount: 67,
            isSaved: true
        ),
        Post(
            id: "p001",
            title: "This week in beautifully unnecessary mechanical keyboards",
            author: "click_spring",
            subreddit: "mechanicalkeyboards",
            domain: "i.redd.it",
            age: "6 hr",
            kind: .image,
            score: 6_781,
            commentCount: 244
        ),
    ]

    public static let fixtureComments: [Comment] = [
        Comment(
            id: "c1",
            author: "aperture_priority",
            body: "The restraint in the processing is what makes this work. The sky still looks like a sky rather than a texture map.",
            age: "14 min",
            score: 1_284,
            children: [
                Comment(
                    id: "c1-1",
                    author: "quiet_shutter",
                    body: "Thank you. I pulled the saturation back twice before exporting it.",
                    age: "11 min",
                    score: 509,
                    isOriginalPoster: true,
                    children: [
                        Comment(
                            id: "c1-1-1",
                            author: "grain_is_good",
                            body: "That was the right call. It also reads beautifully on a small screen.",
                            age: "7 min",
                            score: 118
                        ),
                    ]
                ),
                Comment(
                    id: "c1-2",
                    author: "dark_adapter",
                    body: "Do you remember the lens and exposure time?",
                    age: "9 min",
                    score: 84
                ),
            ]
        ),
        Comment(
            id: "c2",
            author: "old_app_energy",
            body: "This is exactly the kind of post where a compact client shines: image first, discussion immediately below, no transition into another screen.",
            age: "20 min",
            score: 746,
            children: [
                Comment(
                    id: "c2-1",
                    author: "table_view",
                    body: "And it should remember this exact scroll position when you swipe back.",
                    age: "16 min",
                    score: 301
                ),
            ]
        ),
        Comment(
            id: "c3",
            author: "desert_signal",
            body: "The faint green near the horizon is airglow, not an editing artifact.",
            age: "31 min",
            score: 392
        ),
    ]
}
