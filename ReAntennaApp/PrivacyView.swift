import SwiftUI

struct PrivacyView: View {
    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Privacy", showsBack: true)

            Form {
                Section("Collection") {
                    Text("ReAntenna has no developer-operated server, ads, analytics, tracking, data sales, or AI training. In fixture mode it does not access Reddit.")
                    Text("After explicit OAuth consent in an approved live build, it processes account identity, feeds, posts, comments, and subscriptions only to display the requested reading experience.")
                }

                Section("On this device") {
                    Text("OAuth tokens are stored in Keychain. Preferences and up to 100 recently viewed post IDs are stored locally. Reddit API requests use an ephemeral, non-caching session. Media cache is user-controlled and purged at least every 48 hours when the app launches.")
                }

                Section("Your controls") {
                    Text("History and media cache can be cleared separately in Settings. The Reddit Account screen can revoke authorization when possible and delete OAuth credentials, history, and cached responses from this device.")
                }

                Section("Policy") {
                    Link(
                        "Read the complete privacy policy",
                        destination: URL(string: "https://github.com/ChocoTonic/reantenna/blob/main/PRIVACY.md")!
                    )
                    Text("Contact: u/giddiness-uneasy or the public repository issue tracker.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
