import SwiftUI

enum AppTheme {
    static let orange = Color(red: 0.92, green: 0.35, blue: 0.12)
    static let purple = Color(red: 0.46, green: 0.36, blue: 0.68)
    static let mutedBlue = Color(red: 0.28, green: 0.48, blue: 0.68)
    static let separator = Color.primary.opacity(0.13)
    static let secondaryBackground = Color.primary.opacity(0.045)
}

extension Int {
    var abbreviated: String {
        switch abs(self) {
        case 1_000_000...:
            String(format: "%.1fm", Double(self) / 1_000_000)
        case 1_000...:
            String(format: "%.1fk", Double(self) / 1_000)
        default:
            formatted()
        }
    }
}

extension Color {
    static var threadlineBackground: Color {
#if os(iOS)
        Color(uiColor: .systemBackground)
#else
        Color(nsColor: .windowBackgroundColor)
#endif
    }

    static var threadlineSecondaryBackground: Color {
#if os(iOS)
        Color(uiColor: .secondarySystemBackground)
#else
        Color(nsColor: .controlBackgroundColor)
#endif
    }

    static var threadlineTertiaryBackground: Color {
#if os(iOS)
        Color(uiColor: .tertiarySystemBackground)
#else
        Color(nsColor: .underPageBackgroundColor)
#endif
    }
}

extension View {
    @ViewBuilder
    func threadlineNavigationChromeHidden() -> some View {
#if os(iOS)
        toolbar(.hidden, for: .navigationBar)
#else
        self
#endif
    }
}
