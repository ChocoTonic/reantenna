# Antenna-style Reddit client: reconstruction research

Research date: 2026-08-09

## Outcome

An independently written, Antenna-inspired iPhone/iPad client is technically feasible and can be installed on a personal iPhone for free through Xcode. The two hard constraints are:

1. A free Apple Personal Team provisioning profile expires after seven days, requiring rebuild/reinstallation.
2. A live Reddit client requires Reddit approval and registered OAuth access. The interface should therefore be completed against fixtures before depending on API approval.

The product should use original branding, source, icons, and artwork. Antenna's workflows and interaction concepts can be reproduced, but its name, binary, and assets should not be redistributed.

## Evidence recovered locally

`../Antenna.imazingapp` is a complete iMazing app-data backup for Antenna 9.6 (build 25), bundle ID `com.amleszk.amrc`. It does **not** contain the Mach-O executable, storyboards, interface resources, or image assets, so it cannot be decompiled.

The backup does contain a FlatCache object store. Its model names provide a useful functional map:

- Posts and previews: `RCPost`, `RCPostPreview`, `RCPostURLPreview`
- Comments: `RCComment`, `RCCommentText`, `RCMoreComments`, `RCCommentsLoading`
- Pagination/loading: `RCLoading`, `RCPageDivider`, `RCLastPage`, `RCNextPage`
- Navigation: `RCRecent`, `RCSavedSession`, `RCShortcut`, `RCShortcutSelect`
- Accounts/social: `RCFriend`, `RCMessage`, `RCNotifiedMessage`
- Communities: `RCSubreddit`, `RCMulti`
- Filtering/settings: `RCPostFilter`, `RCUserDefaultsEntry`
- Media: `RCImgurAPIImageModel`

Recovered setting names confirm support for:

- Browser selection and embedded WebKit playback
- Comment limits and collapse threshold
- Image cache size and cellular-download limiting
- Message and moderator-mail notifications
- Touch ID/passcode protection
- Markdown toolbar
- Next-post navigation
- Night mode
- Compact/thumbnail post-cell types
- Link previews
- Recently viewed history
- Configurable shortcuts and Force Touch behavior

Security note: the backup contains usernames, cookies, Pocket login material, Reddit bearer tokens, and Reddit refresh tokens. Never commit it or publish it. No credential values should be reused in the replacement app.

## Historical product identity

- Original name: AMRC
- Later name: Antenna client for reddit
- Developer: Alistair Leszkiewicz
- App Store ID: `572391252`
- First release: 2012-12-22
- Last recorded release: 9.20, 2020-07-26
- Positioning: "The fastest reddit client"
- Defining promise: "swipe from anywhere" navigation

Contemporary reviews consistently describe it as unusually fast, dense, minimal, predictable, and old-school rather than visually decorative.

## Reconstructed information architecture

The right-side swipe menu shown in surviving iPhone X screenshots contains:

### Shortcuts

- Add new
- Edit
- User-defined subreddit/search/user/sort shortcuts

### General

- Search
- Messages
- Saved
- Overview
- `/r` Subreddit
- `/u` User
- Night mode
- Home
- Settings
- Back / last dismissed screen

### Accounts and user

- Active-account selector
- Profile
- Login/logout

Likely supporting screens, confirmed by listings, screenshots, release notes, or cache models:

- Front/Home, Popular/All, subreddit, multireddit, user, search-result feeds
- Dense list, thumbnail list, image/grid mode
- Unified post-content and comment view
- Image, GIF/video, YouTube, Imgur album, external link, and reader views
- Inbox, comment replies, private messages, and moderator mail
- User post/comment history
- Saved, hidden, and recently viewed posts
- Submit/edit post and comment, including Markdown toolbar and image upload
- Filters, shortcuts, accounts, data usage, privacy, appearance, link handling, comments, and notifications settings
- Moderator queue and post/comment moderation actions

## Gesture and interaction model

Gesture behavior depends on context. Avoid implementing one global horizontal gesture that steals all scrolling.

