# Reddit Data API application for ReAntenna

Last verified: August 19, 2026

ReAntenna must not access live Reddit data until Reddit gives explicit written approval. The current app remains a fixture-data prototype. Official requirements: [Responsible Builder Policy](https://support.reddithelp.com/hc/en-us/articles/42728983564564-Responsible-Builder-Policy), [Developer Terms](https://redditinc.com/policies/developer-terms), [Data API Terms](https://redditinc.com/policies/data-api-terms), [Data API Wiki](https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki), and [Data Access Request](https://support.reddithelp.com/hc/en-us/requests/new?ticket_form_id=14868593862164).

## What likely caused rejection 18313736

Reddit gave a generic Responsible Builder Policy/details rejection rather than a specific defect. The original submission left reviewers to infer several facts: exact endpoint patterns and actions, expected request volume, why Devvit cannot implement a standalone iOS reader, retention and deletion behavior, app-label applicability, and how the code enforces the claimed safeguards. The linked repository was also described as private even though it is public, had no privacy policy, had no complete in-app deletion control, requested one unused OAuth scope, allowed shared URL caching, and observed rate-limit headers without blocking subsequent calls.

Those implementation issues are now addressed: the repository is public; `PRIVACY.md` is public and linked in the app; the initial scopes are only `identity` and `read`; Reddit HTTP uses ephemeral non-caching sessions; a depleted rate limit blocks calls until reset; local media cache is purged at least every 48 hours on launch; and the Reddit Account screen can revoke authorization and delete Keychain credentials, history, and cached responses. The project is source-available but not currently open source because no license has been selected.

Do not submit simultaneous or duplicate requests. Reply to ticket **18313736** with the clarification below. Submit a new form only if Reddit tells you to do so or the existing ticket cannot be reopened.

## Reply to rejection 18313736

```text
Hello Reddit Data Team,

Thank you for reviewing request 18313736. I understand the submission did not give enough information to assess compliance. I have narrowed the request and updated both the implementation and public documentation.

ReAntenna is an independently written, noncommercial, read-only native iOS client for one human user's personal use. It has no bot or app-operated account and performs no automated activity. The initial live build requests only the identity and read OAuth scopes and uses only GET /api/v1/me, GET /{sort}.json, GET /r/{subreddit}/{sort}.json, and GET /comments/{post_id}.json. It does not vote, post, reply, message, moderate, scrape, bulk collect, or access private communications. Every request follows an explicit user action such as opening, refreshing, sorting, or selecting a feed or thread.

Expected traffic is one user and normally well below 60 requests per minute. The client sends its registered OAuth identity and truthful User-Agent, reads Reddit's rate-limit headers, stops requests when the remaining allowance reaches zero, honors the reset interval and HTTP 429, and does not rotate accounts or client IDs to evade limits.

ReAntenna has no developer server, ads, analytics, tracking, payments, data resale, model training, sensitive-trait inference, re-identification, or off-platform identity matching. Tokens are stored in the device-only iOS Keychain. Reddit API sessions are ephemeral with URL caching disabled. Up to 100 viewed post IDs may be stored locally; the user can disable or clear history. Media cache is user-controlled and purged at least every 48 hours on launch. An in-app deletion action attempts token revocation and deletes credentials, history, and cached responses.

Devvit cannot implement this use case because ReAntenna is a standalone native SwiftUI application with device-level navigation, accessibility, Keychain OAuth, local preferences, and user-directed browsing across communities. It is not an experience embedded in a Reddit post or community. No fixed subreddit list is targeted; the user manually chooses ordinary public communities and feeds.

Public source: https://github.com/ChocoTonic/reantenna
Privacy policy: https://github.com/ChocoTonic/reantenna/blob/main/PRIVACY.md
Bundle ID: com.chocotonic.reantenna
Redirect URI: reantenna://oauth
Planned User-Agent: ios:com.chocotonic.reantenna:v0.2.0 (by /u/giddiness-uneasy)

The app has no automated account, but I will still complete Reddit's required developer/app-profile registration and any labeling Reddit directs after approval and before live use. The live Data API path remains disabled until explicit approval. Please let me know which remaining policy requirement or technical detail needs correction.
```

## Complete form answers

Use the exact form selections below if Reddit requests a new submission.

| Exact field | Answer |
| --- | --- |
| What do you need assistance with? | **Data Access Request** |
| Your email address | The verified email associated with the applying Reddit account |
| Which role best describes your reason for requesting API access? | **I’m a developer** |
| What is your inquiry? | **I’m a developer and want to build a Reddit App that does not work in the Devvit ecosystem.** |
| Reddit account name | `giddiness-uneasy` |

### What benefit/purpose will the bot/app have for Redditors?

```text
ReAntenna gives an iOS Redditor a compact, accessible, gesture-first reading interface designed for long discussion threads. Its main benefits are dense native feeds, reliable root-comment navigation, and a Collapse Children command that keeps every root comment visible while hiding all descendants. It is independently written, personal, noncommercial, read-only, and not affiliated with Reddit or the discontinued Antenna developer. The initial audience is one human user on one iPhone.
```

### Provide a detailed description of what the Bot/App will be doing on the Reddit platform.

```text
ReAntenna is a standalone native SwiftUI reader. After the human user explicitly authorizes Reddit OAuth, the initial live build requests only identity and read. It uses GET /api/v1/me to display the authorized username; GET /{sort}.json for the user's OAuth home listing; GET /r/{subreddit}/{sort}.json for a public community the user manually selects, including hot, new, top, and controversial sorts; and GET /comments/{post_id}.json for a thread the user opens. Requests use raw_json=1 and conservative page limits. Every request is caused by a visible user action such as opening, refreshing, sorting, or selecting a listing or thread.

The approved initial version will not vote, save, hide, post, edit, delete, reply, send private messages, moderate, or perform background or scheduled Reddit activity. It has no bot or shared app account. Prototype action controls affect bundled fixture/local UI state only and are not sent to Reddit. Any future write feature would require a separate review of scopes, user consent, and Reddit approval before release.

Expected use is one person, normally a few requests per browsing minute and always below a client-side ceiling of 60 requests per minute. The client authenticates every live request with the one approved OAuth client, sends User-Agent ios:com.chocotonic.reantenna:v0.2.0 (by /u/giddiness-uneasy), monitors X-Ratelimit-Used, X-Ratelimit-Remaining, and X-Ratelimit-Reset, blocks further requests when the remaining allowance reaches zero, and honors HTTP 429. It will not rotate client IDs, accounts, addresses, or credentials to evade limits.

There is no developer-operated backend. The app has no ads, analytics, tracking, payments, commercialization, data resale or licensing, AI/model training, sensitive-characteristic inference, re-identification, or matching to off-platform identities. OAuth passwords are handled only by Reddit's authorization page. Tokens are stored in the iOS Keychain with device-only accessibility. Reddit API URL caching is disabled. Local preferences and at most 100 recently viewed post IDs stay on the device. A user-controlled media cache is purged at least every 48 hours on app launch. Users can clear history and cache separately or use Delete Reddit Data to attempt OAuth revocation and remove credentials, history, and cached responses. Deleted Reddit content is not retained in a persistent API cache and disappears after refresh.

The public code and privacy policy are available at https://github.com/ChocoTonic/reantenna and https://github.com/ChocoTonic/reantenna/blob/main/PRIVACY.md. Bundle identifier: com.chocotonic.reantenna. OAuth redirect URI: reantenna://oauth. Live access is disabled until Reddit explicitly approves it.
```

### Provide examples, the more detailed this description the more likely we will be able to assess your request.

```text
Example 1: The user opens ReAntenna and refreshes the home feed. The app makes one authenticated GET /hot.json request and renders that response locally.

Example 2: The user enters a public subreddit name such as swift and chooses New. The app makes one GET /r/swift/new.json request. It does not crawl linked communities or fetch unrelated listings.

Example 3: The user opens one post. The app makes one GET /comments/{post_id}.json request, renders the post and comment tree, and then performs collapsing, expanding, comment sorting, and root-comment navigation entirely on device without further API actions unless the user refreshes.

Example 4: The user chooses Delete Reddit Data. The app attempts OAuth token revocation, deletes its Keychain credential, viewed-post IDs, and cached responses, and returns to bundled fixture mode.

The app never runs an unattended job, sends bulk requests, posts repeated content, communicates privately, manipulates votes or karma, bypasses blocks or bans, or uses moderator status.
```

### What is missing from Devvit that prevents building on that platform?

```text
Devvit builds experiences that run within Reddit posts or installed communities. ReAntenna must be a standalone native iOS application with SwiftUI screens, device-wide gesture navigation, iOS accessibility behavior, local preferences and history controls, iOS Keychain OAuth storage, and user-directed browsing between a home listing, arbitrary public communities, and full comment threads. These device-level client capabilities and a native application lifecycle cannot be delivered as an embedded Devvit post or community app. ReAntenna does not need server triggers, automation, custom posts, mod actions, or Devvit storage; its unsupported requirement is the external native reader itself.
```

### Provide a link to source code or platform that will access the API.

```text
https://github.com/ChocoTonic/reantenna
```

### What subreddits do you intend to use the bot/app in?

```text
There is no fixed or pre-collected subreddit list. The one authenticated user may manually request ordinary public subreddits while reading, for example r/swift or r/ios, as well as the user's OAuth home listing. The app does not install into communities, moderate, crawl subreddit lists, target sensitive communities, or bulk collect content. Access is limited to the specific listing or thread the user opens.
```

### If applicable, what username will you be operating this Bot/App under? (optional)

```text
N/A. ReAntenna has no bot, automated, shared, or app-operated Reddit account. The applying developer is u/giddiness-uneasy, and the only user authenticates their own human account through OAuth.
```

Attachments are optional. If useful, attach current screenshots of the fixture-mode feed, Collapse Children behavior, Privacy screen, and Delete Reddit Data confirmation. Never attach an IPA, Apple signing/pairing material, OAuth tokens, passwords, client secrets, local xcconfig files, or credentials recovered from the historic app.

## Policy mapping

| Reddit requirement | ReAntenna evidence |
| --- | --- |
| Explicit approval before API access | Live path has no client ID and remains disabled pending approval. |
| Accurate identity and purpose | Stable bundle ID, redirect URI, developer username, public source, exact endpoint list, and truthful User-Agent are disclosed. |
| Minimum access | Initial OAuth scopes are only `identity` and `read`; transport implements GET listings and threads only. |
| No automated or manipulative activity | No bot account, background jobs, write endpoints, voting, messaging, moderation, or safety bypass. |
| Rate-limit compliance | Headers are parsed; zero remaining blocks calls until reset; HTTP 429 is honored; one approved client only. |
| Privacy and security | Public and in-app policy, Keychain credentials, ephemeral API sessions, no backend/analytics/ads/sharing/training. |
| Retention and deletion | No persistent API response cache, 48-hour media purge, history controls, full local Reddit-data deletion and revocation attempt. |
| Devvit-first explanation | Native external application requirements are identified specifically; no Devvit-hosted function is being requested. |
| App transparency | Stable public identity and source are disclosed; required developer/app-profile registration and any Reddit-directed labeling will be completed before live use. |

## After explicit approval

Complete Reddit's required developer/app-profile registration and any directed labeling, then create one **installed app** OAuth client at Reddit's application preferences using `reantenna://oauth`; an installed app has a client ID and no client secret. Put only the client ID and `giddiness-uneasy` in the ignored `Config/Reddit.local.xcconfig`, regenerate with `xcodegen generate`, and verify the consent page lists only `identity` and `read`. Keep the bundle identifier unchanged. Do not add write scopes or enable live use beyond the approved purpose.

Before describing ReAntenna as open source, the owner must choose and add a license. Until then, call it source-available. This is separate from Reddit approval and should not be misrepresented.
