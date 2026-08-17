import SwiftUI
import AntennaCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Settings", showsBack: true)

            Form {
                Section("Look and feel") {
                    Picker("Theme", selection: preference(\.theme)) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }

                    Picker("Post listing", selection: preference(\.layout)) {
                        ForEach(FeedLayout.allCases, id: \.self) { layout in
                            Text(layout.rawValue.capitalized).tag(layout)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Text size")
                        Slider(value: preference(\.textScale), in: 0.85...1.35, step: 0.05)
                    }
                }

                Section("Links and media") {
                    Toggle("Preview links", isOn: preference(\.previewLinks))
                    Toggle("Limit cellular downloads", isOn: preference(\.limitCellularDownloads))
                    LabeledContent("Default browser", value: "Embedded Safari")
                    LabeledContent("Image cache", value: "256 MB")
                }

                Section("Navigation") {
                    Toggle("Keep recently viewed history", isOn: preference(\.keepHistory))
                    Toggle("Show next post", isOn: preference(\.showNextPost))
                    Toggle("Tap comment to collapse", isOn: preference(\.quickTapCollapsesComments))
                    Toggle(
                        "Collapse child comments by default",
                        isOn: preference(\.collapseChildCommentsByDefault)
                    )
                    LabeledContent("Pagination", value: "Automatic")
                    LabeledContent("Swipe back", value: "Anywhere")
                }

                Section("Accounts and privacy") {
                    LabeledContent("Reddit connection", value: "Fixture mode")
                    Toggle("Require Face ID", isOn: .constant(false))
                    NavigationLink("Manage accounts") {
                        Text("OAuth account management becomes available after Reddit API approval.")
                            .padding()
                    }
                }

                Section("Data") {
                    Button("Clear read history") {}
                    Button("Clear media cache") {}
                    LabeledContent("Analytics", value: "None")
                }

                Section("About") {
                    LabeledContent("Threadline", value: "Milestone 1")
                    Text("An independently written, gesture-first Reddit reader inspired by compact native clients.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func preference<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { model.preferences[keyPath: keyPath] },
            set: { value in model.preferences[keyPath: keyPath] = value }
        )
    }
}