| Context | Interaction | Reconstructed behavior |
|---|---|---|
| Most screens | Swipe right from anywhere | Pop/back to the preceding view while retaining scroll position |
| Most screens | Opposite horizontal swipe | Reveal the right-side menu or contextual options |
| Feed row | Swipe left | Reveal contextual actions |
| Post/comment | Long press | Show the complete, consistent action menu |
| Comment tree | Tap/quick press | Configurable: collapse thread, show actions, or do nothing |
| Comment tree | Swipe/collapse action | Collapse current branch and advance toward the next root comment |
| Header | Tap | Toggle day/night mode in later Pro versions |
| Status bar | Tap | Normally scroll to top; later version added a resume-scroll affordance |
| Link preview | Double tap | Open in selected browser |
| GIF/video | Horizontal pan | Scrub media without triggering navigation |
| 3D Touch devices | Force press | Preview posts, subreddits, comments, albums, and images |

Gesture arbitration is a defining engineering requirement: vertical scrolling, media scrubbing, image paging, interactive-pop behavior, and menu reveal must not conflict.

## Visual reconstruction

The surviving screenshots establish the following visual rules:

- Extremely compact rows with thin separators and almost no card chrome
- Small thumbnail at leading edge; title and metadata packed beside it
- Vote score, comment count, age, author, domain, flair, and subreddit visible with restrained color coding
- A very thin top bar showing current feed title, layout toggle, and sort control
- Light mode uses white/very light gray backgrounds; night mode uses near-black with gray separators
- Link color changes after visiting; duplicates/read state are visually subdued
- Comments appear directly below the post/media rather than on a separately loaded page
- Post toolbar uses large, sparse icons: vote down/up, comments/reply, share, overflow
- iPad uses the available width rather than imposing modern card margins

Visual references:

