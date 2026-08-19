# Register ReAntenna for Reddit Data API access

Last verified: 2026-08-18

Reddit currently requires explicit approval before a new application accesses
Reddit data through the Data API. ReAntenna is an external native iOS client, so
its use case is not supported by Devvit's on-Reddit application model. Apply for
Data API access before relying on the legacy self-service OAuth application page.

Official references:

- [Developer Platform and accessing Reddit data](https://support.reddithelp.com/hc/en-us/articles/14945211791892-Developer-Platform-Accessing-Reddit-Data)
- [Responsible Builder Policy](https://support.reddithelp.com/hc/en-us/articles/42728983564564-Responsible-Builder-Policy)
- [Reddit Data API Wiki](https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki)
- [Data API access request](https://support.reddithelp.com/hc/en-us/requests/new?ticket_form_id=14868593862164)

## 1. Prepare the application identity

Use these stable values:

| Field              | Value                                     |
| ------------------ | ----------------------------------------- |
| Application name   | `ReAntenna`                               |
| Platform           | Native iOS installed application          |
| Bundle identifier  | `com.chocotonic.reantenna`                |
| OAuth redirect URI | `reantenna://oauth`                       |
| Distribution       | Personal device through SideStore         |
| Business status    | Individual, noncommercial                 |
| Company            | `N/A`                                     |
| Source URL         | `https://github.com/ChocoTonic/reantenna` |
| Initial audience   | One user                                  |
| Initial scopes     | `identity`, `read`, `mysubreddits`        |

Before applying:

1. Use a Reddit account in good standing with a verified email address.
2. Decide whether to make the repository public.
3. If describing the project as open source, first make the repository public and
   add an actual license. MIT is the proposed default.
4. Add a privacy policy before distributing the application to anyone else.
5. Do not claim affiliation with Reddit or the original Antenna developer.

## 2. Submit the Data API request

Open the official [Data API access request](https://support.reddithelp.com/hc/en-us/requests/new?ticket_form_id=14868593862164)
while signed into Reddit.

The form path verified on 2026-08-18 uses these fields:

| Field | Answer |
| --- | --- |
| Assistance | **Data Access Request** |
| Role | **I'm a developer** |
| Inquiry | **I'm a developer and want to build a Reddit App that does not work in the Devvit ecosystem.** |
| Reddit account | `giddiness-uneasy` |
| Source | `https://github.com/ChocoTonic/reantenna` |
| Bot username | `N/A — users authenticate through OAuth.` |

Use an email address you monitor. For **What benefit/purpose will the bot/app have for Redditors?**, paste:

```text
ReAntenna is a personal, noncommercial native iOS Reddit reader with a compact, gesture-first interface for feeds and comment threads, including root-comment navigation and collapsing all child comments while keeping roots visible. It is independently written, inspired by the discontinued Antenna/AMRC interaction model, and is not affiliated with Reddit or the original developer.

The initial version is for one personal iPhone installed through SideStore. It requests read-only OAuth access for identity, reading, and subreddit subscriptions, and displays normal feeds, selected subreddits, posts, comments, and comment trees. It performs no automated voting, posting, messaging, moderation, or account activity.

The app has no ads, payments, analytics, data resale, AI training, scraping, or server-side collection. OAuth runs through ASWebAuthenticationSession, tokens stay in the iOS Keychain, passwords are never collected, caching is limited, deleted content is removed, and rate-limit headers are respected.

OAuth redirect URI: reantenna://oauth
Bundle identifier: com.chocotonic.reantenna
User-Agent: ios:com.chocotonic.reantenna:v0.2.0 (by /u/giddiness-uneasy)
```

For **What is missing from Devvit?**, paste:

```text
ReAntenna is a standalone native SwiftUI app installed on an iPhone. It requires native navigation, local preferences, Keychain-based user OAuth, account-level feeds and subscriptions, and browsing across user-selected communities. Devvit apps run inside Reddit posts or installed communities and cannot expose private account data such as subscribed subreddits, saved content, vote history, or recently viewed posts. Devvit therefore cannot provide this native client or its account-level reading workflow.
```

For **What subreddits do you intend to use?**, paste:

```text
The authenticated user's subscribed and manually selected subreddits, plus normal home/front-page and r/all-style reading feeds. There is no fixed subreddit list, automation, or bulk collection.
```

The repository is currently private, so Reddit cannot inspect the source link. Make it public with a license before submitting, or state that it is private personal source and attach a reviewable archive. Never attach credentials, tokens, signing or pairing files, IPA/build products, `Config/Reddit.local.xcconfig`, or the historic Antenna backup.

## 3. Wait for explicit approval

Submitting the request does not grant access. Wait for Reddit to explicitly approve
the use case. Do not submit duplicate requests using additional accounts; Reddit's
Responsible Builder Policy requires transparent registration and prohibits multiple
requests for the same use case.

Retain Reddit's approval email or ticket number. If Reddit requests changes, update
this document and the implementation before registering the OAuth client.

## 4. Create the installed-app OAuth client

After approval:

1. Open [Reddit application preferences](https://www.reddit.com/prefs/apps).
2. Select **create another app**.
3. Set the name to `ReAntenna`.
4. Select **installed app**, not **script** or **web app**.
5. Use `Personal noncommercial native iOS Reddit reader` as the description.
6. Use `https://github.com/ChocoTonic/reantenna` as the About URL if the
   repository is public; otherwise omit it or use an approved public project page.
7. Set the redirect URI to exactly `reantenna://oauth`.
8. Create the application.
9. Copy the short client ID displayed beneath the application name.

An installed/native application has a client ID but does not use a client secret.
Never place a Reddit password, authorization code, access token, refresh token, or
historic Antenna credential in chat, source control, or an xcconfig file.

## 5. Configure ReAntenna locally

Provide only these two non-secret values:

```text
Reddit username: giddiness-uneasy
Client ID: YOUR_INSTALLED_APP_CLIENT_ID
```

Then create the ignored local configuration:

```sh
cd /Users/asdf/repos/reantenna
cp Config/Reddit.local.example.xcconfig Config/Reddit.local.xcconfig
open -e Config/Reddit.local.xcconfig
```

Set:

```xcconfig
REDDIT_CLIENT_ID = YOUR_INSTALLED_APP_CLIENT_ID
REDDIT_DEVELOPER_USERNAME = giddiness-uneasy
```

Regenerate and build:

```sh
xcodegen generate
./scripts/build-sidestore-ipa.sh
```

The build script produces the canonical IPA at:

```text
/Users/asdf/repos/reantenna/build/ReAntenna-unsigned.ipa
```

It also copies a versioned IPA to:

```text
/Users/asdf/Downloads/
```

Install the new version over the existing ReAntenna app through SideStore. Do not
delete the old installation first if its local data should survive.

## 6. Validate the approved connection

1. Open ReAntenna.
2. Open the right-side menu.
3. Select **Reddit Account**.
4. Select **Connect Reddit**.
5. Verify Reddit displays only `identity`, `read`, and `mysubreddits` initially.
6. Approve the request.
7. Confirm the account screen displays `u/giddiness-uneasy`.
8. Confirm the front page and a comment thread load live Reddit data.
9. Force-quit and reopen ReAntenna to verify Keychain restoration and token refresh.
10. Disconnect once and verify the app returns to fixture mode.

Only add write scopes after their corresponding user-initiated features are real,
reviewed, and permitted by Reddit's approval.

## Operating requirements

- Authenticate every Data API request through the registered OAuth client.
- Use a truthful User-Agent in Reddit's required format.
- Monitor the `X-Ratelimit-Used`, `X-Ratelimit-Remaining`, and
  `X-Ratelimit-Reset` response headers.
- Stay within the approved rate and usage limits.
- Remove Reddit content that Reddit or its author deletes. Reddit currently
  recommends routinely clearing stored Reddit data within 48 hours.
- Do not add advertising, payment, subscriptions, data resale, analytics, or model
  training without revisiting Reddit's approval and terms first.
