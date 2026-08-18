import SwiftUI

struct RedditAccountView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Reddit Account", showsBack: true)

            Form {
                Section("Connection") {
                    LabeledContent("Status", value: model.redditConnectionState.description)
                    LabeledContent(
                        "API client",
                        value: model.isRedditOAuthConfigured ? "Configured" : "Approval required"
                    )
                    LabeledContent("Permissions", value: model.redditRequestedScopes)

                    if model.isRedditConnected {
                        Button("Disconnect Reddit", role: .destructive) {
                            Task { await model.disconnectReddit() }
                        }
                    } else {
                        Button("Connect Reddit") {
                            Task { await model.connectReddit() }
                        }
                        .disabled(!model.isRedditOAuthConfigured || model.isAuthenticatingReddit)
                    }
                }

                if !model.isRedditOAuthConfigured {
                    Section("Next owner step") {
                        Text("Request noncommercial Reddit Data API approval, create an installed-app OAuth client, and register the exact redirect URI reantenna://oauth.")
                        Text("Then provide the client ID and Reddit contact username. Installed apps do not use a client secret.")
                    }
                }

                Section("Security") {
                    Text("The authorization page opens in Apple's authentication session. A random state value protects the callback, access and refresh tokens are stored in this device's Keychain, and disconnect attempts token revocation before deleting local credentials.")
                    Text("No password, token, or historic Antenna credential is stored in project files or UserDefaults.")
                }

                if let message = model.redditConnectionError {
                    Section("Last error") {
                        Text(message).foregroundStyle(.red)
                    }
                }
            }
        }
    }
}
