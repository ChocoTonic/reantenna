import SwiftUI

struct TopBar<Trailing: View>: View {
    let title: String
    var showsBack = false
    @ViewBuilder var trailing: () -> Trailing

    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            if showsBack {
                Button(action: model.goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 26, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 8)
        .frame(height: 34)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 0.5)
        }
    }
}

extension TopBar where Trailing == EmptyView {
    init(title: String, showsBack: Bool = false) {
        self.title = title
        self.showsBack = showsBack
        trailing = { EmptyView() }
    }
}