- [iPad dense night feed](https://thesweetsetup.com/wp-content/uploads/2016/03/antenna-ipad-01.jpg)
- [iPad unified media/comments view](https://thesweetsetup.com/wp-content/uploads/2016/03/antenna-ipad-02.jpg)
- [iPhone feed and post view](https://thesweetsetup.com/wp-content/uploads/2016/03/antenna-iphone-01.jpg)
- [iPhone X dense feed](https://superphen.wordpress.com/wp-content/uploads/2017/12/iphonex-anttena-reddit1-copy.jpg?w=1000)
- [iPhone X grid, swipe menu, and settings](https://superphen.wordpress.com/wp-content/uploads/2017/12/iphonex-antenna-reddit.jpg?w=1000)

## Confirmed feature inventory

### Browsing and navigation

- Infinite and manual pagination
- Front page, subreddit, multireddit, user, search, saved, hidden, and overview listings
- Sort controls and ordered subreddit list
- Recently viewed posts and optional history retention
- Restore previous UI/navigation state after process termination
- Last-dismissed-screen recovery
- User-created shortcuts with per-shortcut sorting
- Hide all/hide read and duplicate-post detection across pages
- Reddit Gold visited-link synchronization and Synccit integration (historical; do not reproduce unless still viable)

### Posts and comments

- Vote, reply, save, hide, share, edit, delete, filter, browser-open, and moderation actions
- Full Reddit-flavored Markdown, embedded links, spoiler text, and formatting toolbar
- Collapsible nested comments with configurable tap behavior
- Original-poster identification
- Sort and comment-limit options
- Jump to next root comment, OP comment, or current user's comment
- Load-more-comments nodes while preserving comment sort
- Optional next-post control below a comment tree
- Filter individual posts/comments and optionally collapse AutoModerator

### Media and links

- Inline image, animated GIF/GIFV, Gfycat, Giphy, Reddit-hosted video, YouTube, and Imgur-album handling
- Link/self-text/site preview modes
- GIF duration/progress, long-GIF scrollbar, and scrubbing
- Full-size image view, zoom, paging, sharing, and saving
- Cellular maximum-download size and smaller Reddit-provided preview use
- Embedded Safari, Safari Reader, external Safari, or Chrome
- Low-memory image downscaling and cache clearing

### Accounts, privacy, and communication

- Multiple Reddit accounts with fast switching
- OAuth with refresh tokens
- Inbox, private-message reply, comment reply, and moderator mail
- Notification controls and reply from notification where available
- Passcode plus Touch ID/Face ID
- Optional analytics/bug-reporting controls in the historic app; replacement should have no analytics by default

### Appearance and customization

- Day, night, and automatic night modes
- Custom fonts and text sizes
- Dense list, thumbnail, image/grid, and preview modes
- Optional post bottom bar
- Configurable quick press, comment tap, previews, and 3D Touch shortcuts

## Current Reddit access constraints

As of this research date:

- Reddit requires Data API access to be requested/approved.
- All clients must use registered OAuth and a descriptive User-Agent.
- Eligible free Data API usage is limited to 100 queries per minute per OAuth client ID, averaged over a ten-minute window.
- Cached Reddit data must be kept short-lived and removed when source content or accounts are deleted; Reddit recommends routinely deleting stored content within 48 hours.
- Non-commercial use is the safest request posture. Monetization requires separate written approval/agreement.
- Reddit announced on 2026-08-06 that it intends eventually to restrict new public API requests and require third-party apps to move to its Developer Platform. Reddit explicitly said this migration will not occur during 2026, and the current Developer Platform does not yet expose everything required by a full native client.

Consequences for the design:

1. Define a `RedditService` protocol; no screen should depend directly on HTTP shapes.
2. Supply `FixtureRedditService` for deterministic UI development and screenshots.
3. Supply `DataAPIRedditService` only after approval and credentials exist.
4. Keep OAuth credentials out of source control and old Antenna credentials out of the new app.
5. Use Keychain for refresh tokens and per-account credential isolation.
6. Implement rate-limit headers, request coalescing, caching, exponential retry, and deletion-aware expiration centrally.
7. Keep a future Developer Platform adapter possible, although its client-app viability is currently incomplete.

Primary Reddit sources:

- [Reddit Data API Wiki](https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki)
- [Developer Terms](https://redditinc.com/policies/developer-terms)
- [Data API Terms](https://redditinc.com/policies/data-api-terms)
- [August 2026 API/Developer Platform announcement](https://www.reddit.com/r/redditdev/comments/1vgbm9c/our_plans_for_the_future_of_reddits_public_data/)

## Personal iPhone deployment

Free deployment is supported by Apple through an Xcode Personal Team:

1. Install the current Xcode on a Mac.
2. Sign in with a free Apple Account in Xcode.
3. Connect the iPhone, enable Developer Mode, and trust the Mac.
4. Select the Personal Team for signing and use an original, unique bundle identifier.
5. Build and run directly on the phone.

Free-account limits:

- Provisioning expires after seven days.
- Rebuild/reinstall after expiration.
- Up to 3 installed Personal Team apps per device.
- Up to 3 temporary registered devices.
- Up to 10 temporary App IDs.
- No App Store or TestFlight distribution.
- Some advanced entitlements are unavailable.

A paid Apple Developer Program membership removes the seven-day development-signing churn and enables TestFlight/App Store workflows, but it is unnecessary for initial personal development.

Primary Apple source: [Developer account overview and Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)

## Recommended implementation

Use Swift and SwiftUI for the application shell, dropping to UIKit gesture recognizers and collection-view behavior where SwiftUI gesture arbitration or high-density scrolling is insufficient.

```text
AntennaSuccessor/
  App/
    AppState, NavigationState, Dependencies
  Domain/
    Post, Comment, Community, Account, Message, Listing, Sort
  Services/
    RedditService protocol
    FixtureRedditService
    DataAPIRedditService
    OAuthSessionStore
    RateLimiter
  Features/
    Feed
    PostAndComments
    MediaViewer
    SwipeMenu
    Inbox
    User
    Search
    Composer
    Settings
  Interaction/
    SwipeAnywhereCoordinator
    ContextActionResolver
    CommentCollapseController
    ScrollPositionStore
  Persistence/
    Keychain credentials
    SQLite/GRDB cache
    UserDefaults preferences
  Fixtures/
    Feeds, posts, comments, accounts, errors
```

Do not begin by implementing every historic integration. Pocket, Readability, Instapaper, Synccit, old Imgur APIs, Flurry, AdMob, 3D Touch, Chrome-specific URLs, and Reddit Gold sync are either obsolete or secondary. Preserve the user-facing intent through the system share sheet, local history, modern context menus, and optional compatibility work later.

## Build order

### Milestone 1: interaction prototype

- Original app identity and theme tokens
- Dense light/night feed using fixtures
- Swipe-anywhere back and right-side menu
- Feed contextual actions
- Unified post/media/comments screen
- Nested comment collapse and scroll-position restoration
- Settings for density, text size, tap action, previews, and night mode
- Install on the owner's iPhone through a free Personal Team

This milestone proves the reason to rebuild Antenna without needing Reddit approval.

### Milestone 2: complete offline product shell

- Image/grid feed
- Image, GIF/video, gallery, link, and self-text renderers
- Search, inbox, profile, saved, recent, and composer screens using fixtures
- Multiple mock accounts and account switching
- Accessibility, Dynamic Type option, VoiceOver, reduced motion, landscape, iPad, and split view
- UI tests for every gesture conflict and preserved scroll position

### Milestone 3: approved live Reddit transport

- OAuth authorization-code flow for an installed app
- Read feeds, post details, comments, subscriptions, user pages, and inbox
- Vote, save, hide, reply, submit, edit, and delete
- Rate limiting, token refresh, transient-error handling, and cache expiry/deletion compliance

### Milestone 4: parity and polish

- Filtering and shortcut editor
- Moderator tools if API access permits
- Notifications if permitted and supportable without an always-on backend
- Advanced media handling, GIF scrubbing, and comment navigation
- Exact iPad behavior and optional automatic day/night schedule

## Principal risks

| Risk | Impact | Mitigation |
|---|---|---|
| Reddit denies Data API access | No full live client | Build fixture-complete UI first; submit a narrowly scoped, non-commercial approval request early |
| Reddit moves clients to Developer Platform | Transport rewrite | Strict service boundary and no HTTP models in UI |
| Gesture conflicts | Product fails to feel like Antenna | Central gesture coordinator plus device-level UI tests |
| Visual imitation becomes IP confusion | Distribution/legal friction | Original name, icon, copy, and assets; reproduce workflows rather than branding |
| Seven-day free signing | Weekly reinstall inconvenience | Accept for prototype or later join paid Developer Program |
| Backup credential exposure | Account compromise | Keep backup untracked/private; never import its tokens; revoke old sessions if concerned |

## External code references

- [Beam](https://github.com/awkward/Beam) is an older GPL-2.0 iOS Reddit client. It is useful for historical Reddit models, Markdown, comment trees, and media concepts, but direct reuse imposes GPL obligations and much of its networking/UI code is obsolete.
- [Infinity for Reddit iOS](https://github.com/foxanastudio/Infinity-For-Reddit-iOS) is a current SwiftUI implementation with repositories for feeds, comments, accounts, moderation, media, filtering, and OAuth. No license was visible during this review, so its code must not be copied without permission.

## Remaining evidence that would materially improve fidelity

The most valuable missing artifact is a screen recording from a device on which Antenna still launches. Capture:

1. Cold launch and state restoration
2. Every right-side menu section
3. Feed row gestures and long-press actions
4. Post/comment gestures and collapse/navigation behavior
5. Image, GIF, album, video, and browser dismissal
6. Inbox, account switching, search, saved, recent, and profile
7. Every settings section in both light and night mode
8. iPad portrait, landscape, split view, and keyboard behavior

Without that recording, the surviving screenshots, listing, release history, and backup are sufficient for a faithful spiritual successor, but not a provably exact clone.
