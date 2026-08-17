# Threadline

Threadline is an independently written, gesture-first iPhone/iPad discussion client inspired by the speed and information density of Antenna/AMRC. It currently runs entirely against deterministic fixture data, so the complete interaction layer can be developed without using unapproved Reddit access.

## Implemented milestone

- Dense, thumbnail, and grid feeds
- Light, dark, and system appearance
- Read, saved, vote, score, metadata, flair, domain, and NSFW row states
- Short row swipe for vote/save/hide actions
- Long swipe from anywhere to open the right-side menu
- Swipe right from anywhere to navigate back
- Right-side shortcuts/general/accounts/user menu modeled from surviving Antenna screenshots
- Unified post/media/comments screen
- Nested comments with colored depth guides and OP identification
- Tap-to-collapse individual comment branches
- One-tap **collapse all child comments**, preserving root comments
- One-tap expand all and per-branch reopening
- Optional collapse-all-child-comments default for every newly opened thread
- Previous/next root-comment navigation
- Optional next-post control
- Long-press post/comment action menus
- Persistent layout, theme, link-preview, history, navigation, and text-size preferences
- Replaceable `RedditService` boundary
- Fixture service and platform-neutral core smoke checks

## Open the project

The generated Xcode project is [Threadline.xcodeproj](Threadline.xcodeproj). `project.yml` is its source of truth.

After installing full Xcode:

```sh
cd /Users/asdf/repos/General/AntennaRebuild
xcodegen generate
open Threadline.xcodeproj
```

In Xcode:

1. Select the `Threadline` target.
2. Open **Signing & Capabilities**.
3. Select your Apple Account's **Personal Team**.
4. Replace `com.example.threadline.app` with a unique bundle identifier if Xcode requests it.
5. Connect the iPhone, enable Developer Mode, choose it as the run destination, and press Run.

A free Personal Team build expires after seven days and then needs to be rebuilt/reinstalled.

## Validate the core without Xcode

```sh
swift run AntennaCoreSmoke
```

The normal `AntennaCoreTests` XCTest target is included, but Apple's standalone Command Line Tools installation does not currently contain XCTest. Run it from Xcode after the full installation is complete.

## Continuous integration and builds

GitHub Actions builds and tests the app on a pinned macOS runner. Main-branch
simulator snapshots retain only the newest three artifacts, while Git tags retain
the source needed to rebuild any older version. A manual workflow accepts any tag,
branch, or commit SHA for historical rebuilds.

See [docs/RELEASING.md](docs/RELEASING.md) for the retention policy, free Personal
Team limitation, and optional signed-build secrets.

## Reddit integration

Do not put old Antenna credentials, tokens, cookies, or client identifiers into this project. Live integration requires separately approved Reddit Data API credentials. Until then, `FixtureRedditService` is the active transport.

The intended live implementation is `DataAPIRedditService`, conforming to the same protocol:

```swift
public protocol RedditService: Sendable {
    func posts(in feed: String, sort: FeedSort) async throws -> [Post]
    func thread(id: String) async throws -> ThreadPage
    func accounts() async -> [AccountSummary]
}
```

No view knows whether its content came from fixtures, Reddit's Data API, or a future approved Reddit platform adapter.

## What works today

Threadline is currently an interaction prototype, not yet a live Reddit client. The feed,
sorting, layouts, swipe navigation, appearance preferences, thread traversal, and comment
collapse controls operate against deterministic fixtures. In particular, **Collapse
Children** keeps every root comment visible while hiding all of its descendants, matching
the Antenna workflow this reconstruction is intended to preserve.

Actions that require an authenticated Reddit account—voting, replying, saving remotely,
inbox, profile, and submission—must remain unavailable until a separately registered and
approved OAuth client is connected. The UI should never imply that one of those actions
succeeded merely because fixture state changed.

The implementation status and historical evidence are tracked in `RESEARCH.md`. Surviving
screenshots and the developer-maintained Antenna FAQ are treated as the visual and
behavioral references; the old iMazing backup supplies model and preference names only.

## Project map

```text
AntennaApp/                 SwiftUI application and interactions
Sources/AntennaCore/       Models, traversal, service protocol, fixtures
Sources/AntennaCoreSmoke/  Framework-free executable validation
Tests/AntennaCoreTests/     XCTest coverage
project.yml                Reproducible Xcode project definition
RESEARCH.md                Historical and current feasibility research
```
