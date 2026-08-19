# Reddit Data API application for ReAntenna

Last verified: August 19, 2026

ReAntenna must not access live Reddit data until Reddit gives explicit written approval. The current app remains in fixture mode without an approved client ID. Official requirements: [Responsible Builder Policy](https://support.reddithelp.com/hc/en-us/articles/42728983564564-Responsible-Builder-Policy), [Developer Terms](https://redditinc.com/policies/developer-terms), [Data API Terms](https://redditinc.com/policies/data-api-terms), [Data API Wiki](https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki), and [Data Access Request](https://support.reddithelp.com/hc/en-us/requests/new?ticket_form_id=14868593862164).

## What likely caused rejection 18313736

Reddit gave a generic Responsible Builder Policy/details rejection rather than identifying one defect. The original submission did not state every requested scope and endpoint, distinguish interactive writes from automation, estimate traffic, explain why Devvit cannot provide a standalone iOS client, or describe retention and deletion precisely. It also described the repository as private when it is public and lacked an accessible privacy policy.

The request below is deliberately limited. ReAntenna reads feeds and threads and lets the authenticated user manually comment or reply, edit or delete their own comments and self-text posts, vote, and save or unsave. It does not submit new posts, access private messages, moderate, report, hide, change subscriptions, or perform automated or background writes. The initial scopes are exactly `identity`, `read`, `submit`, `edit`, `vote`, and `save`; Reddit's `submit` scope is required for comments even though new-post submission is excluded.

Reply to ticket **18313736** with the clarification below. Do not submit a simultaneous duplicate request. Submit a new form only if Reddit directs you to do so or the existing ticket cannot be reopened.

## Reply to rejection 18313736

```text
Hello Reddit Data Team,

Thank you for reviewing request 18313736. I understand that my original submission did not provide enough detail to assess compliance. I have narrowed and documented the exact use case and updated the public implementation and privacy policy.

ReAntenna is an independently written, MIT-licensed, noncommercial native iOS Reddit client for one human user's personal use. It has no bot, shared account, developer backend, or unattended activity. The user explicitly authorizes their own account through Reddit OAuth and every write is initiated by a visible user action.

The requested scopes are identity, read, submit, edit, vote, and save. Identity is used for GET /api/v1/me. Read is used for GET /{sort}.json, GET /r/{subreddit}/{sort}.json, and GET /comments/{post_id}.json. Submit is used only for POST /api/comment to create a comment or reply; ReAntenna does not submit new posts. Edit is used only for POST /api/editusertext and POST /api/del on comments and self-text posts authored by the authenticated user. Vote is used for POST /api/vote after the user explicitly chooses upvote, downvote, or clear vote. Save is used for POST /api/save and POST /api/unsave after the user explicitly chooses that action.

The initial live version does not access private messages, create new link or self-text posts, moderate, report, hide, subscribe or unsubscribe, or perform scheduled/background writes. It never automatically votes, comments, saves, edits, deletes, sends repeated content, or acts on a different user's content as though it were the user's own. Failed API writes are shown as failures and are not represented as successful local changes.

Expected traffic is one user and normally a few requests per browsing minute. Listing, thread, and write calls share a client-side ceiling of 60 requests per minute. OAuth identity, token refresh, and revocation occur only during sign-in, token expiry, or disconnect and are not included in that content-call ceiling. The client uses only the approved OAuth client and a truthful User-Agent, reads Data API rate-limit headers, blocks content and write calls when the remaining allowance reaches zero until reset, and honors HTTP 429. It does not rotate accounts, client IDs, IP addresses, or credentials to evade limits.

ReAntenna has no ads, analytics, tracking, payments, data resale or licensing, AI/model training, sensitive-trait inference, re-identification, scraping, or off-platform identity matching. Tokens are stored in the device-only iOS Keychain. Reddit API sessions are ephemeral with URL caching disabled. Up to 100 viewed post IDs may be stored locally and can be disabled or cleared. A user-controlled media cache is purged at least every 48 hours on launch. An in-app deletion action attempts token revocation and deletes credentials, history, and cached responses. Clearing local data does not falsely claim to undo an action already submitted to Reddit.

Devvit cannot implement this use case because ReAntenna is a standalone native SwiftUI application with device-level gesture navigation, accessibility behavior, Keychain OAuth, local preferences, and user-directed browsing across feeds, communities, and full comment threads. It is not an experience embedded in a Reddit post or installed community. No fixed subreddit list is targeted; the user manually selects ordinary public communities and threads.

Public source: https://github.com/ChocoTonic/reantenna
License: https://github.com/ChocoTonic/reantenna/blob/main/LICENSE
Privacy policy: https://github.com/ChocoTonic/reantenna/blob/main/PRIVACY.md
Bundle ID: com.chocotonic.reantenna
Redirect URI: reantenna://oauth
Planned User-Agent: ios:com.chocotonic.reantenna:v0.2.0 (by /u/giddiness-uneasy)

There is no automated app account. I will complete Reddit's required developer/app-profile registration and any labeling Reddit directs before live use. The live Data API path remains disabled until explicit approval. Please reconsider the request or tell me which remaining policy or technical detail must be corrected.

Thank you.
```

## Complete form answers

Use these exact selections and separate responses only if Reddit requests a new submission.

| Exact field | Answer |
| --- | --- |
| What do you need assistance with? | **Data Access Request** |
| Your email address | The verified email associated with the applying Reddit account |
| Which role best describes your reason for requesting API access? | **I’m a developer** |
| What is your inquiry? | **I’m a developer and want to build a Reddit App that does not work in the Devvit ecosystem.** |
| Reddit account name | `giddiness-uneasy` |

### What benefit/purpose will the bot/app have for Redditors?

```text
ReAntenna gives an iOS Redditor a compact, accessible, gesture-first interface for reading and participating in discussions. Its main benefits are dense native feeds, reliable root-comment navigation, and a Collapse Children command that keeps every root comment visible while hiding descendants. The user can also perform ordinary, explicitly chosen Reddit actions: comment or reply, edit or delete their own comments and self-text posts, vote, and save or unsave. ReAntenna is independently written, personal, noncommercial, open source, and intended initially for one human user on one iPhone.
```

### Provide a detailed description of what the Bot/App will be doing on the Reddit platform.

```text
ReAntenna is a standalone native SwiftUI Reddit client. After the human user explicitly authorizes their own account through Reddit OAuth, it requests identity, read, submit, edit, vote, and save. It reads the authorized identity with GET /api/v1/me, loads home listings with GET /{sort}.json, loads a manually selected public community with GET /r/{subreddit}/{sort}.json, and loads a thread with GET /comments/{post_id}.json. Every read follows a visible action such as opening, refreshing, sorting, or selecting a feed or thread.

All writes are direct consequences of an explicit user choice. POST /api/comment creates a comment or reply containing text composed by the user. ReAntenna does not use the submit scope to create new posts. POST /api/editusertext edits only a comment or self-text post authored by the authenticated user, and POST /api/del deletes only that user's own comment or self-text post. POST /api/vote applies the user's chosen upvote, downvote, or vote removal. POST /api/save and POST /api/unsave apply the user's chosen saved state. The UI reports API success or failure rather than treating a local optimistic change as final.

The initial version does not access private messages, create new link or self-text posts, moderate, report, hide, change subreddit subscriptions, or run scheduled/background Reddit activity. It has no bot, app-operated, shared, or mixed-use automation account. It never automatically votes, comments, saves, edits, or deletes, and it does not generate or repeat content.

Expected use is one person and normally a few requests per browsing minute. Listing, thread, and write calls share a 60-request-per-minute client ceiling. OAuth identity, token refresh, and revocation occur only as part of authentication lifecycle events and are outside that content-call counter. The client authenticates through the one approved OAuth client, sends User-Agent ios:com.chocotonic.reantenna:v0.2.0 (by /u/giddiness-uneasy), monitors Reddit's Data API rate-limit headers, blocks content and write calls when the remaining allowance reaches zero until reset, and honors HTTP 429. It will not rotate client IDs, accounts, addresses, or credentials to evade limits.

There is no developer-operated backend. The app has no ads, analytics, tracking, payments, commercialization, data resale or licensing, AI/model training, sensitive-characteristic inference, re-identification, scraping, or off-platform identity matching. Tokens are stored in the device-only iOS Keychain. Reddit API URL caching is disabled. Local preferences and at most 100 recently viewed post IDs stay on the device. A user-controlled media cache is purged at least every 48 hours on launch. Users can clear history and cache separately or use Delete Reddit Data to attempt OAuth revocation and remove credentials, history, and cached responses. Completed Reddit account actions remain subject to Reddit's own retention and can be reversed through the app where supported or through Reddit.

Public source: https://github.com/ChocoTonic/reantenna
Privacy policy: https://github.com/ChocoTonic/reantenna/blob/main/PRIVACY.md
Bundle identifier: com.chocotonic.reantenna
OAuth redirect URI: reantenna://oauth
Live access remains disabled until Reddit explicitly approves it.
```

### Provide examples, the more detailed this description the more likely we will be able to assess your request.

```text
Example 1: The user opens ReAntenna and refreshes the home feed. The app makes one authenticated listing request and renders the response locally. It does not crawl linked communities or prefetch unrelated listings.

Example 2: The user manually opens r/swift, chooses New, then opens one post. The app requests GET /r/swift/new.json and GET /comments/{post_id}.json. Collapsing, expanding, sorting, and root-comment navigation happen on device without another API action unless the user refreshes.

Example 3: The user writes a reply, reviews the text, and taps Reply. The app sends one POST /api/comment for the chosen parent. It never generates text, posts without the tap, repeats the reply elsewhere, or sends a private message.

Example 4: The authenticated user chooses Edit on their own comment or self-text post, changes the text, and submits it through POST /api/editusertext, or chooses Delete on that content and confirms POST /api/del. These controls are unavailable for another user's content and do not create a new post.

Example 5: The user taps Upvote, Downvote, or Clear Vote, producing one POST /api/vote with the corresponding direction. The app does not vote automatically, coordinate votes, evade a restriction, or attempt to manipulate karma.

Example 6: The user taps Save or Unsave, producing one POST /api/save or POST /api/unsave for that item. No bulk or background save operation runs.

Example 7: The user chooses Delete Reddit Data. The app attempts OAuth revocation, deletes its Keychain credential, viewed-post IDs, and cached responses, and returns to bundled fixture mode. This local deletion does not misrepresent previously submitted comments or account actions as deleted from Reddit.
```

### What is missing from Devvit that prevents building on that platform?

```text
Devvit provides experiences that run within Reddit posts or installed communities. ReAntenna must be a standalone native iOS application with SwiftUI screens, device-wide gesture navigation, iOS accessibility behavior, local preferences and history controls, iOS Keychain OAuth storage, and user-directed browsing and participation across a home listing, arbitrary public communities, and full comment threads. Those device-level client capabilities and a native application lifecycle cannot be delivered as an embedded Devvit post or community app. ReAntenna does not require server triggers, custom posts, mod actions, or Devvit storage; the unsupported requirement is the external native client itself.
```

### Provide a link to source code or platform that will access the API.

```text
https://github.com/ChocoTonic/reantenna
```

### What subreddits do you intend to use the bot/app in?

```text
There is no fixed or pre-collected subreddit list. The one authenticated user may manually open ordinary public subreddits, for example r/swift or r/ios, as well as the user's home listing and individual threads. The app does not install into communities, moderate, crawl subreddit lists, target sensitive communities, or bulk collect content. Access is limited to the specific listing, thread, or user-initiated action the user selects.
```

### If applicable, what username will you be operating this Bot/App under? (optional)

```text
N/A. ReAntenna has no bot, automated, shared, or app-operated Reddit account. The applying developer is u/giddiness-uneasy, and the only user authenticates their own human account through OAuth.
```

Attachments are optional. If useful, attach current screenshots of the fixture-mode feed, Collapse Children behavior, Privacy screen, account-action UI, and Delete Reddit Data confirmation. Never attach an IPA, Apple signing or pairing material, OAuth tokens, passwords, client secrets, local xcconfig files, or credentials recovered from the historic app.

## Policy mapping

| Reddit requirement | ReAntenna evidence |
| --- | --- |
| Explicit approval before API access | Live path has no approved client ID and remains disabled pending approval. |
| Accurate identity and purpose | Stable bundle ID, redirect URI, developer username, public source, exact endpoints, and truthful User-Agent are disclosed. |
| Purpose-limited access | Initial scopes are `identity read submit edit vote save`; submit is restricted to comments/replies and edit/delete to the authenticated user's own comments and self-text posts. |
| User control over writes | Every comment, edit, delete, vote, save, or unsave follows an explicit visible user action; API failures are surfaced. |
| No automated or manipulative activity | No bot account, scheduled/background writes, generated content, private messages, moderation, reporting, coordinated voting, or safety bypass. |
| Rate-limit compliance | A conservative client ceiling and Reddit rate-limit reset blocking are enforced; HTTP 429 is honored; one approved client is used. |
| Privacy and security | Public and in-app policy, Keychain credentials, ephemeral API sessions, and no backend, analytics, ads, sharing, or training. |
| Retention and deletion | No persistent API response cache, 48-hour media purge, history controls, local Reddit-data deletion, and revocation attempt. |
| Devvit-first explanation | The unsupported native external-client requirements are identified specifically. |
| App transparency | Stable public identity and source are disclosed; required developer/app-profile registration and Reddit-directed labeling will be completed before live use. |

## After explicit approval

Complete Reddit's required developer/app-profile registration and any directed labeling, then create one **installed app** OAuth client through the approved process using `reantenna://oauth`. An installed app has a client ID and no client secret. Put only the client ID and `giddiness-uneasy` in the ignored `Config/Reddit.local.xcconfig`, regenerate with `xcodegen generate`, and verify the consent page lists exactly `identity`, `read`, `submit`, `edit`, `vote`, and `save`. Keep the bundle identifier unchanged and do not add unapproved scopes or features.

ReAntenna is open source under the MIT License. That license does not grant Reddit Data API access; explicit Reddit approval remains required.
