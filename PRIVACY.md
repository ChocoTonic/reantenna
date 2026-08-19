# ReAntenna Privacy Policy

Effective: August 19, 2026

ReAntenna is a personal, noncommercial native iOS Reddit reader. It is independently developed and is not affiliated with Reddit or the discontinued Antenna app.

## Data processed

The default fixture mode uses bundled sample data and does not access Reddit. If Reddit approves Data API access and the user explicitly authorizes the live build through Reddit OAuth, ReAntenna processes only the data needed for its reading features: the authorized account's identity, feeds, subreddit subscriptions, posts, and comments. The initial live version requests the `identity`, `read`, and `mysubreddits` OAuth scopes. It does not post, vote, message, moderate, or run automated account activity.

## Storage and sharing

ReAntenna has no developer-operated server. It does not contain advertising, analytics, third-party tracking, data sales, data licensing, or AI/model training. Reddit data and credentials are not sent to the developer or shared with third parties by the app.

OAuth access and refresh tokens are stored in the iOS Keychain using device-only accessibility. App preferences and up to 100 recently viewed post IDs are stored locally. Reddit API traffic uses an ephemeral URL session with URL caching disabled. A user-controlled media cache may store fetched media locally and is cleared at least every 48 hours when the app is launched.

## Retention and deletion

OAuth credentials remain until the user deletes Reddit data, disconnects the account, or Reddit invalidates them. Recently viewed IDs remain until the user clears history, disables history, or deletes Reddit data. In-memory Reddit listings disappear when replaced or when the app process ends.

The user can clear read history and media cache separately in Settings. **Reddit Account > Delete Reddit data from this device** attempts OAuth revocation, deletes Keychain credentials, clears read history and cached responses, and returns ReAntenna to offline fixture mode. Deleting the iOS app removes its sandbox; use the in-app deletion control first to ensure Keychain credentials are also deleted and revocation is attempted.

## User control and Reddit removals

All Reddit access is initiated by the user. ReAntenna does not infer sensitive characteristics, re-identify users, scrape Reddit, or combine Reddit data with off-platform identifiers. Because API responses are not persistently cached, removed or deleted Reddit content is no longer displayed after the next user refresh and cannot survive as stored API response data.

## Contact and changes

Questions or deletion concerns can be sent to Reddit user `u/giddiness-uneasy` or filed in the [public ReAntenna repository](https://github.com/ChocoTonic/reantenna). Material changes to data use, permissions, sharing, or retention will be reflected here before release and may require renewed Reddit approval.
