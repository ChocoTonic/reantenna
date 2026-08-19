import SwiftUI
import AntennaCore

struct FeedView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: model.selectedFeed) {
                HStack(spacing: 2) {
                    Button(action: cycleLayout) {
                        Image(systemName: layoutIcon)
                            .font(.system(size: 12))
                            .frame(width: 25, height: 27)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change feed layout")

                    Menu {
                        ForEach(FeedSort.allCases, id: \.self) { sort in
                            Button(sort.title) { model.setSort(sort) }
                        }
                    } label: {
                        Text(model.sort.rawValue)
                            .font(.system(size: 10.5))
                            .frame(minWidth: 34, minHeight: 27)
                    }
                    .buttonStyle(.plain)

                    Button(action: model.toggleMenu) {
                        Image(systemName: "sidebar.right")
                            .font(.system(size: 12))
                            .frame(width: 25, height: 27)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open swipe menu")
                }
            }

            if let error = model.errorMessage, model.posts.isEmpty {
                ContentUnavailableView(
                    "Feed unavailable",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error)
                )
            } else if model.isLoading, model.posts.isEmpty {
                ProgressView("Loading \(model.selectedFeed)…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    if model.isUsingFixtureData {
                        Label("Fixture data — actions are local previews", systemImage: "shippingbox")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(AppTheme.secondaryBackground)
                    }
                    feed
                }
            }
        }
        .background(Color.reAntennaBackground)
        .alert("Reddit action failed", isPresented: writeErrorPresented) {
            Button("OK", role: .cancel) { model.writeErrorMessage = nil }
        } message: {
            Text(model.writeErrorMessage ?? "Unknown error")
        }
    }

    @ViewBuilder
    private var feed: some View {
        if model.preferences.layout == .grid {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 155), spacing: 1)],
                    spacing: 1
                ) {
                    ForEach(model.posts) { post in
                        GridPostCell(post: post)
                            .onTapGesture { model.openPost(post) }
                    }
                }
            }
            .refreshable { await model.refresh() }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.posts) { post in
                        DensePostRow(
                            post: post,
                            layout: model.preferences.layout,
                            textScale: model.preferences.textScale,
                            open: { model.openPost(post) },
                            vote: { direction in
                                Task {
                                    let requested = post.vote == direction ? VoteState.none : direction
                                    guard await model.vote(fullname: "t3_\(post.id)", direction: requested) else { return }
                                    model.updatePost(id: post.id) { item in
                                        let old = item.vote.rawValue
                                        item.vote = requested
                                        item.score += requested.rawValue - old
                                    }
                                }
                            },
                            toggleSaved: {
                                Task {
                                    let requested = !post.isSaved
                                    guard await model.setSaved(fullname: "t3_\(post.id)", isSaved: requested) else { return }
                                    model.updatePost(id: post.id) { $0.isSaved = requested }
                                }
                            },
                            isVotePending: model.isWritePending("vote:t3_\(post.id)"),
                            isSavePending: model.isWritePending("save:t3_\(post.id)")
                        )
                    }
                }
            }
            .refreshable { await model.refresh() }
        }
    }

    private var writeErrorPresented: Binding<Bool> {
        Binding(
            get: { model.writeErrorMessage != nil },
            set: { if !$0 { model.writeErrorMessage = nil } }
        )
    }

    private var layoutIcon: String {
        switch model.preferences.layout {
        case .compact: "list.bullet"
        case .thumbnail: "list.bullet.rectangle"
        case .grid: "square.grid.2x2"
        }
    }

    private func cycleLayout() {
        switch model.preferences.layout {
        case .compact: model.preferences.layout = .thumbnail
        case .thumbnail: model.preferences.layout = .grid
        case .grid: model.preferences.layout = .compact
        }
    }
}

private struct DensePostRow: View {
    let post: Post
    let layout: FeedLayout
    let textScale: Double
    let open: () -> Void
    let vote: (VoteState) -> Void
    let toggleSaved: () -> Void
    let isVotePending: Bool
    let isSavePending: Bool

    @State private var isActionsOpen = false
    @State private var dragOffset: CGFloat = 0

    private let actionsWidth: CGFloat = 116

