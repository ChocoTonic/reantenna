import SwiftUI
import AntennaCore

@main
struct ReAntennaApp: App {
    @StateObject private var model = AppModel(service: FixtureRedditService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(model.preferredColorScheme)
        }
    }
}
