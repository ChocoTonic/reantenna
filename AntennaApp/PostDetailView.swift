import SwiftUI
import AntennaCore
#if os(iOS)
import UIKit
#endif

struct PostDetailView: View {
    let postID: String

    @EnvironmentObject private var model: AppModel
    @State private var page: ThreadPage?
    @State private var loadError: String?
    @State private var collapsedIDs: Set<String> = []
    @State private var currentRootIndex = 0
    @State private var commentSort: CommentSort = .best

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
        let comments = sortedComments(page.comments)

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    PostHeader(post: page.post)
                    commentControls(comments)

                    ForEach(visibleComments(from: comments)) { item in
                        CommentRow(
                            item: item,
                            isCollapsed: collapsedIDs.contains(item.id),
                            quickTapCollapses: model.preferences.quickTapCollapsesComments,
                            toggleCollapsed: { toggleCollapsed(item.comment) }
                        )
                        .id(item.id)
                    }

                    if comments.isEmpty {
                        Text("No comments yet")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                    }

                    if model.preferences.showNextPost {
                        Button {
                            if let next = model.posts.drop(while: { $0.id != postID }).dropFirst().first {
                                model.path[model.path.count - 1] = .post(next.id)
                            }
                        } label: {
                            Label("Show next post", systemImage: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .background(AppTheme.secondaryBackground)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if comments.count > 1 {
                    rootNavigation(comments: comments, proxy: proxy)
                }
            }
        }
    }

    private func commentControls(_ comments: [Comment]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("\(comments.count) comments")
                    .fontWeight(.semibold)
                Spacer()
                Menu {
                    ForEach(CommentSort.allCases) { sort in
                        Button {
                            commentSort = sort
                            currentRootIndex = 0
                        } label: {
                            if commentSort == sort {
                                Label(sort.title, systemImage: "checkmark")
                            } else {
                                Text(sort.title)
                            }
                        }
                    }
                } label: {
                    Label(commentSort.title, systemImage: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Comment sort, \(commentSort.title)")
            }
            .font(.system(size: 10.5))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .frame(height: 27)

            HStack(spacing: 0) {
                Button {
                    collapseAllChildComments(comments)
                } label: {
                    Label("Collapse Children", systemImage: "rectangle.compress.vertical")
                        .frame(maxWidth: .infinity, minHeight: 30)
                }
                .disabled(comments.allSatisfy(\.children.isEmpty))

                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(width: 0.5, height: 18)

                Button {
                    expandAllComments()
                } label: {
                    Label("Expand All", systemImage: "rectangle.expand.vertical")
                        .frame(maxWidth: .infinity, minHeight: 30)
                }
                .disabled(collapsedIDs.isEmpty)
            }
            .font(.system(size: 10.5, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.mutedBlue)
        }
        .background(AppTheme.secondaryBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }

    private func rootNavigation(comments: [Comment], proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            Text("\(currentRootIndex + 1)/\(comments.count)")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            Button {
                currentRootIndex = max(currentRootIndex - 1, 0)
                scrollToCurrentRoot(comments, proxy: proxy)
            } label: {
                Image(systemName: "chevron.up").frame(width: 38, height: 30)
            }
            .disabled(currentRootIndex == 0)
            Button {
                currentRootIndex = min(currentRootIndex + 1, comments.count - 1)
                scrollToCurrentRoot(comments, proxy: proxy)
            } label: {
                Image(systemName: "chevron.down").frame(width: 38, height: 30)
            }
            .disabled(currentRootIndex == comments.count - 1)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial)
        .overlay { Rectangle().stroke(AppTheme.separator, lineWidth: 0.5) }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private func sortedComments(_ comments: [Comment]) -> [Comment] {
        switch commentSort {
        case .best:
            comments
        case .top:
            comments.sorted { $0.score > $1.score }
        case .new:
            Array(comments.reversed())
        case .controversial:
            comments.sorted {
                abs($0.score) == abs($1.score)
                    ? $0.children.count > $1.children.count
                    : abs($0.score) < abs($1.score)
            }
        }
    }

    private func visibleComments(from comments: [Comment]) -> [VisibleComment] {
        CommentTraversal.visibleComments(from: comments, collapsedIDs: collapsedIDs)
    }

    private func toggleCollapsed(_ comment: Comment) {
        guard !comment.children.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.13)) {
            if collapsedIDs.contains(comment.id) {
                collapsedIDs.remove(comment.id)
            } else {
                collapsedIDs.insert(comment.id)
            }
        }
    }

