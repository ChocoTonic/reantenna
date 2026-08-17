import SwiftUI

struct TopBar<Trailing: View>: View {
    let title: String
    var showsBack = false
    @ViewBuilder var trailing: () -> Trailing

    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 3) {
            if showsBack {
                Button(action: model.goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 22, height: 27)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.title)
                .lineLimit(1)

            Spacer(minLength: 4)
            trailing()
        }
        .padding(.horizontal, 6)
        .frame(height: 29)
        .background(AppTheme.toolbarBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.separator).frame(height: 1 / 3)
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
