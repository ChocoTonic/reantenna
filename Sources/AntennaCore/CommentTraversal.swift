import Foundation

public struct VisibleComment: Identifiable, Hashable, Sendable {
    public let comment: Comment
    public let depth: Int
    public let hiddenChildCount: Int

    public var id: String { comment.id }

    public init(comment: Comment, depth: Int, hiddenChildCount: Int = 0) {
        self.comment = comment
        self.depth = depth
        self.hiddenChildCount = hiddenChildCount
    }
}

public enum CommentTraversal {
    public static func visibleComments(
        from roots: [Comment],
        collapsedIDs: Set<String>
    ) -> [VisibleComment] {
        var result: [VisibleComment] = []

        func append(_ comment: Comment, depth: Int) {
            let isCollapsed = collapsedIDs.contains(comment.id)
            result.append(
                VisibleComment(
                    comment: comment,
                    depth: depth,
                    hiddenChildCount: isCollapsed ? descendantCount(of: comment) : 0
                )
            )
            guard !isCollapsed else { return }
            for child in comment.children {
                append(child, depth: depth + 1)
            }
        }

        for root in roots {
            append(root, depth: 0)
        }
        return result
    }

    public static func descendantCount(of comment: Comment) -> Int {
        comment.children.reduce(0) { total, child in
            total + 1 + descendantCount(of: child)
        }
    }

    public static func rootIDs(in comments: [Comment]) -> [String] {
        comments.map(\.id)
    }

    public static func collapsibleIDs(in comments: [Comment]) -> Set<String> {
        var result: Set<String> = []

        func collect(_ comment: Comment) {
            if !comment.children.isEmpty {
                result.insert(comment.id)
                comment.children.forEach(collect)
            }
        }

        comments.forEach(collect)
        return result
    }
}
