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

| Field | Value |
| --- | --- |
| Application name | `ReAntenna` |
| Platform | Native iOS installed application |
| Bundle identifier | `com.chocotonic.reantenna` |
| OAuth redirect URI | `reantenna://oauth` |
| Distribution | Personal device through SideStore |
| Business status | Individual, noncommercial |
| Company | `N/A` |
| Source URL | `https://github.com/ChocoTonic/reantenna` |
| Initial audience | One user |
| Initial scopes | `identity`, `read`, `mysubreddits` |

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

The form's labels may change. Select the options closest to:

- Assistance: Data API or API access
- Role: Developer
- Inquiry: Bot/App not supported by Devvit
- Organization: Individual or noncommercial
- Company name: `N/A`

Use this subject:

```text
Noncommercial Data API access request — ReAntenna iOS client
```

Use this detailed description, replacing `MY_USERNAME` with the Reddit username
that will be responsible for the application:

```text
I am requesting Data API access for ReAntenna, a personal,
noncommercial native iOS Reddit reader.

ReAntenna is an independently written, unofficial application inspired
by the interaction model of the discontinued Antenna/AMRC client. It is
not affiliated with Reddit or the original Antenna developer.

The application will initially be used only by me on my personal iPhone
and installed through SideStore. It has no advertising, subscriptions,
payments, analytics, data resale, AI training, scraping, or server-side
data collection.

Initial API access will be read-only. It will use OAuth scopes for
identity, read access, and subscribed subreddit listings. It will display
the authenticated user's normal feeds, posts, comments, and subreddit
subscriptions. It will not perform automated voting, posting, messaging,
moderation, or other automated account activity.

Authentication uses Reddit OAuth through ASWebAuthenticationSession.
Access and refresh tokens are stored only in the iOS Keychain. Reddit
passwords are never collected. API data remains on the device, caching
is limited, and deleted or expired Reddit content will be removed in
accordance with Reddit's retention requirements.

The OAuth redirect URI is:

reantenna://oauth

The iOS bundle identifier is:

com.chocotonic.reantenna

The User-Agent will be:

ios:com.chocotonic.reantenna:v0.2.0 (by /u/MY_USERNAME)

Source:
https://github.com/ChocoTonic/reantenna
```

For **What benefit/purpose will the app have?** use:

```text
ReAntenna provides a compact, gesture-first native iOS reading interface,
including efficient comment navigation and the ability to collapse all
child comments while preserving root comments. It is intended as a
personal, accessible alternative interface for reading Reddit.
```

For **What is missing from Devvit?** use:

```text
Devvit runs applications and community experiences within Reddit.
ReAntenna is an external native iOS reader with device-side navigation,
accessibility, media presentation, local preferences, and an independent
SwiftUI interface. That native-client use case cannot be implemented as
a Devvit community app.
```

For **What subreddits will the app use?** use:

```text
The authenticated user's subscribed and manually selected subreddits.
There is no fixed subreddit list and no bulk collection.
```

For **What is your data budget?** use:

```text
One initial user, substantially below 100 requests per minute. The client
will inspect Reddit's X-Ratelimit headers and throttle requests.
```

Attach or link the source only if Reddit can access it. If the repository remains
private, describe it truthfully as private personal source rather than open source.

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
