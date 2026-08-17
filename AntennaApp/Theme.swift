import SwiftUI

enum AppTheme {
    static let orange = Color(red: 0.92, green: 0.35, blue: 0.12)
    static let purple = adaptive(light: 0x68529A, dark: 0xA397C7)
    static let mutedBlue = adaptive(light: 0x466F98, dark: 0x7899BA)
    static let title = adaptive(light: 0x244D75, dark: 0xB8C9D9)
    static let visitedTitle = adaptive(light: 0x725E87, dark: 0x9388A3)
    static let metadata = adaptive(light: 0x717171, dark: 0x929292)
    static let faintMetadata = adaptive(light: 0x999999, dark: 0x717171)
    static let separator = adaptive(light: 0xD2D2D2, dark: 0x303030)
    static let secondaryBackground = adaptive(light: 0xF4F4F4, dark: 0x171717)
    static let toolbarBackground = adaptive(light: 0xF7F7F7, dark: 0x111111)
    static let sectionBackground = adaptive(light: 0xE9E9E9, dark: 0x202020)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
#if os(iOS)
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
#else
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
#endif
    }
}

#if os(iOS)
private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
#else
private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
#endif

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
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.035, green: 0.035, blue: 0.035, alpha: 1)
                : .white
        })
#else
        Color(nsColor: .windowBackgroundColor)
#endif
    }

    static var threadlineSecondaryBackground: Color {
        AppTheme.secondaryBackground
    }

    static var threadlineTertiaryBackground: Color {
        AppTheme.sectionBackground
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
