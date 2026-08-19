# ReAntenna

ReAntenna is an unofficial, open-source reimplementation inspired by the discontinued Antenna (formerly AMRC) Reddit client. It is not affiliated with or endorsed by the original Antenna developer.

The project is independently written and uses original assets. It recreates Antenna's gesture-first speed and information density without copying the original source code, icon, artwork, or proprietary resources. It uses deterministic fixture data until an approved Reddit OAuth client is configured.

## Implemented milestone

- Dense, thumbnail, and grid feeds
- Light, dark, and system appearance
- Read, saved, vote, score, metadata, flair, domain, and NSFW row states
- Short row swipe for vote and save actions
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
- Manual navigation to validated public subreddit feeds
- Long-press post/comment action menus
- Persistent layout, theme, link-preview, history, navigation, and text-size preferences
- Replaceable `RedditService` boundary
- Fixture service and platform-neutral core smoke checks
- Approval-gated installed-app OAuth flow with state validation, refresh, revocation,
  and Keychain token storage
- Approval-gated live Reddit service with user-initiated comment/reply, edit/delete of the user's own comments and self-text posts, vote, and save/unsave operations, plus automatic fixture fallback

## Open the project

The generated Xcode project is [ReAntenna.xcodeproj](ReAntenna.xcodeproj). `project.yml` is its source of truth.

After installing full Xcode:

```sh
cd /Users/asdf/repos/reantenna
xcodegen generate
open ReAntenna.xcodeproj
```

In Xcode:

1. Select the `ReAntenna` target.
2. Open **Signing & Capabilities**.
3. Select your Apple Account's **Personal Team**.
4. Replace `com.example.reantenna.app` with a unique bundle identifier if Xcode requests it.
5. Connect the iPhone, enable Developer Mode, choose it as the run destination, and press Run.

A free Personal Team build expires after seven days and then needs to be rebuilt/reinstalled.

## Validate the core without Xcode

```sh
swift run AntennaCoreSmoke
```

The normal `AntennaCoreTests` XCTest target is included, but Apple's standalone Command Line Tools installation does not currently contain XCTest. Run it from Xcode after the full installation is complete.

## Continuous integration and builds

GitHub Actions is configured to build and test on a pinned macOS runner. Main-branch simulator snapshots retain only the newest three artifacts, while Git tags retain the source needed to rebuild any older version. A manual workflow accepts any tag, branch, or commit SHA for historical rebuilds. If GitHub refuses to start a macOS job because of account billing or spending settings, the repository owner must resolve that account-level restriction.

See [docs/RELEASING.md](docs/RELEASING.md) for the retention policy, free Personal
Team limitation, and optional signed-build secrets.

For the current project status, owner prerequisites, Reddit approval checklist, and
the checkpoint-by-checkpoint iOS 18 SideStore setup, see
[docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md).

Running `scripts/build-sidestore-ipa.sh` leaves the canonical unsigned artifact at
`build/ReAntenna-unsigned.ipa` and also copies a versioned IPA to `~/Downloads`.
Set `MACOS_DOWNLOADS_DIR` to override that second destination.

## Reddit integration

Do not put old Antenna credentials, tokens, cookies, or client identifiers into this project. Live integration requires separately approved Reddit Data API credentials. Until then, `FixtureRedditService` is the active transport.

The [privacy policy](PRIVACY.md) describes local storage, retention, and deletion.

After approval, copy the example local configuration:

```sh
cp Config/Reddit.local.example.xcconfig Config/Reddit.local.xcconfig
open -e Config/Reddit.local.xcconfig
xcodegen generate
```

Enter only the installed-app client ID and your Reddit username. Do not add a
client secret: an installed/native app does not have one. The local file is ignored
by Git. Reddit must register the callback exactly as `reantenna://oauth`.

The intended live implementation is `DataAPIRedditService`, conforming to the same protocol. Its read methods are joined by authenticated, user-initiated methods for commenting, editing or deleting the user's own comments and self-text posts, voting, and saving or unsaving:

```swift
public protocol RedditService: Sendable {
    func posts(in feed: String, sort: FeedSort) async throws -> [Post]
    func thread(id: String) async throws -> ThreadPage
    func accounts() async -> [AccountSummary]
    func submitComment(parentFullName: String, text: String) async throws -> String
    func editText(fullName: String, text: String) async throws
    func deleteText(fullName: String) async throws
    func vote(fullName: String, direction: VoteState) async throws
    func setSaved(fullName: String, isSaved: Bool) async throws
}
```

No view knows whether its content came from fixtures, Reddit's Data API, or a future approved Reddit platform adapter.

## License

ReAntenna is available under the [MIT License](LICENSE).

## What works today

ReAntenna is currently an interaction prototype with an approval-gated OAuth and Data API foundation, but live behavior cannot be validated until Reddit approves and issues a client ID. Without that local configuration, the feed, sorting, layouts, swipe navigation, appearance preferences, thread traversal, comment collapse controls, and action feedback operate against deterministic fixtures. In particular, **Collapse Children** keeps every root comment visible while hiding all descendants.

The initial live scope is deliberately limited to reading plus manually initiated comment/reply, editing or deleting the user's own comments and self-text posts, voting, and saving or unsaving. New-post submission, private messages, moderation, reporting, hiding, subreddit subscription changes, automation, and background writes are not included. The UI must display API success or failure and must never imply that a live action succeeded merely because local state changed.

The implementation status and historical evidence are tracked in `RESEARCH.md`. Surviving
screenshots and the developer-maintained Antenna FAQ are treated as the visual and
behavioral references; the old iMazing backup supplies model and preference names only.

## Project map

```text
ReAntennaApp/               SwiftUI application and interactions
Sources/AntennaCore/       Models, traversal, service protocol, fixtures
Sources/AntennaCoreSmoke/  Framework-free executable validation
Tests/AntennaCoreTests/     XCTest coverage
project.yml                Reproducible Xcode project definition
RESEARCH.md                Historical and current feasibility research
```
