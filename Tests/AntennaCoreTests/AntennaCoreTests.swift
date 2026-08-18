import XCTest
@testable import AntennaCore

final class AntennaCoreTests: XCTestCase {
    func testFixtureServiceSortsTopPostsByScore() async throws {
        let service = FixtureRedditService()
        let posts = try await service.posts(in: "Front", sort: .top)

        XCTAssertEqual(posts.count, 8)
        XCTAssertEqual(posts.first?.score, posts.map(\.score).max())
    }

    func testFixtureServiceReturnsAThread() async throws {
        let service = FixtureRedditService()
        let page = try await service.thread(id: "p008")

        XCTAssertEqual(page.post.id, "p008")
        XCTAssertEqual(page.comments.count, 3)
    }

    func testCollapsingACommentHidesAllDescendants() {
        let comments = FixtureRedditService.fixtureComments
        let visible = CommentTraversal.visibleComments(from: comments, collapsedIDs: ["c1"])
        let collapsed = visible.first { $0.id == "c1" }

        XCTAssertTrue(visible.map(\.id).contains("c1"))
        XCTAssertFalse(visible.map(\.id).contains("c1-1"))
        XCTAssertEqual(collapsed?.hiddenChildCount, 3)
    }

    func testTraversalReportsRootIDsInOrder() {
        XCTAssertEqual(
            CommentTraversal.rootIDs(in: FixtureRedditService.fixtureComments),
            ["c1", "c2", "c3"]
        )
    }

    func testTraversalFindsEveryCollapsibleBranch() {
        let ids = CommentTraversal.collapsibleIDs(in: FixtureRedditService.fixtureComments)

        XCTAssertEqual(ids, Set(["c1", "c1-1", "c2"]))
    }

    func testRedditConfigurationRequiresEveryOAuthField() {
        let configuration = RedditAPIConfiguration(
            clientID: "",
            redirectURI: "reantenna://oauth",
            userAgent: "ios:com.chocotonic.reantenna:v0.1 (by /u/example)"
        )

        XCTAssertFalse(configuration.isUsable)
    }

    func testApprovedRedditConfigurationIsUsable() {
        let configuration = RedditAPIConfiguration(
            clientID: "approved-client-id",
            redirectURI: "reantenna://oauth",
            userAgent: "ios:com.chocotonic.reantenna:v0.1 (by /u/example)"
        )

        XCTAssertTrue(configuration.isUsable)
    }
}
