import SwiftUI
import AntennaCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var horizontalDrag: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                Color.reAntennaBackground.ignoresSafeArea()

                SwipeMenuView()
                    .frame(width: min(proxy.size.width * 0.84, 390))
                    .opacity(model.isMenuOpen ? 1 : 0)
                    .accessibilityHidden(!model.isMenuOpen)

                navigationContent
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .background(Color.reAntennaBackground)
                    .offset(x: contentOffset(for: proxy.size.width))
                    .shadow(
                        color: .black.opacity(model.isMenuOpen ? 0.28 : 0),
                        radius: 12,
                        x: -5
                    )
                    .overlay {
                        if model.isMenuOpen {
                            Color.black.opacity(0.001)
                                .contentShape(Rectangle())
                                .onTapGesture { model.closeMenu() }
                                .accessibilityLabel("Close menu")
                        }
                    }
                    .simultaneousGesture(globalSwipe(in: proxy.size.width))
            }
            .clipped()
        }
        .task { await model.start() }
    }

    private var navigationContent: some View {
        NavigationStack(path: $model.path) {
            FeedView()
                .reAntennaNavigationChromeHidden()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case let .post(id):
                        PostDetailView(postID: id)
                            .reAntennaNavigationChromeHidden()
                    case .settings:
                        SettingsView()
                            .reAntennaNavigationChromeHidden()
                    case .redditAccount:
                        RedditAccountView()
                            .reAntennaNavigationChromeHidden()
                    case .privacy:
                        PrivacyView()
                            .reAntennaNavigationChromeHidden()
                    case let .listing(title):
                        PlaceholderListingView(title: title)
                            .reAntennaNavigationChromeHidden()
                    }
                }
        }
    }

    private func contentOffset(for width: CGFloat) -> CGFloat {
        let openOffset = -min(width * 0.84, 390)
        return (model.isMenuOpen ? openOffset : 0) + horizontalDrag
    }

    private func globalSwipe(in width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .global)
            .onChanged { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) * 1.4 else { return }

                if model.isMenuOpen {
                    horizontalDrag = min(max(horizontal, -30), min(width * 0.84, 390))
                } else if horizontal > 0, !model.path.isEmpty {
                    horizontalDrag = min(horizontal, width * 0.45)
                } else if horizontal < -80 {
                    // A long leftward pull opens the global menu. Short row
                    // swipes remain available for contextual post actions.
                    horizontalDrag = max(horizontal * 0.22, -45)
                }
            }
            .onEnded { value in
                defer {
                    withAnimation(.snappy(duration: 0.22)) { horizontalDrag = 0 }
                }

                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) * 1.4 else { return }

                if model.isMenuOpen, horizontal > 65 {
                    model.closeMenu()
                } else if !model.isMenuOpen, horizontal > 95, !model.path.isEmpty {
                    model.goBack()
                } else if !model.isMenuOpen, horizontal < -150 {
                    model.toggleMenu()
                }
            }
    }
}
