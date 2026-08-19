import SwiftUI
import AntennaCore

struct SwipeMenuView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                menuSection("Shortcuts") {
                    row("Add new", icon: "plus") { model.selectRoute(.listing("Add Shortcut")) }
                    row("Edit", icon: "pencil") { model.selectRoute(.listing("Edit Shortcuts")) }
                    row("Front · Hot", icon: "bolt") { model.closeMenu() }
                }

                menuSection("General") {
                    row("Search", icon: "magnifyingglass") { model.selectRoute(.listing("Search")) }
                    row("Messages", icon: "envelope") { model.selectRoute(.listing("Messages")) }
                    row("Saved", icon: "tray.and.arrow.down") { model.selectRoute(.listing("Saved")) }
                    row("Overview", icon: "list.bullet.rectangle") { model.selectRoute(.listing("Overview")) }
                    row("/r  Subreddit", icon: "textformat") { model.selectRoute(.subredditPicker) }
                    row("/u  User", icon: "person") { model.selectRoute(.listing("Go to User")) }
                    row("Night mode", icon: "moon") { toggleNightMode() }
                    row("Home", icon: "house") { goHome() }
                    row("Settings", icon: "gearshape") { model.selectRoute(.settings) }
                    row("Back", icon: "chevron.backward") { goBack() }
                }

                menuSection("Accounts") {
                    if model.isRedditConnected {
                        ForEach(model.accounts) { account in
                            row(account.username, icon: "person.crop.circle", accessory: "checkmark") {
                                model.selectRoute(.redditAccount)
                            }
                        }
                    } else {
                        row("Fixture mode", icon: "testtube.2") { model.closeMenu() }
                    }
                    row(
                        model.isRedditConnected ? "Manage Reddit account" : "Connect Reddit",
                        icon: "person.badge.key"
                    ) { model.selectRoute(.redditAccount) }
                }

                menuSection("User") {
                    row("Profile", icon: "person.text.rectangle") { model.selectRoute(.listing("Profile")) }
                    row("Reddit account", icon: "person.badge.plus") { model.selectRoute(.redditAccount) }
                }
            }
            .padding(.bottom, 18)
        }
        .background(Color.reAntennaSecondaryBackground)
        .overlay(alignment: .leading) {
            Rectangle().fill(AppTheme.separator).frame(width: 0.5)
        }
    }

    @ViewBuilder
    private func menuSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section {
            content()
        } header: {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppTheme.metadata)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 20)
                .background(Color.reAntennaTertiaryBackground)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppTheme.separator).frame(height: 0.5)
                }
        }
    }

    private func row(
        _ title: String,
        icon: String,
        accessory: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.metadata)
                    .frame(width: 17)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer()
                if let accessory {
                    Image(systemName: accessory)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedBlue)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 33)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppTheme.separator).frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleNightMode() {
        model.preferences.theme = model.preferences.theme == .night ? .day : .night
    }

    private func goHome() {
        model.path.removeAll()
        model.closeMenu()
    }

    private func goBack() {
        model.goBack()
        model.closeMenu()
    }
}