    private func collapseAllChildComments(_ comments: [Comment]) {
        // Collapsing every root branch keeps each root visible while suppressing all descendants.
        withAnimation(.easeOut(duration: 0.15)) {
            collapsedIDs.formUnion(comments.filter { !$0.children.isEmpty }.map(\.id))
        }
    }

    private func expandAllComments() {
        withAnimation(.easeOut(duration: 0.15)) {
            collapsedIDs.removeAll()
        }
    }

    private func scrollToCurrentRoot(_ comments: [Comment], proxy: ScrollViewProxy) {
        guard comments.indices.contains(currentRootIndex) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(comments[currentRootIndex].id, anchor: .top)
        }
    }

    private func load() async {
        do {
            page = try await model.service.thread(id: postID)
            loadError = nil
            if model.preferences.collapseChildCommentsByDefault, let comments = page?.comments {
                collapsedIDs = Set(comments.filter { !$0.children.isEmpty }.map(\.id))
            } else {
                collapsedIDs.removeAll()
            }
            currentRootIndex = 0
        } catch {
            loadError = "The discussion could not be loaded."
        }
    }
}

private enum CommentSort: String, CaseIterable, Identifiable {
    case best
    case top
    case new
    case controversial

    var id: Self { self }
    var title: String { rawValue.capitalized }
}

private struct PostHeader: View {
    let post: Post

    @State private var vote: VoteState
    @State private var isSaved: Bool
    @State private var isHidden = false
    @State private var showsReply = false

    init(post: Post) {
        self.post = post
        _vote = State(initialValue: post.vote)
        _isSaved = State(initialValue: post.isSaved)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(post.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isHidden ? .secondary : .primary)
                HStack(spacing: 4) {
                    Text("r/\(post.subreddit)")
                        .foregroundStyle(AppTheme.purple)
                    Text("• \(post.age) • u/\(post.author) • \(post.domain)")
                }
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)

            if let body = post.body {
                Text(body)
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(AppTheme.secondaryBackground)
            } else if !isHidden {
                PostHero(kind: post.kind)
            }

