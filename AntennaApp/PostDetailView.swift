import SwiftUI
import AntennaCore

struct PostDetailView: View {
    let postID: String

    @EnvironmentObject private var model: AppModel
    @State private var page: ThreadPage?
    @State private var loadError: String?
    @State private var collapsedIDs: Set<String> = []
    @State private var currentRootIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: page?.post.title ?? "Post", showsBack: true) {
                Button(action: model.toggleMenu) {
                    Image(systemName: "sidebar.right")
                        .frame(width: 30, height: 28)
                }
                .buttonStyle(.plain)
            }

            Group {
                if let page {
                    thread(page)
                } else if let loadError {
                    ContentUnavailableView(
                        "Post unavailable",
                        systemImage: "exclamationmark.bubble",
                        description: Text(loadError)
                    )
                } else {
                    ProgressView("Loading discussion…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task(id: postID) { await load() }
    }

    private func thread(_ page: ThreadPage) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    PostHeader(post: page.post)
                    commentSortBar(page.comments)

                    ForEach(visibleComments(from: page.comments)) { item in
                        CommentRow(
                            item: item,
                            isCollapsed: collapsedIDs.contains(item.id),
                            quickTapCollapses: model.preferences.quickTapCollapsesComments,
                            toggleCollapsed: { toggleCollapsed(item.comment) }
                        )
                        .id(item.id)
                    }

                    if model.preferences.showNextPost {
                        Button {
                            if let next = model.posts.drop(while: { $0.id != postID }).dropFirst().first {
                                model.path[model.path.count - 1] = .post(next.id)
                            }
                        } label: {
                            Label("Next post", systemImage: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if page.comments.count > 1 {
                    nextCommentControl(comments: page.comments, proxy: proxy)
                }
            }
        }
    }

    private func commentSortBar(_ comments: [Comment]) -> some View {
        HStack {
            Text("\(comments.count) root comments")
            Spacer()

            Button {
                toggleAllChildComments(comments)
            } label: {
                Label(
                    allChildrenCollapsed(in: comments) ? "expand" : "children",
                    systemImage: allChildrenCollapsed(in: comments)
                        ? "rectangle.expand.vertical"
                        : "rectangle.compress.vertical"
                )
                .font(.system(size: 10, weight: .medium))
                .frame(minWidth: 62, minHeight: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                allChildrenCollapsed(in: comments)
                    ? "Expand all comments"
                    : "Collapse all child comments"
            )

            Menu("best") {
                Button("Best") {}
                Button("Top") {}
                Button("New") {}
                Button("Controversial") {}
                Divider()
                Button("Collapse all child comments") {
                    collapseAllChildComments(comments)
                }
                Button("Expand all comments") {
                    expandAllComments()
                }
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .frame(height: 29)
        .background(AppTheme.secondaryBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }

    private func nextCommentControl(comments: [Comment], proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            Button {
                currentRootIndex = max(currentRootIndex - 1, 0)
                scrollToCurrentRoot(comments, proxy: proxy)
            } label: {
                Image(systemName: "chevron.up").frame(width: 44, height: 34)
            }
            Button {
                currentRootIndex = min(currentRootIndex + 1, comments.count - 1)
                scrollToCurrentRoot(comments, proxy: proxy)
            } label: {
                Image(systemName: "chevron.down").frame(width: 44, height: 34)
            }
            Text("root \(currentRootIndex + 1)/\(comments.count)")
                .font(.system(size: 10))
                .padding(.trailing, 10)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }

    private func visibleComments(from comments: [Comment]) -> [VisibleComment] {
        CommentTraversal.visibleComments(from: comments, collapsedIDs: collapsedIDs)
    }

    private func toggleCollapsed(_ comment: Comment) {
        guard !comment.children.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.16)) {
            if collapsedIDs.contains(comment.id) {
                collapsedIDs.remove(comment.id)
            } else {
                collapsedIDs.insert(comment.id)
            }
        }
    }

    private func allChildrenCollapsed(in comments: [Comment]) -> Bool {
        let rootBranches = Set(comments.filter { !$0.children.isEmpty }.map(\.id))
        return !rootBranches.isEmpty && rootBranches.isSubset(of: collapsedIDs)
    }

    private func toggleAllChildComments(_ comments: [Comment]) {
        if allChildrenCollapsed(in: comments) {
            expandAllComments()
        } else {
            collapseAllChildComments(comments)
        }
    }

    private func collapseAllChildComments(_ comments: [Comment]) {
        withAnimation(.easeOut(duration: 0.18)) {
            collapsedIDs.formUnion(CommentTraversal.collapsibleIDs(in: comments))
        }
    }

    private func expandAllComments() {
        withAnimation(.easeOut(duration: 0.18)) {
            collapsedIDs.removeAll()
        }
    }

    private func scrollToCurrentRoot(_ comments: [Comment], proxy: ScrollViewProxy) {
        guard comments.indices.contains(currentRootIndex) else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            proxy.scrollTo(comments[currentRootIndex].id, anchor: .top)
        }
    }

    private func load() async {
        do {
            page = try await model.service.thread(id: postID)
            loadError = nil
            if
                model.preferences.collapseChildCommentsByDefault,
                let comments = page?.comments
            {
                collapsedIDs = CommentTraversal.collapsibleIDs(in: comments)
            } else {
                collapsedIDs.removeAll()
            }
            currentRootIndex = 0
        } catch {
            loadError = "The discussion could not be loaded."
        }
    }
}

private struct PostHeader: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.system(size: 15, weight: .semibold))
                Text("r/\(post.subreddit) · \(post.age) · \(post.author) · \(post.domain)")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
            }
            .padding(8)

            if let body = post.body {
                Text(body)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(AppTheme.secondaryBackground)
            } else {
                PostHero(kind: post.kind)
            }

            HStack(spacing: 0) {
                postAction("arrow.up", label: "Upvote")
                postAction("arrow.down", label: "Downvote")
                postAction("bubble.left", label: "Reply")
                postAction("square.and.arrow.up", label: "Share")
                postAction("ellipsis", label: "More")
            }
            .frame(height: 38)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }

    private func postAction(_ icon: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct PostHero: View {
    let kind: PostKind

    var body: some View {
        ZStack {
            LinearGradient(
                colors: heroColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 58, weight: .thin))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.9))
        }
        .aspectRatio(16 / 10, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private var label: String {
        switch kind {
        case .image: "Image preview"
        case .video: "Video preview"
        case .link: "Link preview"
        case .text: "Self post"
        case .gallery: "Gallery preview"
        }
    }

    private var heroColors: [Color] {
        switch kind {
        case .image: [.indigo, .purple, .black]
        case .video: [.red, .orange, .black]
        case .link: [.blue, .teal, .black]
        case .text: [.gray, .black]
        case .gallery: [.teal, .purple, .black]
        }
    }
}

