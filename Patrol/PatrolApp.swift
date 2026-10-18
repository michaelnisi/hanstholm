import SwiftUI

@main
struct PatrolApp: App {
    init() {
        PatrolShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
