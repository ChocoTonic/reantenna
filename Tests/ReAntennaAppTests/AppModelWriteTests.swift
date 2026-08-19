import XCTest
import AntennaCore
@testable import ReAntenna

final class AppModelWriteTests: XCTestCase {
    @MainActor
    func testDuplicatePendingVoteDoesNotReachService() async {
        let service = BlockingVoteService()
        let model = AppModel(service: service)

        let firstVote = Task {
            await model.vote(fullname: "t3_post", direction: .up)
        }
        await service.waitUntilVoteStarts()

        let duplicateSucceeded = await model.vote(fullname: "t3_post", direction: .up)
        let callsBeforeRelease = await service.voteCallCount
        await service.releaseVote()
        let firstSucceeded = await firstVote.value

        XCTAssertFalse(duplicateSucceeded)
        XCTAssertEqual(callsBeforeRelease, 1)
        XCTAssertTrue(firstSucceeded)
    }
}

private actor BlockingVoteService: RedditService {
    private(set) var voteCallCount = 0
    private var voteStartedWaiters: [CheckedContinuation<Void, Never>] = []
    private var voteRelease: CheckedContinuation<Void, Never>?

    func posts(in feed: String, sort: FeedSort) async throws -> [Post] { [] }

    func thread(id: String) async throws -> ThreadPage {
        throw RedditServiceError.missingPost
    }

    func accounts() async -> [AccountSummary] { [] }

    func vote(fullName: String, direction: VoteState) async throws {
        voteCallCount += 1
        let waiters = voteStartedWaiters
        voteStartedWaiters.removeAll()
        for waiter in waiters { waiter.resume() }
        await withCheckedContinuation { continuation in
            voteRelease = continuation
        }
    }

    func waitUntilVoteStarts() async {
        guard voteCallCount == 0 else { return }
        await withCheckedContinuation { continuation in
            voteStartedWaiters.append(continuation)
        }
    }

    func releaseVote() {
        voteRelease?.resume()
        voteRelease = nil
    }
}
