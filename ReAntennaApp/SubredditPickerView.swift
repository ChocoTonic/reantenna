import SwiftUI

struct SubredditPickerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var subreddit = ""
    @State private var validationMessage: String?
    @State private var isOpening = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Go to Subreddit", showsBack: true)

            Form {
                Section {
                    HStack(spacing: 6) {
                        Text("/r/")
                            .foregroundStyle(.secondary)
                        TextField("subreddit", text: $subreddit)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($isNameFocused)
                            .onSubmit(openSubreddit)
                    }

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Use 2–21 letters, numbers, or underscores.")
                }

                Button(action: openSubreddit) {
                    HStack {
                        Spacer()
                        if isOpening {
                            ProgressView()
                        } else {
                            Text("Open Subreddit")
                        }
                        Spacer()
                    }
                }
                .disabled(isOpening || subreddit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color.reAntennaBackground)
        .onAppear { isNameFocused = true }
    }

    private func openSubreddit() {
        guard !isOpening else { return }
        isOpening = true
        validationMessage = nil
        Task {
            validationMessage = await model.openSubreddit(named: subreddit)
            isOpening = false
        }
    }
}
