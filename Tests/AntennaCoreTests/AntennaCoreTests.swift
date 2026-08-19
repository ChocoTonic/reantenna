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

    func testFixtureCommentWriteLifecycleMutatesThread() async throws {
        let service = FixtureRedditService()
        let fullName = try await service.submitComment(parentFullName: "t3_p008", text: "First draft")
        try await service.editText(fullName: fullName, text: "Edited draft")

        var page = try await service.thread(id: "p008")
        XCTAssertEqual(page.comments.first?.body, "Edited draft")
        XCTAssertEqual(page.comments.first?.author, "local_reader")

        try await service.deleteText(fullName: fullName)
        page = try await service.thread(id: "p008")
        XCTAssertFalse(page.comments.contains { "t1_\($0.id)" == fullName })
    }

    func testFixtureRepliesRemainIsolatedToTheirDiscussion() async throws {
        let service = FixtureRedditService()
        let originalOtherDiscussion = try await service.thread(id: "p008").comments

        let rootFullName = try await service.submitComment(
            parentFullName: "t3_p007",
            text: "Only in the iOS discussion"
        )
        let replyFullName = try await service.submitComment(
            parentFullName: rootFullName,
            text: "A reply in the same discussion"
        )

        let targetDiscussion = try await service.thread(id: "p007")
        let untouchedDiscussion = try await service.thread(id: "p008")
        let targetFullNames = Set(Self.flatten(targetDiscussion.comments).map { "t1_\($0.id)" })
        let untouchedFullNames = Set(Self.flatten(untouchedDiscussion.comments).map { "t1_\($0.id)" })

        XCTAssertTrue(targetFullNames.contains(rootFullName))
        XCTAssertTrue(targetFullNames.contains(replyFullName))
        XCTAssertFalse(untouchedFullNames.contains(rootFullName))
        XCTAssertFalse(untouchedFullNames.contains(replyFullName))
        XCTAssertEqual(untouchedDiscussion.comments, originalOtherDiscussion)
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

    func testReadOnlyCredentialRequiresReauthorizationAfterWriteScopesAdded() {
        XCTAssertTrue(
            RedditOAuthScopePolicy.requiresReauthorization(grantedScope: "identity read")
        )
        XCTAssertFalse(
            RedditOAuthScopePolicy.requiresReauthorization(
                grantedScope: "identity read submit edit vote save"
            )
        )
    }

    func testSubmitCommentUsesAuthenticatedFormRequestAndReturnsFullName() async throws {
        let recorder = RequestRecorder()
        let service = makeDataAPIService(recorder: recorder) { request in
            Self.response(
                for: request,
                body: #"{"json":{"errors":[],"data":{"things":[{"data":{"name":"t1_newreply"}}]}}}"#
            )
        }

        let fullName = try await service.submitComment(
            parentFullName: "t3_parent",
            text: "A reply with & punctuation"
        )

        XCTAssertEqual(fullName, "t1_newreply")
        let request = try XCTUnwrap(recorder.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://oauth.reddit.com/api/comment")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), Self.userAgent)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded; charset=UTF-8"
        )
        let form = try XCTUnwrap(request.httpBody.flatMap { String(data: $0, encoding: .utf8) })
        XCTAssertTrue(form.contains("thing_id=t3_parent"))
        XCTAssertTrue(form.contains("text=A%20reply%20with%20%26%20punctuation"))
    }

    func testEditSurfacesRedditJSONError() async throws {
        let service = makeDataAPIService { request in
            Self.response(
                for: request,
                body: #"{"json":{"errors":[["TOO_LONG","this is too long","text"]],"data":null}}"#
            )
        }

        do {
            try await service.editText(fullName: "t1_owned", text: "replacement")
            XCTFail("Expected Reddit's API error")
        } catch let error as RedditServiceError {
            XCTAssertEqual(error, .apiError(code: "TOO_LONG", message: "this is too long"))
        }
    }

    func testVoteAndSaveUseExpectedEndpointsAndValues() async throws {
        let recorder = RequestRecorder()
        let service = makeDataAPIService(recorder: recorder) { request in
            Self.response(for: request, body: "{}")
        }

        try await service.vote(fullName: "t3_post", direction: .down)
        try await service.setSaved(fullName: "t3_post", isSaved: true)
        try await service.setSaved(fullName: "t3_post", isSaved: false)

        XCTAssertEqual(recorder.requests.map { $0.url?.path }, ["/api/vote", "/api/save", "/api/unsave"])
        let voteBody = try XCTUnwrap(recorder.requests.first?.httpBody)
        XCTAssertTrue(String(decoding: voteBody, as: UTF8.self).contains("dir=-1"))
    }

    func testWriteOperationsRejectInvalidFullNamesBeforeNetworkAccess() async throws {
        let recorder = RequestRecorder()
        let service = makeDataAPIService(recorder: recorder) { request in
            Self.response(for: request, body: "{}")
        }

        do {
            try await service.deleteText(fullName: "plain-id")
            XCTFail("Expected input validation")
        } catch let error as RedditServiceError {
            XCTAssertEqual(error, .invalidRequest("A post or comment fullname is required."))
        }
        XCTAssertTrue(recorder.requests.isEmpty)
    }

    func testRateLimitedWriteBlocksFollowingRequestUntilReset() async throws {
        let recorder = RequestRecorder()
        let service = makeDataAPIService(recorder: recorder) { request in
            Self.response(for: request, status: 429, body: "{}")
        }

        for _ in 0..<2 {
            do {
                try await service.vote(fullName: "t3_post", direction: .up)
                XCTFail("Expected rate limiting")
            } catch let RedditServiceError.rateLimited(retryAfter) {
                XCTAssertGreaterThan(retryAfter, 0)
            }
        }

        XCTAssertEqual(recorder.requests.count, 1)
    }

    func testConcurrentRequestsAtomicallyEnforceClientCeiling() async {
        let recorder = RequestRecorder()
        let service = makeDataAPIService(
            recorder: recorder,
            tokenProvider: {
                try await Task.sleep(nanoseconds: 50_000_000)
                return "test-token"
            }
        ) { request in
            Self.response(for: request, body: "{}")
        }

        let outcomes = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for index in 0..<61 {
                group.addTask {
                    do {
                        try await service.vote(fullName: "t3_post\(index)", direction: .up)
                        return 0
                    } catch RedditServiceError.rateLimited {
                        return 1
                    } catch {
                        return 2
                    }
                }
            }

            var values: [Int] = []
            for await value in group { values.append(value) }
            return values
        }

        XCTAssertEqual(outcomes.filter { $0 == 0 }.count, 60)
        XCTAssertEqual(outcomes.filter { $0 == 1 }.count, 1)
        XCTAssertEqual(outcomes.filter { $0 == 2 }.count, 0)
        XCTAssertEqual(recorder.requests.count, 60)
    }

    func testForbiddenWriteIsNotReportedAsExpiredAuthorization() async throws {
        let service = makeDataAPIService { request in
            Self.response(for: request, status: 403, body: "{}")
        }

        do {
            try await service.vote(fullName: "t3_locked", direction: .up)
            XCTFail("Expected a forbidden response")
        } catch let error as RedditServiceError {
            XCTAssertEqual(error, .forbidden)
        }
    }

    private static let userAgent = "ios:com.chocotonic.reantenna:v0.1 (by /u/giddiness-uneasy)"

    private static func flatten(_ comments: [Comment]) -> [Comment] {
        comments.flatMap { [$0] + flatten($0.children) }
    }

    private func makeDataAPIService(
        recorder: RequestRecorder = RequestRecorder(),
        tokenProvider: @escaping DataAPIRedditService.AccessTokenProvider = { "test-token" },
        handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> DataAPIRedditService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.handler = { request in
            recorder.append(request)
            return try handler(request)
        }
        return DataAPIRedditService(
            configuration: RedditAPIConfiguration(
                clientID: "approved-client-id",
                redirectURI: "reantenna://oauth",
                userAgent: Self.userAgent
            ),
            account: AccountSummary(id: "me", username: "tester", karma: 1),
            session: URLSession(configuration: configuration),
            tokenProvider: tokenProvider
        )
    }

    private static func response(
        for request: URLRequest,
        status: Int = 200,
        body: String
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "application/json",
                "x-ratelimit-used": "1",
                "x-ratelimit-remaining": "59",
                "x-ratelimit-reset": "60",
            ]
        )!
        return (response, Data(body.utf8))
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [URLRequest] = []

    var requests: [URLRequest] {
        lock.withLock { storage }
    }

    func append(_ request: URLRequest) {
        var recorded = request
        if recorded.httpBody == nil, let stream = recorded.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var body = Data()
            var buffer = [UInt8](repeating: 0, count: 1_024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                body.append(buffer, count: count)
            }
            recorded.httpBody = body
        }
        lock.withLock { storage.append(recorded) }
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: RedditServiceError.unavailable)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