private struct CommentRow: View {
    let item: VisibleComment
    let isCollapsed: Bool
    let quickTapCollapses: Bool
    let toggleCollapsed: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            depthGuides
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(item.comment.author)
                        .foregroundStyle(item.comment.isOriginalPoster ? AppTheme.mutedBlue : .primary)
                    if item.comment.isOriginalPoster {
                        Text("OP")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .background(AppTheme.mutedBlue)
                    }
                    Text("\(item.comment.score.abbreviated) · \(item.comment.age)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !item.comment.children.isEmpty {
                        Image(systemName: isCollapsed ? "plus.square" : "minus.square")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 10.5, weight: .medium))

                Text(item.comment.body)
                    .font(.system(size: 13.5))
                    .fixedSize(horizontal: false, vertical: true)

                if item.hiddenChildCount > 0 {
                    Text("\(item.hiddenChildCount) hidden replies")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(AppTheme.mutedBlue)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 7)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if quickTapCollapses { toggleCollapsed() }
        }
        .contextMenu {
            Button("Upvote", systemImage: "arrow.up") {}
            Button("Reply", systemImage: "arrowshape.turn.up.left") {}
            Button("Collapse", systemImage: "rectangle.compress.vertical") { toggleCollapsed() }
            Button("Copy text", systemImage: "doc.on.doc") {}
            Button("Filter this", systemImage: "line.3.horizontal.decrease.circle") {}
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }

    private var depthGuides: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(item.depth, 8), id: \.self) { depth in
                Rectangle()
                    .fill(guideColor(depth))
                    .frame(width: 2)
            }
        }
        .padding(.leading, item.depth == 0 ? 0 : 4)
    }

    private func guideColor(_ depth: Int) -> Color {
        let colors: [Color] = [.blue, .orange, .green, .purple, .pink, .teal]
        return colors[depth % colors.count].opacity(0.65)
    }
}