            HStack(spacing: 0) {
                postAction(vote == .up ? "arrow.up.circle.fill" : "arrow.up", label: "Upvote", color: vote == .up ? AppTheme.orange : .secondary) {
                    vote = vote == .up ? .none : .up
                }
                postAction(vote == .down ? "arrow.down.circle.fill" : "arrow.down", label: "Downvote", color: vote == .down ? AppTheme.mutedBlue : .secondary) {
                    vote = vote == .down ? .none : .down
                }
                Text(adjustedScore.abbreviated)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(vote == .up ? AppTheme.orange : vote == .down ? AppTheme.mutedBlue : .secondary)
                    .frame(minWidth: 34)
                postAction("bubble.left", label: "Reply") { showsReply = true }
                ShareLink(item: post.title) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
                Menu {
                    Button(isSaved ? "Unsave" : "Save", systemImage: isSaved ? "bookmark.slash" : "bookmark") {
                        isSaved.toggle()
                    }
                    Button(isHidden ? "Show post" : "Hide post", systemImage: isHidden ? "eye" : "eye.slash") {
                        isHidden.toggle()
                    }
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "ellipsis")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 33)
            .background(AppTheme.secondaryBackground)
        }
        .sheet(isPresented: $showsReply) {
            ReplyComposer(title: "Reply to u/\(post.author)")
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }

    private var adjustedScore: Int {
        post.score + vote.rawValue - post.vote.rawValue
    }

    private func postAction(
        _ icon: String,
        label: String,
        color: Color = .secondary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
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
            LinearGradient(colors: heroColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 6) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 46, weight: .thin))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.9))
        }
        .aspectRatio(16 / 9, contentMode: .fit)
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

    @State private var vote: VoteState
    @State private var showsReply = false
    @State private var isFiltered = false
    @State private var copied = false

    init(
        item: VisibleComment,
        isCollapsed: Bool,
        quickTapCollapses: Bool,
        toggleCollapsed: @escaping () -> Void
    ) {
        self.item = item
        self.isCollapsed = isCollapsed
        self.quickTapCollapses = quickTapCollapses
        self.toggleCollapsed = toggleCollapsed
        _vote = State(initialValue: item.comment.vote)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(item.comment.author)
                    .foregroundStyle(item.comment.isOriginalPoster ? AppTheme.mutedBlue : .primary)
                if item.comment.isOriginalPoster {
                    Text("OP")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(AppTheme.mutedBlue)
                }
                Text("\(adjustedScore.abbreviated) • \(item.comment.age)")
                    .foregroundStyle(scoreColor)
                Spacer(minLength: 4)
                if copied {
                    Text("copied")
                        .foregroundStyle(AppTheme.mutedBlue)
                }
                if !item.comment.children.isEmpty {
                    Image(systemName: isCollapsed ? "plus.square" : "minus.square")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 9.5, weight: .medium))

            if isFiltered {
                Text("comment filtered")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundStyle(.secondary)
            } else {
                Text(item.comment.body)
                    .font(.system(size: 12.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if item.hiddenChildCount > 0 {
                Text("\(item.hiddenChildCount) hidden repl\(item.hiddenChildCount == 1 ? "y" : "ies")")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedBlue)
            }
        }
        .padding(.leading, 7 + CGFloat(min(item.depth, 10)) * 11)
        .padding(.trailing, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(scoreTint)
        .contentShape(Rectangle())
        .onTapGesture {
            if quickTapCollapses { toggleCollapsed() }
        }
        .contextMenu {
            Button(vote == .up ? "Remove upvote" : "Upvote", systemImage: "arrow.up") {
                vote = vote == .up ? .none : .up
            }
            Button("Reply", systemImage: "arrowshape.turn.up.left") { showsReply = true }
            if !item.comment.children.isEmpty {
                Button(isCollapsed ? "Expand" : "Collapse", systemImage: isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical") {
                    toggleCollapsed()
                }
            }
            Button("Copy text", systemImage: "doc.on.doc") { copyComment() }
            Button(isFiltered ? "Show comment" : "Filter this", systemImage: "line.3.horizontal.decrease.circle") {
                isFiltered.toggle()
            }
        }
        .sheet(isPresented: $showsReply) {
            ReplyComposer(title: "Reply to u/\(item.comment.author)")
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }

    private var adjustedScore: Int {
        item.comment.score + vote.rawValue - item.comment.vote.rawValue
    }

    private var scoreColor: Color {
        if vote == .up { return AppTheme.orange }
        if adjustedScore >= 100 { return .orange }
        if adjustedScore < 0 { return .red }
        return .secondary
    }

    private var scoreTint: Color {
        if adjustedScore >= 100 { return .orange.opacity(0.035) }
        if adjustedScore < 0 { return .red.opacity(0.035) }
        return .clear
    }

    private func copyComment() {
#if os(iOS)
        UIPasteboard.general.string = item.comment.body
#endif
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { copied = false }
        }
    }
}

private struct ReplyComposer: View {
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .padding(8)
                HStack(spacing: 18) {
                    Image(systemName: "bold")
                    Image(systemName: "italic")
                    Image(systemName: "link")
                    Image(systemName: "quote.opening")
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(AppTheme.secondaryBackground)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
