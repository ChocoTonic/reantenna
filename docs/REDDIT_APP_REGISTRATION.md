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

The form path verified on 2026-08-18 displays the fields below. Fill them as
follows, replacing every `YOUR_USERNAME` placeholder.

### What do you need assistance with?

Select:

```text
Data Access Request
```

### Your email address

Use the email address you actively monitor and that is associated with the Reddit
account responsible for ReAntenna.

### Which role best describes your reason for requesting API access?

Select:

```text
I'm a developer
```

### What is your inquiry?

Select:

```text
I'm a developer and want to build a Reddit App that does not work in the Devvit ecosystem.
```

Do not select the moderator-tool option. ReAntenna is a general native reader, not
a tool whose primary purpose is moderating a subreddit.

### Reddit account name

Enter only the username responsible for the application, without `/u/`:

```text
YOUR_USERNAME
```

### What benefit/purpose will the bot/app have for Redditors?

This field also asks for a detailed description of what the application will do.
Paste the following after replacing `YOUR_USERNAME`:

```text
ReAntenna is a personal, noncommercial native iOS Reddit reader. It
provides a compact, gesture-first interface for reading feeds and comment
threads, including efficient root-comment navigation and the ability to
collapse all child comments while preserving the root comments. It is
intended to provide an accessible, information-dense native reading
experience on an iPhone.

ReAntenna is independently written and is an unofficial application
inspired by the interaction model of the discontinued Antenna/AMRC
client. It is not affiliated with Reddit or the original Antenna
developer.

The initial version will be used only by me on my personal iPhone and
installed through SideStore. Initial Data API access will be read-only.
It will use OAuth scopes for identity, reading, and the authenticated
user's subreddit subscriptions. It will display the user's normal feeds,
selected subreddits, posts, comments, and comment trees. It will not
perform automated voting, posting, messaging, moderation, or other
automated account activity.

The app has no advertising, subscriptions, payments, analytics, data
resale, AI training, scraping, or server-side data collection. It makes
requests directly from the user's device.

Authentication uses Reddit OAuth through Apple's
ASWebAuthenticationSession. Access and refresh tokens are stored only in
the iOS Keychain, and the app never collects a Reddit password. Local
caching is limited, and deleted or expired Reddit content will be removed
in accordance with Reddit's retention requirements. The client will
monitor Reddit's rate-limit response headers and remain substantially
below the documented free-access limit.

OAuth redirect URI: reantenna://oauth
Bundle identifier: com.chocotonic.reantenna
User-Agent: ios:com.chocotonic.reantenna:v0.2.0 (by /u/YOUR_USERNAME)
Initial audience: one user
```

### What is missing from Devvit that prevents building on that platform?

Paste:

```text
ReAntenna is a standalone native SwiftUI iOS application installed on the
user's device. It requires native device navigation, local preferences,
Keychain-based per-user OAuth, account-level feeds and subscriptions, and
browsing across the user's selected communities.

Devvit applications run inside Reddit posts or installed communities as
web experiences. Devvit's Reddit API documentation also states that it
does not expose private logged-in-user data such as subscribed
subreddits, saved content, vote history, or recently viewed posts. Devvit
therefore cannot provide ReAntenna's standalone native interface or its
required account-level reading workflow. This use case requires an
approved Data API installed-app OAuth client.
```

### Provide a link to source code or platform that will access the API

If the repository has been made public, enter:

```text
https://github.com/ChocoTonic/reantenna
```

The repository is currently private. A private GitHub URL does not let Reddit's
reviewer inspect the source. Either make it public and add a license before
submitting, or truthfully explain that it is private personal source and attach a
reviewable source archive if the form permits it. Do not attach build products,
signing files, pairing files, tokens, credentials, or the historic Antenna backup.

### What subreddits do you intend to use the bot/app in?

Paste:

```text
The authenticated user's subscribed and manually selected subreddits,
along with the normal home/front-page and r/all-style reading feeds. There
is no fixed subreddit list, subreddit-specific automation, or bulk data
collection. Initially the app will be used by one person for ordinary
interactive reading.
```

### If applicable, what username will you be operating this Bot/App under?

ReAntenna does not operate a bot account. Enter:

```text
N/A — the app has no bot account. The user signs into their own Reddit account through OAuth.
```

### Attachments

Attachments are optional. Useful attachments are a screenshot of the working
fixture-mode interface or a small source archive if the repository remains private.
Before attaching an archive, verify that it excludes:

- `Config/Reddit.local.xcconfig`
- build products and IPA files
- Apple signing or device-pairing material
- OAuth tokens, cookies, passwords, or Keychain exports
- the historic Antenna iMazing backup

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
Reddit username: YOUR_USERNAME
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
REDDIT_DEVELOPER_USERNAME = YOUR_USERNAME_WITHOUT_U_SLASH
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
7. Confirm the account screen displays `u/YOUR_USERNAME`.
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
