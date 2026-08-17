import SwiftUI

struct PlaceholderListingView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: title, showsBack: true)
            ContentUnavailableView(
                title,
                systemImage: icon,
                description: Text("The interaction shell is ready. Live content will connect through the replaceable Reddit service after API approval.")
            )
        }
    }

    private var icon: String {
        switch title {
        case "Search": "magnifyingglass"
        case "Messages": "envelope"
        case "Saved": "bookmark"
        case "Profile": "person.crop.circle"
        default: "square.stack.3d.up"
        }
    }
}