    var body: some View {
        ZStack(alignment: .trailing) {
            actionStrip
            rowContent
                .background(Color.reAntennaBackground)
                .offset(x: (isActionsOpen ? -actionsWidth : 0) + dragOffset)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isActionsOpen {
                        withAnimation(.snappy) { isActionsOpen = false }
                    } else {
                        open()
                    }
                }
                .gesture(rowSwipe)
                .contextMenu { contextActions }
        }
        .clipped()
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 1 / 3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Open") { open() }
        .accessibilityAction(named: "Save") { toggleSaved() }
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 6) {
            if layout == .thumbnail {
                PostThumbnail(kind: post.kind, size: 50)
            } else {
                PostThumbnail(kind: post.kind, size: 30)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(post.title)
                        .font(.system(size: 12 * textScale, weight: .regular))
                        .foregroundStyle(post.isRead ? AppTheme.visitedTitle : AppTheme.title)
                        .lineLimit(layout == .compact ? 2 : 3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let flair = post.flair {
                        Text(flair)
                            .font(.system(size: 7.5, weight: .semibold))
                            .foregroundStyle(AppTheme.purple)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 4) {
                    Text(post.score.abbreviated)
                        .foregroundStyle(post.vote == .up ? AppTheme.orange : AppTheme.metadata)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundStyle(post.vote == .up ? AppTheme.orange : AppTheme.faintMetadata)
                    Text("\(post.commentCount.abbreviated)c")
                    Text("·")
                    Text(post.domain)
                    if post.isSaved { Image(systemName: "bookmark.fill") }
                    if post.isNSFW { Text("NSFW").foregroundStyle(.red) }
                }
                .font(.system(size: 8.5 * textScale))
                .foregroundStyle(AppTheme.metadata)
                .lineLimit(1)

                Text("\(post.age) by \(post.author) · r/\(post.subreddit)")
                    .font(.system(size: 7.8 * textScale))
                    .foregroundStyle(AppTheme.faintMetadata)
                    .lineLimit(1)
            }
            .padding(.vertical, 3)
        }
        .padding(.horizontal, 5)
        .frame(minHeight: layout == .thumbnail ? 58 : 43)
    }

    private var actionStrip: some View {
        HStack(spacing: 0) {
            actionButton("arrow.up", color: AppTheme.orange) {
                vote(.up)
                closeActions()
            }
            .disabled(isVotePending)
            actionButton(post.isSaved ? "bookmark.slash" : "bookmark", color: AppTheme.mutedBlue) {
                toggleSaved()
                closeActions()
            }
            .disabled(isSavePending)
        }
        .frame(width: actionsWidth)
    }

    private func actionButton(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var contextActions: some View {
        Button("Upvote", systemImage: "arrow.up") { vote(.up) }.disabled(isVotePending)
        Button("Downvote", systemImage: "arrow.down") { vote(.down) }.disabled(isVotePending)
        Button(post.isSaved ? "Unsave" : "Save", systemImage: "bookmark") { toggleSaved() }.disabled(isSavePending)
        ShareLink(
            item: redditURL,
            subject: Text(post.title),
            message: Text(post.title)
        ) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }

    private var rowSwipe: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.3 else { return }
                if isActionsOpen {
                    dragOffset = min(max(value.translation.width, -25), actionsWidth)
                } else {
                    dragOffset = max(min(value.translation.width, 15), -actionsWidth)
                }
            }
            .onEnded { value in
                let projected = value.predictedEndTranslation.width
                withAnimation(.snappy(duration: 0.2)) {
                    if isActionsOpen {
                        isActionsOpen = projected < actionsWidth * 0.45
                    } else {
                        isActionsOpen = projected < -55
                    }
                    dragOffset = 0
                }
            }
    }

    private func closeActions() {
        withAnimation(.snappy) { isActionsOpen = false }
    }

    private var redditURL: URL {
        URL(string: "https://www.reddit.com/comments/\(post.id)")!
    }
}

struct PostThumbnail: View {
    let kind: PostKind
    let size: CGFloat

    var body: some View {
        ZStack {
            AppTheme.secondaryBackground
            Image(systemName: kind.systemImage)
                .font(.system(size: size * 0.30, weight: .regular))
                .foregroundStyle(iconColor)
        }
        .frame(width: size, height: size)
        .overlay {
            Rectangle().stroke(AppTheme.separator, lineWidth: 1 / 3)
        }
    }

    private var iconColor: Color {
        switch kind {
        case .image, .gallery: AppTheme.purple
        case .video: AppTheme.orange
        case .link: AppTheme.mutedBlue
        case .text: AppTheme.metadata
        }
    }
}

private struct GridPostCell: View {
    let post: Post

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PostThumbnail(kind: post.kind, size: 220)
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(post.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3)
                HStack(spacing: 7) {
                    Label(post.score.abbreviated, systemImage: "arrow.up")
                    Label(post.commentCount.abbreviated, systemImage: "bubble.left")
                }
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            .padding(7)
        }
        .aspectRatio(0.92, contentMode: .fit)
        .contentShape(Rectangle())
    }
}
