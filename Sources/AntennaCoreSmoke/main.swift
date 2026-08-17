import AntennaCore

@main
struct AntennaCoreSmoke {
    static func main() async throws {
        let service = FixtureRedditService()
        let posts = try await service.posts(in: "Front", sort: .top)
        precondition(posts.count == 8)
        precondition(posts.first?.score == posts.map(\.score).max())

        let page = try await service.thread(id: "p008")
        precondition(page.comments.count == 3)

        let collapsible = CommentTraversal.collapsibleIDs(in: page.comments)
        precondition(collapsible == Set(["c1", "c1-1", "c2"]))

        let collapsed = CommentTraversal.visibleComments(
            from: page.comments,
            collapsedIDs: collapsible
        )
        precondition(collapsed.map(\.id) == ["c1", "c2", "c3"])
        precondition(collapsed.first?.hiddenChildCount == 3)

        let configuration = RedditAPIConfiguration(
            clientID: "approved-client-id",
            redirectURI: "threadline://oauth",
            userAgent: "ios:com.example.threadline:v0.1 (by /u/example)"
        )
        precondition(configuration.isUsable)

        print("AntennaCore smoke checks passed")
    }
}
