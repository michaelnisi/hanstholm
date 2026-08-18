import SwiftUI
import MockData
import os.log

nonisolated let logger = Logger(subsystem: "ink.codes.Patrol", category: "App")

@main
struct PatrolWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SurfProvider.live)
        }
        .backgroundTask(.appRefresh("ink.codes.Patrol")) {
            await backgroundRefresh()
        }
    }
}
