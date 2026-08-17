import SwiftUI
import AntennaCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmationMessage: String?

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

                    if model.preferences.limitCellularDownloads {
                        Picker("Maximum download", selection: cellularDownloadLimit) {
                            Text("2 MB").tag(2)
                            Text("5 MB").tag(5)
                            Text("10 MB").tag(10)
                            Text("25 MB").tag(25)
                        }
                    }

                    Picker("Default browser", selection: defaultBrowser) {
                        ForEach(BrowserPreference.allCases, id: \.self) { browser in
                            Text(browser.rawValue).tag(browser)
                        }
                    }

                    Picker("Image cache", selection: imageCacheLimit) {
                        Text("64 MB").tag(64)
                        Text("128 MB").tag(128)
                        Text("256 MB").tag(256)
                        Text("512 MB").tag(512)
                    }

                    Text("Link preview, browser, and cellular rules are saved now and will be applied when remote media and web links are connected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Navigation") {
                    Toggle("Keep recently viewed history", isOn: historyRetention)
                    Toggle("Show next post", isOn: preference(\.showNextPost))
                    Toggle("Tap comment to collapse", isOn: preference(\.quickTapCollapsesComments))
                    Toggle(
                        "Collapse child comments by default",
                        isOn: preference(\.collapseChildCommentsByDefault)
                    )
                    Picker("Pagination", selection: pagination) {
                        ForEach(PaginationPreference.allCases, id: \.self) { pagination in
                            Text(pagination.rawValue).tag(pagination)
                        }
                    }
                    LabeledContent("Swipe back", value: "Anywhere")
                    Text("Pagination mode is saved for the live Reddit feed; fixture feeds currently fit on one page.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Accounts and privacy") {
                    LabeledContent("Reddit connection", value: "Fixture mode")
                    LabeledContent("Biometrics", value: model.biometricAvailabilityDescription)
                    LabeledContent("App lock", value: "Not implemented")
                        .foregroundStyle(.secondary)
                    Text("OAuth account management and biometric locking are unavailable until live account support is implemented.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Button("Clear read history") {
                        model.clearReadHistory()
                        confirmationMessage = "Read history cleared."
                    }
                    .disabled(model.recentlyViewedPostIDs.isEmpty && !model.posts.contains(where: \.isRead))

                    Button("Clear media cache") {
                        model.clearMediaCache()
                        confirmationMessage = "Media cache cleared."
                    }
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
        .alert(
            "Threadline",
            isPresented: Binding(
                get: { confirmationMessage != nil },
                set: { if !$0 { confirmationMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { confirmationMessage = nil }
        } message: {
            Text(confirmationMessage ?? "")
        }
    }

    private func preference<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { model.preferences[keyPath: keyPath] },
            set: { value in model.preferences[keyPath: keyPath] = value }
        )
    }

    private var defaultBrowser: Binding<BrowserPreference> {
        Binding(
            get: { model.defaultBrowser },
            set: { model.defaultBrowser = $0 }
        )
    }

    private var pagination: Binding<PaginationPreference> {
        Binding(
            get: { model.pagination },
            set: { model.pagination = $0 }
        )
    }

    private var cellularDownloadLimit: Binding<Int> {
        Binding(
            get: { model.cellularDownloadLimitMB },
            set: { model.cellularDownloadLimitMB = $0 }
        )
    }

    private var imageCacheLimit: Binding<Int> {
        Binding(
            get: { model.imageCacheLimitMB },
            set: { model.imageCacheLimitMB = $0 }
        )
    }

    private var historyRetention: Binding<Bool> {
        Binding(
            get: { model.preferences.keepHistory },
            set: { keepHistory in model.setHistoryRetention(keepHistory) }
        )
    }
}
